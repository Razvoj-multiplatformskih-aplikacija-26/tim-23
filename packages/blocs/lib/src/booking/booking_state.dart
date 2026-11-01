part of 'booking_bloc.dart';

sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class BookingLoading extends BookingState {
  const BookingLoading();
}

final class BookingFailure extends BookingState {
  const BookingFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'BookingFailure($cause)';
}

/// Akcija ili davalac ne postoje.
final class BookingNotFound extends BookingState {
  const BookingNotFound();
}

final class BookingLoaded extends BookingState {
  const BookingLoaded({
    required this.drive,
    required this.donor,
    required this.slots,
    required this.donorAppointments,
    required this.driveAppointments,
    this.selected,
    this.submitting = false,
    this.notice,
  });

  final DonationDrive drive;
  final Donor donor;
  final List<SlotAvailability> slots;
  final List<Appointment> donorAppointments;
  final List<Appointment> driveAppointments;
  final DateTime? selected;
  final bool submitting;
  final BookingNotice? notice;

  /// Prvi dan kada davalac ponovo sme da da krv (računa domen).
  DateTime? get nextAllowed => nextAllowedDonation(sex: donor.sex, lastDonation: donor.lastDonation);

  bool get hasActiveAppointment => donorAppointments.any((a) => a.status.isActive);

  int get freeSpots => slots.where((s) => s.isBookable).fold<int>(0, (sum, s) => sum + s.free);

  BookingLoaded copyWith({DateTime? selected, bool? submitting, BookingNotice? notice, bool clearNotice = false}) =>
      BookingLoaded(
        drive: drive,
        donor: donor,
        slots: slots,
        donorAppointments: donorAppointments,
        driveAppointments: driveAppointments,
        selected: selected ?? this.selected,
        submitting: submitting ?? false,
        notice: clearNotice ? null : (notice ?? this.notice),
      );

  @override
  List<Object?> get props => [drive, donor, slots, donorAppointments, driveAppointments, selected, submitting, notice];

  @override
  String toString() => [
    'BookingLoaded($freeSpots slobodnih',
    if (selected case final s?) ', izabran $s',
    if (submitting) ', šalje se',
    if (notice case final n?) ', ${n.runtimeType}',
    ')',
  ].join();
}

/// Jednokratna poruka o ishodu; ekran je prikaže i javi BookingNoticeAcknowledged.
sealed class BookingNotice extends Equatable {
  const BookingNotice();

  @override
  List<Object?> get props => const [];
}

final class BookingSucceeded extends BookingNotice {
  const BookingSucceeded(this.appointment);

  final Appointment appointment;

  @override
  List<Object?> get props => [appointment];
}

final class BookingRejected extends BookingNotice {
  const BookingRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class BookingFailed extends BookingNotice {
  const BookingFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
