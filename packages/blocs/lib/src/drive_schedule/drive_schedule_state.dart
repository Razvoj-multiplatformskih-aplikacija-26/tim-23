part of 'drive_schedule_bloc.dart';

sealed class DriveScheduleState extends Equatable {
  const DriveScheduleState();

  /// Akcija na koju se stanje odnosi; null pre prvog učitavanja.
  DriveId? get driveId;

  @override
  List<Object?> get props => [driveId];

  @override
  String toString() => '$runtimeType';
}

final class DriveScheduleLoading extends DriveScheduleState {
  const DriveScheduleLoading(this.driveId);

  @override
  final DriveId? driveId;
}

final class DriveScheduleFailure extends DriveScheduleState {
  const DriveScheduleFailure(this.driveId, this.cause);

  @override
  final DriveId driveId;
  final Object cause;

  @override
  List<Object?> get props => [driveId, cause];

  @override
  String toString() => 'DriveScheduleFailure($cause)';
}

final class DriveScheduleEmpty extends DriveScheduleState {
  const DriveScheduleEmpty(this.drive);

  final DonationDrive drive;

  @override
  DriveId get driveId => drive.id;

  @override
  List<Object?> get props => [drive];
}

final class DriveScheduleLoaded extends DriveScheduleState {
  const DriveScheduleLoaded({
    required this.drive,
    required this.appointments,
    required this.donors,
    required this.actions,
    required this.cursor,
    this.selectedId,
    this.busyId,
    this.notice,
  });

  final DonationDrive drive;

  /// Termini akcije, poređani po vremenu.
  final List<Appointment> appointments;

  final Map<DonorId, Donor> donors;

  /// Akcije koje osoblje sada sme nad svakim terminom (računa domen).
  final Map<AppointmentId, Set<StaffAction>> actions;

  /// Red pod kursorom tastature.
  final int cursor;

  /// Termin otvoren u detalju.
  final AppointmentId? selectedId;

  final AppointmentId? busyId;
  final DriveScheduleNotice? notice;

  @override
  DriveId get driveId => drive.id;

  bool get isBusy => busyId != null;

  Appointment? find(AppointmentId id) => appointments.where((a) => a.id == id).firstOrNull;

  Appointment? get selected => selectedId == null ? null : find(selectedId!);

  Set<StaffAction> actionsFor(Appointment a) => actions[a.id] ?? const {};

  bool allows(Appointment a, StaffAction action) => !isBusy && actionsFor(a).contains(action);

  DriveScheduleLoaded copyWith({
    AppointmentId? selectedId,
    bool clearSelection = false,
    int? cursor,
    AppointmentId? busyId,
    DriveScheduleNotice? notice,
    bool clearNotice = false,
  }) => DriveScheduleLoaded(
    drive: drive,
    appointments: appointments,
    donors: donors,
    actions: actions,
    cursor: cursor ?? this.cursor,
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    busyId: busyId,
    notice: clearNotice ? null : (notice ?? this.notice),
  );

  @override
  List<Object?> get props => [drive, appointments, donors, actions, cursor, selectedId, busyId, notice];

  @override
  String toString() => [
    'DriveScheduleLoaded(${appointments.length} termina, kursor $cursor',
    if (selectedId case final id?) ', izabran ${id.value}',
    if (busyId case final id?) ', radi se na ${id.value}',
    if (notice case final n?) ', ${n.runtimeType}',
    ')',
  ].join();
}

sealed class DriveScheduleNotice extends Equatable {
  const DriveScheduleNotice();

  @override
  List<Object?> get props => const [];
}

final class StaffActionDone extends DriveScheduleNotice {
  const StaffActionDone(this.action, this.appointment);

  final StaffAction action;
  final Appointment appointment;

  @override
  List<Object?> get props => [action, appointment];
}

final class StaffActionRejected extends DriveScheduleNotice {
  const StaffActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class StaffActionFailed extends DriveScheduleNotice {
  const StaffActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
