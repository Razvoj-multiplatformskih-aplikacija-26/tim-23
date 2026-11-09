import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../clock.dart';
import '../ports/donation_repository.dart';

part 'my_appointments_event.dart';
part 'my_appointments_state.dart';

/// Glavni tok davaoca: učitavanje njegovih termina i akcije koje menjaju
/// stanje (potvrda i otkazivanje).
final class MyAppointmentsBloc extends Bloc<MyAppointmentsEvent, MyAppointmentsState> {
  MyAppointmentsBloc({required this.repository, required this.clock, required this.donorId})
    : super(const MyAppointmentsLoading()) {
    on<MyAppointmentsRequested>((event, emit) async {
      emit(const MyAppointmentsLoading());
      await _reload(emit);
    });
    on<MyAppointmentsRefreshed>((event, emit) => _reload(emit));
    on<AppointmentConfirmationRequested>(
      (event, emit) => _change(emit, event.id, (a, now) => confirmAppointment(a, now: now), AppointmentConfirmed.new),
    );
    on<AppointmentCancellationRequested>(
      (event, emit) => _change(
        emit,
        event.id,
        (a, now) => cancelAppointment(a, byStaff: false, now: now),
        AppointmentCancelled.new,
      ),
    );
    on<MyAppointmentsNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyAppointmentsLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final DonationRepository repository;
  final Clock clock;
  final DonorId donorId;

  /// Zajednički tok svake akcije: pravilo iz domena, pa čuvanje, pa novo učitavanje.
  Future<void> _change(
    Emitter<MyAppointmentsState> emit,
    AppointmentId id,
    Result<Appointment> Function(Appointment appointment, DateTime now) rule,
    MyAppointmentsNotice Function(Appointment appointment) done,
  ) async {
    final current = state;
    if (current is! MyAppointmentsLoaded || current.isBusy) return;
    final appointment = current.find(id);
    if (appointment == null) return;

    switch (rule(appointment, clock())) {
      case Failure(:final error):
        emit(current.copyWith(notice: ActionRejected(error)));
      case Success(:final value):
        emit(current.copyWith(busyId: id));
        try {
          // Server ponovo proverava pravilo; ako odbije (npr. termin je u međuvremenu
          // promenjen), prikazuje se razlog i podaci se ponovo učitavaju.
          switch (await repository.saveAppointment(value)) {
            case Success(value: final saved):
              await _reload(emit, notice: done(saved));
            case Failure(:final error):
              await _reload(emit, notice: ActionRejected(error));
          }
        } on Exception catch (cause) {
          emit(current.copyWith(notice: ActionFailed(cause)));
        }
    }
  }

  Future<void> _reload(Emitter<MyAppointmentsState> emit, {MyAppointmentsNotice? notice}) async {
    try {
      final appointments = await repository.appointmentsOfDonor(donorId);
      final donor = await repository.donor(donorId);
      if (appointments.isEmpty) {
        emit(const MyAppointmentsEmpty());
        return;
      }
      final drives = await repository.drives();
      final now = clock();
      final sorted = [...appointments]..sort((a, b) => a.slotStart.compareTo(b.slotStart));
      emit(
        MyAppointmentsLoaded(
          upcoming: [
            for (final a in sorted)
              if (a.status.isActive) a,
          ],
          past: [
            for (final a in sorted.reversed)
              if (!a.status.isActive) a,
          ],
          drives: {for (final d in drives) d.id: d},
          cancellable: {
            for (final a in sorted)
              if (cancelAppointment(a, byStaff: false, now: now).isSuccess) a.id,
          },
          confirmable: {
            for (final a in sorted)
              if (confirmAppointment(a, now: now).isSuccess) a.id,
          },
          nextAllowed: donor == null
              ? null
              : nextAllowedDonation(sex: donor.sex, lastDonation: donor.lastDonation),
          notice: notice,
        ),
      );
    } on Exception catch (cause) {
      emit(MyAppointmentsFailure(cause));
    }
  }
}
