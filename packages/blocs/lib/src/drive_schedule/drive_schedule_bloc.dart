import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../clock.dart';
import '../ports/donation_repository.dart';

part 'drive_schedule_event.dart';
part 'drive_schedule_state.dart';

/// Dnevni raspored jedne akcije za osoblje: svi termini, izbor, kursor
/// za tastaturu i akcije osoblja (pristupio, dao krv, odbijen, nije došao, otkaži).
///
/// Izbor i kursor su ovde, iznad rasporeda ekrana, pa ostaju kad se prozor suzi.
final class DriveScheduleBloc extends Bloc<DriveScheduleEvent, DriveScheduleState> {
  DriveScheduleBloc({required this.repository, required this.clock}) : super(const DriveScheduleLoading(null)) {
    on<DriveScheduleRequested>((event, emit) async {
      _pendingSelection = event.selectedId;
      emit(DriveScheduleLoading(event.driveId));
      await _load(emit, event.driveId, selectedId: event.selectedId);
    });
    on<DriveScheduleRefreshed>((event, emit) async {
      final current = state;
      final driveId = current.driveId;
      if (driveId == null) return;
      await _load(
        emit,
        driveId,
        selectedId: current is DriveScheduleLoaded ? current.selectedId : null,
        cursor: current is DriveScheduleLoaded ? current.cursor : 0,
      );
    });
    on<ScheduleAppointmentSelected>((event, emit) {
      final current = state;
      if (current is! DriveScheduleLoaded) {
        _pendingSelection = event.id;
        return;
      }
      final index = event.id == null ? -1 : current.appointments.indexWhere((a) => a.id == event.id);
      emit(current.copyWith(selectedId: event.id, clearSelection: event.id == null, cursor: index < 0 ? null : index));
    });
    on<ScheduleCursorMoved>((event, emit) {
      final current = state;
      if (current is! DriveScheduleLoaded) return;
      final last = current.appointments.length - 1;
      final next = (current.cursor + event.delta).clamp(0, last).toInt();
      emit(current.copyWith(cursor: next));
    });
    on<ScheduleCursorActivated>((event, emit) {
      final current = state;
      if (current is! DriveScheduleLoaded) return;
      emit(current.copyWith(selectedId: current.appointments[current.cursor].id));
    });
    on<StaffActionRequested>(_onAction);
    on<DriveScheduleNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is DriveScheduleLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final DonationRepository repository;
  final Clock clock;

  /// Izbor koji je stigao (npr. iz adrese) pre nego što su termini učitani.
  AppointmentId? _pendingSelection;

  Future<void> _load(
    Emitter<DriveScheduleState> emit,
    DriveId driveId, {
    AppointmentId? selectedId,
    int cursor = 0,
    DriveScheduleNotice? notice,
  }) async {
    try {
      final drive = await repository.drive(driveId);
      if (drive == null) {
        emit(DriveScheduleFailure(driveId, StateError('Nema akcije ${driveId.value}')));
        return;
      }
      final appointments = [...await repository.appointmentsOfDrive(driveId)]
        ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
      if (appointments.isEmpty) {
        emit(DriveScheduleEmpty(drive));
        return;
      }
      final donors = await repository.donors();
      final now = clock();
      final wanted = _pendingSelection ?? selectedId;
      _pendingSelection = null;
      final selectedIndex = appointments.indexWhere((a) => a.id == wanted);
      emit(
        DriveScheduleLoaded(
          drive: drive,
          appointments: appointments,
          donors: {for (final d in donors) d.id: d},
          actions: {for (final a in appointments) a.id: staffActionsFor(a, now: now)},
          selectedId: selectedIndex < 0 ? null : wanted,
          cursor: selectedIndex >= 0 ? selectedIndex : cursor.clamp(0, appointments.length - 1).toInt(),
          notice: notice,
        ),
      );
    } on Exception catch (cause) {
      emit(DriveScheduleFailure(driveId, cause));
    }
  }

  Future<void> _onAction(StaffActionRequested event, Emitter<DriveScheduleState> emit) async {
    final current = state;
    if (current is! DriveScheduleLoaded || current.isBusy) return;
    final appointment = current.find(event.id);
    if (appointment == null) return;

    final now = clock();
    final result = switch (event.action) {
      StaffAction.checkIn => checkIn(appointment, now: now),
      StaffAction.donated => recordDonation(appointment, now: now),
      StaffAction.deferred => recordDeferral(appointment, reason: event.reason, now: now),
      StaffAction.noShow => recordNoShow(appointment, now: now),
      StaffAction.cancel => cancelAppointment(appointment, byStaff: true, now: now, reason: event.reason),
    };

    switch (result) {
      case Failure(:final error):
        emit(current.copyWith(notice: StaffActionRejected(error)));
      case Success(:final value):
        emit(current.copyWith(busyId: event.id));
        try {
          final saved = await repository.saveAppointment(value);
          await _load(
            emit,
            current.drive.id,
            selectedId: saved.id,
            cursor: current.cursor,
            notice: StaffActionDone(event.action, saved),
          );
        } on Exception catch (cause) {
          emit(current.copyWith(notice: StaffActionFailed(cause)));
        }
    }
  }
}
