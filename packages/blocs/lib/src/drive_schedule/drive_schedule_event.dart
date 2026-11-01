part of 'drive_schedule_bloc.dart';

sealed class DriveScheduleEvent {
  const DriveScheduleEvent();
}

/// Osoblje je otvorilo raspored akcije (iz adrese ili izborom akcije).
final class DriveScheduleRequested extends DriveScheduleEvent {
  const DriveScheduleRequested(this.driveId, {this.selectedId});

  final DriveId driveId;
  final AppointmentId? selectedId;
}

/// Ponovno učitavanje iste akcije, uz zadržan izbor.
final class DriveScheduleRefreshed extends DriveScheduleEvent {
  const DriveScheduleRefreshed();
}

/// Izabran termin (klik, Enter, adresa); null zatvara detalj.
final class ScheduleAppointmentSelected extends DriveScheduleEvent {
  const ScheduleAppointmentSelected(this.id);

  final AppointmentId? id;
}

/// Strelica gore ili dole: kursor ide za [delta] redova.
final class ScheduleCursorMoved extends DriveScheduleEvent {
  const ScheduleCursorMoved(this.delta);

  final int delta;
}

/// Enter: bira termin pod kursorom.
final class ScheduleCursorActivated extends DriveScheduleEvent {
  const ScheduleCursorActivated();
}

final class StaffActionRequested extends DriveScheduleEvent {
  const StaffActionRequested(this.id, this.action, {this.reason = ''});

  final AppointmentId id;
  final StaffAction action;

  /// Razlog odbijanja ili otkazivanja.
  final String reason;
}

final class DriveScheduleNoticeAcknowledged extends DriveScheduleEvent {
  const DriveScheduleNoticeAcknowledged();
}
