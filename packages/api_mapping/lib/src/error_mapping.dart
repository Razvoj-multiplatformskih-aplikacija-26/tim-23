import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'donation_mapping.dart';

/// Greška domena → greška na mreži (server). Nosi kôd i podatke pravila, bez teksta za korisnika.
extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    InvalidDonorName(:final length, :final min, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidDonorName,
      title: 'Invalid donor name',
      value: length,
      min: min,
      max: max,
    ),
    AgeOutOfRange(:final age, :final min, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.ageOutOfRange,
      title: 'Age out of range',
      value: age,
      min: min,
      max: max,
    ),
    LastDonationInFuture() => const ProblemDto(
      status: 422,
      code: ErrorCodes.lastDonationInFuture,
      title: 'Last donation in the future',
    ),
    TooSoonToDonate(:final nextAllowed) => ProblemDto(
      status: 422,
      code: ErrorCodes.tooSoonToDonate,
      title: 'Too soon to donate',
      at: nextAllowed.toUtc(),
    ),
    ActiveAppointmentExists() => const ProblemDto(
      status: 409,
      code: ErrorCodes.activeAppointmentExists,
      title: 'Donor already has an active appointment',
    ),
    SlotFull() => const ProblemDto(status: 409, code: ErrorCodes.slotFull, title: 'Slot full'),
    SlotInPast() => const ProblemDto(status: 422, code: ErrorCodes.slotInPast, title: 'Slot in the past'),
    SlotNotInDrive() => const ProblemDto(status: 422, code: ErrorCodes.slotNotInDrive, title: 'Slot not in drive'),
    CancellationTooLate(:final deadline) => ProblemDto(
      status: 422,
      code: ErrorCodes.cancellationTooLate,
      title: 'Cancellation too late',
      at: deadline.toUtc(),
    ),
    AppointmentStarted() => const ProblemDto(
      status: 422,
      code: ErrorCodes.appointmentStarted,
      title: 'Appointment started',
    ),
    CheckInOutsideWindow() => const ProblemDto(
      status: 422,
      code: ErrorCodes.checkInOutsideWindow,
      title: 'Check-in outside the window',
    ),
    AppointmentNotStarted() => const ProblemDto(
      status: 422,
      code: ErrorCodes.appointmentNotStarted,
      title: 'Appointment not started',
    ),
    InvalidDeferralReason(:final length, :final min, :final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.invalidDeferralReason,
      title: 'Invalid deferral reason',
      value: length,
      min: min,
      max: max,
    ),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: from.kind,
      to: to.kind,
    ),
    NotFound() => const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found'),
    NotAllowed() => const ProblemDto(status: 403, code: ErrorCodes.notAllowed, title: 'Not allowed'),
  };
}

/// Greška na mreži → greška domena (klijent). Nepoznat kôd (npr. pravilo koje je
/// server dodao posle izgradnje aplikacije) daje null, pa klijent prikaže opštu poruku.
extension ProblemMapping on ProblemDto {
  DomainError? toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.invalidDonorName, :final value?, :final min?, :final max?) => InvalidDonorName(
      length: value,
      min: min,
      max: max,
    ),
    ProblemDto(code: ErrorCodes.ageOutOfRange, :final value?, :final min?, :final max?) => AgeOutOfRange(
      age: value,
      min: min,
      max: max,
    ),
    ProblemDto(code: ErrorCodes.lastDonationInFuture) => const LastDonationInFuture(),
    ProblemDto(code: ErrorCodes.tooSoonToDonate, :final at?) => TooSoonToDonate(at.toLocal()),
    ProblemDto(code: ErrorCodes.activeAppointmentExists) => const ActiveAppointmentExists(),
    ProblemDto(code: ErrorCodes.slotFull) => const SlotFull(),
    ProblemDto(code: ErrorCodes.slotInPast) => const SlotInPast(),
    ProblemDto(code: ErrorCodes.slotNotInDrive) => const SlotNotInDrive(),
    ProblemDto(code: ErrorCodes.cancellationTooLate, :final at?) => CancellationTooLate(at.toLocal()),
    ProblemDto(code: ErrorCodes.appointmentStarted) => const AppointmentStarted(),
    ProblemDto(code: ErrorCodes.checkInOutsideWindow) => const CheckInOutsideWindow(),
    ProblemDto(code: ErrorCodes.appointmentNotStarted) => const AppointmentNotStarted(),
    ProblemDto(code: ErrorCodes.invalidDeferralReason, :final value?, :final min?, :final max?) =>
      InvalidDeferralReason(length: value, min: min, max: max),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => _transition(from, to),
    ProblemDto(code: ErrorCodes.notFound) => const NotFound(),
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    _ => null,
  };
}

/// Za prelaz je bitna samo vrsta stanja; vreme nije deo greške.
DomainError? _transition(String from, String to) {
  final epoch = DateTime.utc(2000);
  AppointmentStatus? status(String kind) {
    try {
      return AppointmentStatusDto(kind: kind, at: epoch).toDomain();
    } on FormatException {
      return null;
    }
  }

  final fromStatus = status(from);
  final toStatus = status(to);
  if (fromStatus == null || toStatus == null) return null;
  return InvalidTransition(from: fromStatus, to: toStatus);
}
