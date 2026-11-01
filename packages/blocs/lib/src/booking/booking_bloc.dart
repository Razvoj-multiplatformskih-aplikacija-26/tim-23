import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../clock.dart';
import '../ports/donation_repository.dart';

part 'booking_event.dart';
part 'booking_state.dart';

/// Zakazivanje termina na jednoj akciji: slobodna mesta po slotovima,
/// izbor slota i slanje.
///
/// Klijent proverava pravila odmah (isti kod iz domena), a repozitorijum,
/// odnosno od KT2 server, proverava ponovo i konačno odlučuje.
final class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({required this.repository, required this.clock, required this.donorId, required this.driveId})
    : super(const BookingLoading()) {
    on<BookingRequested>((event, emit) async {
      emit(const BookingLoading());
      await _load(emit);
    });
    on<BookingSlotSelected>((event, emit) {
      final current = state;
      if (current is! BookingLoaded || current.submitting) return;
      emit(current.copyWith(selected: event.slotStart));
    });
    on<BookingSubmitted>(_onSubmitted);
    on<BookingNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is BookingLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final DonationRepository repository;
  final Clock clock;
  final DonorId donorId;
  final DriveId driveId;

  Future<void> _load(Emitter<BookingState> emit, {DateTime? selected, BookingNotice? notice}) async {
    try {
      final drive = await repository.drive(driveId);
      final donor = await repository.donor(donorId);
      if (drive == null || donor == null) {
        emit(const BookingNotFound());
        return;
      }
      final driveAppointments = await repository.appointmentsOfDrive(driveId);
      final donorAppointments = await repository.appointmentsOfDonor(donorId);
      final slots = slotAvailability(drive: drive, appointments: driveAppointments, now: clock());
      final stillFree = slots.any((s) => s.start == selected && s.isBookable);
      emit(
        BookingLoaded(
          drive: drive,
          donor: donor,
          slots: slots,
          donorAppointments: donorAppointments,
          driveAppointments: driveAppointments,
          selected: stillFree ? selected : null,
          notice: notice,
        ),
      );
    } on Exception catch (cause) {
      emit(BookingFailure(cause));
    }
  }

  Future<void> _onSubmitted(BookingSubmitted event, Emitter<BookingState> emit) async {
    final current = state;
    if (current is! BookingLoaded || current.submitting) return;
    final slot = current.selected;
    if (slot == null) return;

    // 1. Klijent proverava odmah, istim pravilom iz domena.
    final local = bookAppointment(
      id: const AppointmentId('provera'),
      donor: current.donor,
      drive: current.drive,
      slotStart: slot,
      donorAppointments: current.donorAppointments,
      driveAppointments: current.driveAppointments,
      now: clock(),
    );
    if (local case Failure(:final error)) {
      emit(current.copyWith(notice: BookingRejected(error)));
      return;
    }

    // 2. Druga strana proverava ponovo i odlučuje.
    emit(current.copyWith(submitting: true));
    try {
      final result = await repository.book(donorId: donorId, driveId: driveId, slotStart: slot);
      switch (result) {
        case Success(:final value):
          await _load(emit, notice: BookingSucceeded(value));
        case Failure(:final error):
          await _load(emit, selected: slot, notice: BookingRejected(error));
      }
    } on Exception catch (cause) {
      emit(current.copyWith(notice: BookingFailed(cause)));
    }
  }
}
