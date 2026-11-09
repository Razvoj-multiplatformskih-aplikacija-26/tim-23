import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'api_client.dart';

/// Port DonationRepository nad serverom. Bloc-ovi i ekrani ostaju isti kao sa lažnim podacima.
final class HttpDonationRepository implements DonationRepository {
  const HttpDonationRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<DonationDrive>> drives() async =>
      accepted(await _api.get(ApiPaths.drives), (json) => [for (final item in objects(json)) _drive(item)]);

  @override
  Future<DonationDrive?> drive(DriveId id) async {
    final answer = await _api.get(ApiPaths.drive(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, _drive);
  }

  @override
  Future<Donor?> donor(DonorId id) async {
    final answer = await _api.get(ApiPaths.donor(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return accepted(answer, _donor);
  }

  @override
  Future<List<Donor>> donors() async =>
      accepted(await _api.get(ApiPaths.donors), (json) => [for (final item in objects(json)) _donor(item)]);

  @override
  Future<List<Appointment>> appointmentsOfDonor(DonorId id) async => accepted(
    await _api.get(ApiPaths.appointmentsOfDonor(id.value)),
    (json) => [for (final item in objects(json)) _appointment(item)],
  );

  @override
  Future<List<Appointment>> appointmentsOfDrive(DriveId id) async => accepted(
    await _api.get(ApiPaths.appointmentsOfDrive(id.value)),
    (json) => [for (final item in objects(json)) _appointment(item)],
  );

  /// Davaoca server zna iz prijave, pa [donorId] ne putuje.
  @override
  Future<Result<Appointment>> book({
    required DonorId donorId,
    required DriveId driveId,
    required DateTime slotStart,
  }) async {
    final body = NewAppointmentDto(driveId: driveId.value, slotStart: slotStart.toUtc());
    return resultOf(await _api.post(ApiPaths.appointments, body: body.toJson()), _appointment);
  }

  /// Novo stanje određuje koji poziv ide na server; svaku akciju server proverava posebno.
  @override
  Future<Result<Appointment>> saveAppointment(Appointment appointment) async {
    final id = appointment.id.value;
    final answer = await switch (appointment.status) {
      Confirmed() => _api.post(ApiPaths.confirmation(id)),
      Cancelled(:final reason) => _api.post(ApiPaths.cancellation(id), body: ReasonDto(reason: reason).toJson()),
      CheckedIn() => _api.post(ApiPaths.checkIn(id)),
      Donated() => _api.post(ApiPaths.donation(id)),
      Deferred(:final reason) => _api.post(ApiPaths.deferral(id), body: ReasonDto(reason: reason).toJson()),
      NoShow() => _api.post(ApiPaths.noShow(id)),
      Scheduled() => throw ArgumentError.value(appointment, 'appointment', 'A new appointment is booked, not saved'),
    };
    return resultOf(answer, _appointment);
  }

  @override
  Future<Result<Donor>> saveDonor(Donor donor) async =>
      resultOf(await _api.post(ApiPaths.profile(donor.id.value), body: donor.toProfileDto().toJson()), _donor);

  DonationDrive _drive(Object? json) => DriveDto.fromJson(object(json)).toDomain();

  Donor _donor(Object? json) => DonorDto.fromJson(object(json)).toDomain();

  Appointment _appointment(Object? json) => AppointmentDto.fromJson(object(json)).toDomain();
}
