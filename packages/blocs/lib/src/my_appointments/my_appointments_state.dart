part of 'my_appointments_bloc.dart';

sealed class MyAppointmentsState extends Equatable {
  const MyAppointmentsState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class MyAppointmentsLoading extends MyAppointmentsState {
  const MyAppointmentsLoading();
}

final class MyAppointmentsFailure extends MyAppointmentsState {
  const MyAppointmentsFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'MyAppointmentsFailure($cause)';
}

final class MyAppointmentsEmpty extends MyAppointmentsState {
  const MyAppointmentsEmpty();
}

final class MyAppointmentsLoaded extends MyAppointmentsState {
  const MyAppointmentsLoaded({
    required this.upcoming,
    required this.past,
    required this.drives,
    required this.cancellable,
    required this.confirmable,
    this.nextAllowed,
    this.busyId,
    this.notice,
  });

  /// Aktivni termini (zakazan, potvrđen, pristupio), od najranijeg.
  final List<Appointment> upcoming;

  /// Završeni termini, od najnovijeg.
  final List<Appointment> past;

  final Map<DriveId, DonationDrive> drives;

  /// Termini koje davalac sada sme da otkaže, odnosno potvrdi (računa domen).
  final Set<AppointmentId> cancellable;
  final Set<AppointmentId> confirmable;

  /// Prvi dan kada davalac ponovo sme da da krv.
  final DateTime? nextAllowed;

  /// Termin nad kojim akcija upravo traje.
  final AppointmentId? busyId;

  final MyAppointmentsNotice? notice;

  bool get isBusy => busyId != null;

  bool canCancel(Appointment a) => cancellable.contains(a.id);

  bool canConfirm(Appointment a) => confirmable.contains(a.id);

  Appointment? find(AppointmentId id) => [...upcoming, ...past].where((a) => a.id == id).firstOrNull;

  MyAppointmentsLoaded copyWith({AppointmentId? busyId, MyAppointmentsNotice? notice, bool clearNotice = false}) =>
      MyAppointmentsLoaded(
        upcoming: upcoming,
        past: past,
        drives: drives,
        cancellable: cancellable,
        confirmable: confirmable,
        nextAllowed: nextAllowed,
        busyId: busyId,
        notice: clearNotice ? null : (notice ?? this.notice),
      );

  @override
  List<Object?> get props => [upcoming, past, drives, cancellable, confirmable, nextAllowed, busyId, notice];

  @override
  String toString() => [
    'MyAppointmentsLoaded(${upcoming.length} aktivnih, ${past.length} završenih',
    if (busyId case final id?) ', radi se na ${id.value}',
    if (notice case final n?) ', ${n.runtimeType}',
    ')',
  ].join();
}

sealed class MyAppointmentsNotice extends Equatable {
  const MyAppointmentsNotice();

  @override
  List<Object?> get props => const [];
}

final class AppointmentConfirmed extends MyAppointmentsNotice {
  const AppointmentConfirmed(this.appointment);

  final Appointment appointment;

  @override
  List<Object?> get props => [appointment];
}

final class AppointmentCancelled extends MyAppointmentsNotice {
  const AppointmentCancelled(this.appointment);

  final Appointment appointment;

  @override
  List<Object?> get props => [appointment];
}

final class ActionRejected extends MyAppointmentsNotice {
  const ActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class ActionFailed extends MyAppointmentsNotice {
  const ActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
