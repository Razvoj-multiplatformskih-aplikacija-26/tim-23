import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show Pool, ServerException;
import 'package:relic/relic.dart' hide Result;

import 'http.dart';
import 'kap_store.dart';
import 'sessions.dart';

/// Obrada zahteva. Svaki upis prolazi kroz ista pravila iz domena kao na klijentu
/// (bookAppointment, cancelAppointment...) i ista prava (AccessPolicy).
/// Ko poziva, server zna samo iz prijave (currentSession), nikad iz tela zahteva.
final class KapHandlers {
  KapHandlers({required Pool<void> database, required this.clock}) : _database = database, store = KapStore(database);

  final Pool<void> _database;
  final KapStore store;
  final DateTime Function() clock;

  // Akcije.

  Future<Response> drives(Request request) async =>
      json(200, [for (final drive in await store.drives()) drive.toDto().toJson()]);

  Future<Response> drive(Request request) async {
    final drive = await store.drive(DriveId(_id(request, #id)));
    if (drive == null) return problem(const NotFound());
    return json(200, drive.toDto().toJson());
  }

  /// Termini akcije. Osoblje vidi sve; davalac za tuđe termine vidi samo da je mesto
  /// zauzeto (bez imena i razloga), što mu je dovoljno za slobodna mesta po slotu.
  Future<Response> driveAppointments(Request request) async {
    final actor = _actor(request);
    final appointments = await store.appointmentsOfDrive(DriveId(_id(request, #id)));
    return json(200, [
      for (final appointment in appointments)
        (AccessPolicy.canSeeWhoBooked(actor, appointment) ? appointment : _anonymous(appointment)).toDto().toJson(),
    ]);
  }

  // Davaoci.

  Future<Response> donors(Request request) async {
    if (!AccessPolicy.canViewAllDonors(_actor(request))) return problem(const NotAllowed());
    return json(200, [for (final donor in await store.donors()) donor.toDto().toJson()]);
  }

  Future<Response> donor(Request request) async {
    final id = DonorId(_id(request, #id));
    if (!AccessPolicy.canViewDonor(_actor(request), id)) return problem(const NotFound());
    final donor = await store.donor(id);
    if (donor == null) return problem(const NotFound());
    return json(200, donor.toDto().toJson());
  }

  Future<Response> donorAppointments(Request request) async {
    final id = DonorId(_id(request, #id));
    if (!AccessPolicy.canViewDonor(_actor(request), id)) return problem(const NotFound());
    return json(200, [for (final appointment in await store.appointmentsOfDonor(id)) appointment.toDto().toJson()]);
  }

  /// Izmena profila: ista pravila profila kao forma u aplikaciji (updateProfile).
  Future<Response> updateProfile(Request request) async {
    final id = DonorId(_id(request, #id));
    if (!AccessPolicy.canEditProfile(_actor(request), id)) return problem(const NotAllowed());
    final body = ProfileDto.fromJson(await readObject(request));
    final donor = await store.donor(id);
    if (donor == null) return problem(const NotFound());
    final updated = domainUpdateProfile(
      donor,
      name: body.name,
      birthDate: body.birthDate,
      sex: sexFromJson(body.sex),
      bloodGroup: bloodGroupFromJson(body.bloodGroup),
      city: body.city,
      lastDonation: body.lastDonation,
      now: clock(),
    );
    if (updated case Success(:final value)) await store.saveDonor(value);
    return respond(updated, (donor) => donor.toDto().toJson());
  }

  // Termini.

  /// Zakazivanje. Kapacitet zavisi od termina drugih davalaca, pa konačno odlučuje server:
  /// akcija se zaključava u transakciji, pa dva istovremena zahteva za poslednje mesto
  /// idu jedan za drugim i prolazi samo jedan. Drugi dobija „slot-full“.
  Future<Response> book(Request request) async {
    final actor = _actor(request);
    if (!AccessPolicy.canBook(actor)) return problem(const NotAllowed());
    final body = NewAppointmentDto.fromJson(await readObject(request));
    final driveId = DriveId(body.driveId);
    Result<Appointment> result;
    try {
      result = await _database.runTx<Result<Appointment>>((session) async {
        final tx = KapStore(session);
        if (!await tx.lockDrive(driveId)) return const Failure<Appointment>(NotFound());
        final drive = await tx.drive(driveId);
        final donor = await tx.donor(actor.donorId);
        if (drive == null || donor == null) return const Failure<Appointment>(NotFound());
        final booked = bookAppointment(
          id: const AppointmentId('novi'),
          donor: donor,
          drive: drive,
          slotStart: body.slotStart,
          donorAppointments: await tx.appointmentsOfDonor(donor.id),
          driveAppointments: await tx.appointmentsOfDrive(driveId),
          now: clock(),
        );
        return switch (booked) {
          Success(:final value) => Success(await tx.insertAppointment(value)),
          Failure(:final error) => Failure(error),
        };
      });
    } on ServerException catch (error) {
      // Isti davalac sa dva uređaja u istom trenutku: drugi upis odbija jedinstveni indeks u bazi.
      if (error.code != uniqueViolation || error.constraintName != oneActivePerDonor) rethrow;
      result = const Failure(ActiveAppointmentExists());
    }
    return respond(result, (appointment) => appointment.toDto().toJson(), status: 201);
  }

  Future<Response> confirm(Request request) => _change(
    request,
    allowed: AccessPolicy.canConfirm,
    rule: (actor, appointment, body, now) => confirmAppointment(appointment, now: now),
  );

  Future<Response> cancel(Request request) => _change(
    request,
    allowed: AccessPolicy.canCancel,
    rule: (actor, appointment, body, now) => cancelAppointment(
      appointment,
      byStaff: actor.role.isStaff,
      now: now,
      reason: ReasonDto.fromJson(body).reason,
    ),
  );

  Future<Response> checkInDonor(Request request) => _change(
    request,
    allowed: (actor, _) => AccessPolicy.canPerform(actor, StaffAction.checkIn),
    rule: (actor, appointment, body, now) => checkIn(appointment, now: now),
  );

  Future<Response> donation(Request request) => _change(
    request,
    allowed: (actor, _) => AccessPolicy.canPerform(actor, StaffAction.donated),
    rule: (actor, appointment, body, now) => recordDonation(appointment, now: now),
  );

  Future<Response> deferral(Request request) => _change(
    request,
    allowed: (actor, _) => AccessPolicy.canPerform(actor, StaffAction.deferred),
    rule: (actor, appointment, body, now) =>
        recordDeferral(appointment, reason: ReasonDto.fromJson(body).reason, now: now),
  );

  Future<Response> noShow(Request request) => _change(
    request,
    allowed: (actor, _) => AccessPolicy.canPerform(actor, StaffAction.noShow),
    rule: (actor, appointment, body, now) => recordNoShow(appointment, now: now),
  );

  /// Zajednički tok promene stanja: pravo → pravilo iz domena → upis samo ako se
  /// stanje u međuvremenu nije promenilo (inače „invalid-transition“ sa trenutnim stanjem).
  Future<Response> _change(
    Request request, {
    required bool Function(User actor, Appointment appointment) allowed,
    required Result<Appointment> Function(User actor, Appointment appointment, Map<String, Object?> body, DateTime now)
    rule,
  }) async {
    final actor = _actor(request);
    final body = await readObject(request);
    final appointment = await store.appointment(AppointmentId(_id(request, #id)));
    // Tuđ termin davalac ne vidi, pa za njega i ne postoji.
    if (appointment == null || !AccessPolicy.canSeeWhoBooked(actor, appointment)) return problem(const NotFound());
    if (!allowed(actor, appointment)) return problem(const NotAllowed());
    final changed = rule(actor, appointment, body, clock());
    if (changed case Failure(:final error)) return problem(error);
    final next = changed.valueOrNull!;
    final saved = await _database.runTx((session) => KapStore(session).changeStatus(next, from: appointment.status));
    if (!saved) {
      final current = await store.appointment(appointment.id);
      return problem(InvalidTransition(from: current?.status ?? appointment.status, to: next.status));
    }
    return json(200, next.toDto().toJson());
  }

  User _actor(Request request) => currentSession.get(request).user;

  String _id(Request request, Symbol name) => request.rawPathParameters[name]!;
}

/// Domenska funkcija updateProfile pod drugim imenom, da se ne meša sa metodom iznad.
const domainUpdateProfile = updateProfile;

/// Tuđ termin za davaoca: samo akcija, vreme i da li zauzima mesto.
Appointment _anonymous(Appointment appointment) => Appointment(
  id: const AppointmentId('zauzeto'),
  donorId: const DonorId('skriveno'),
  driveId: appointment.driveId,
  slotStart: appointment.slotStart,
  slotLength: appointment.slotLength,
  status: switch (appointment.status) {
    Deferred(:final at) => Deferred(at: at, reason: ''),
    Cancelled(:final at, :final byStaff) => Cancelled(at: at, byStaff: byStaff),
    final other => other,
  },
);
