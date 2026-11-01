import 'package:equatable/equatable.dart';

import '../donor/donor.dart';
import '../donor/eligibility.dart';
import '../drive/availability.dart';
import '../drive/donation_drive.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import 'appointment.dart';
import 'appointment_status.dart';

/// Davalac otkazuje najkasnije 12 sati pre termina.
const cancellationNotice = Duration(hours: 12);

/// Dolazak se beleži od sat vremena pre do dva sata posle početka slota.
const checkInBefore = Duration(hours: 1);
const checkInAfter = Duration(hours: 2);

/// Razlog odbijanja na pregledu: od 3 do 200 znakova.
final class DeferralReason extends Equatable {
  const DeferralReason._(this.value);

  static const minLength = 3;
  static const maxLength = 200;

  final String value;

  static Result<DeferralReason> parse(String input) {
    final text = input.trim();
    if (text.length < minLength || text.length > maxLength) {
      return Failure(InvalidDeferralReason(length: text.length, min: minLength, max: maxLength));
    }
    return Success(DeferralReason._(text));
  }

  @override
  List<Object?> get props => [value];
}

/// Poslednji trenutak kada davalac sme da otkaže termin.
DateTime cancellationDeadline(Appointment appointment) => appointment.slotStart.subtract(cancellationNotice);

bool hasStarted(Appointment appointment, {required DateTime now}) => !now.isBefore(appointment.slotStart);

/// Zakazivanje novog termina. Proverava sva pravila zakazivanja:
/// slot postoji i nije prošao, starost, razmak od poslednjeg davanja,
/// najviše jedan aktivan termin i kapacitet slota.
///
/// [donorAppointments] su termini ovog davaoca, a [driveAppointments] termini
/// svih davalaca na akciji. Kapacitet zavisi od drugih davalaca, pa isto
/// izračunavanje ponovo radi server i on konačno odlučuje.
Result<Appointment> bookAppointment({
  required AppointmentId id,
  required Donor donor,
  required DonationDrive drive,
  required DateTime slotStart,
  required List<Appointment> donorAppointments,
  required List<Appointment> driveAppointments,
  required DateTime now,
}) {
  if (!drive.hasSlot(slotStart)) return const Failure(SlotNotInDrive());
  if (!slotStart.isAfter(now)) return const Failure(SlotInPast());
  if (checkAge(birthDate: donor.birthDate, on: slotStart) case Failure(:final error)) return Failure(error);
  final interval = checkDonationInterval(sex: donor.sex, lastDonation: donor.lastDonation, donationTime: slotStart);
  if (interval case Failure(:final error)) return Failure(error);
  if (donorAppointments.any((a) => a.donorId == donor.id && a.status.isActive)) {
    return const Failure(ActiveAppointmentExists());
  }
  final taken = takenSpots(drive: drive, slotStart: slotStart, appointments: driveAppointments);
  if (taken >= drive.slotCapacity) return const Failure(SlotFull());
  return Success(
    Appointment(
      id: id,
      donorId: donor.id,
      driveId: drive.id,
      slotStart: slotStart,
      slotLength: drive.slotLength,
      status: const Scheduled(),
    ),
  );
}

/// Zajednički korak svake akcije: da li je prelaz dozvoljen.
Result<Appointment> _moveTo(Appointment appointment, AppointmentStatus next) {
  if (!canTransition(appointment.status, next)) {
    return Failure(InvalidTransition(from: appointment.status, to: next));
  }
  return Success(appointment.withStatus(next));
}

/// Davalac potvrđuje da dolazi.
Result<Appointment> confirmAppointment(Appointment appointment, {required DateTime now}) {
  final result = _moveTo(appointment, Confirmed(at: now));
  if (result.isSuccess && hasStarted(appointment, now: now)) return const Failure(AppointmentStarted());
  return result;
}

/// Otkazivanje. Davalac mora da otkaže najkasnije 12 sati pre termina,
/// a osoblje može sve dok termin ne počne.
Result<Appointment> cancelAppointment(
  Appointment appointment, {
  required bool byStaff,
  required DateTime now,
  String reason = '',
}) {
  final result = _moveTo(appointment, Cancelled(at: now, byStaff: byStaff, reason: reason.trim()));
  if (!result.isSuccess) return result;
  if (hasStarted(appointment, now: now)) return const Failure(AppointmentStarted());
  if (!byStaff && now.isAfter(cancellationDeadline(appointment))) {
    return Failure(CancellationTooLate(cancellationDeadline(appointment)));
  }
  return result;
}

/// Osoblje beleži da je davalac stigao.
Result<Appointment> checkIn(Appointment appointment, {required DateTime now}) {
  final result = _moveTo(appointment, CheckedIn(at: now));
  if (!result.isSuccess) return result;
  final opens = appointment.slotStart.subtract(checkInBefore);
  final closes = appointment.slotStart.add(checkInAfter);
  if (now.isBefore(opens) || now.isAfter(closes)) return const Failure(CheckInOutsideWindow());
  return result;
}

/// Osoblje beleži da je davalac dao krv.
Result<Appointment> recordDonation(Appointment appointment, {required DateTime now}) =>
    _moveTo(appointment, Donated(at: now));

/// Osoblje beleži da je davalac odbijen na pregledu, uz razlog.
Result<Appointment> recordDeferral(Appointment appointment, {required String reason, required DateTime now}) {
  final parsed = DeferralReason.parse(reason);
  return switch (parsed) {
    Failure(:final error) => Failure(error),
    Success(:final value) => _moveTo(appointment, Deferred(at: now, reason: value.value)),
  };
}

/// Osoblje beleži da davalac nije došao; tek kad termin počne.
Result<Appointment> recordNoShow(Appointment appointment, {required DateTime now}) {
  final result = _moveTo(appointment, NoShow(at: now));
  if (result.isSuccess && !hasStarted(appointment, now: now)) return const Failure(AppointmentNotStarted());
  return result;
}

/// Akcije koje osoblje ima u backoffice-u.
enum StaffAction { checkIn, donated, deferred, noShow, cancel }

/// Koje akcije osoblje sada sme nad terminom; računa ih ista pravila kao i same akcije.
Set<StaffAction> staffActionsFor(Appointment appointment, {required DateTime now}) => {
  if (checkIn(appointment, now: now).isSuccess) StaffAction.checkIn,
  if (recordDonation(appointment, now: now).isSuccess) StaffAction.donated,
  if (recordDeferral(appointment, reason: 'provera', now: now).isSuccess) StaffAction.deferred,
  if (recordNoShow(appointment, now: now).isSuccess) StaffAction.noShow,
  if (cancelAppointment(appointment, byStaff: true, now: now).isSuccess) StaffAction.cancel,
};
