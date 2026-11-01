import 'package:equatable/equatable.dart';

import '../identifiers.dart';
import 'appointment_status.dart';

/// Termin davanja krvi: glavni pojam sistema.
final class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.donorId,
    required this.driveId,
    required this.slotStart,
    required this.status,
    this.slotLength = const Duration(minutes: 30),
  });

  final AppointmentId id;
  final DonorId donorId;
  final DriveId driveId;
  final DateTime slotStart;
  final Duration slotLength;
  final AppointmentStatus status;

  DateTime get slotEnd => slotStart.add(slotLength);

  Appointment withStatus(AppointmentStatus status) => Appointment(
    id: id,
    donorId: donorId,
    driveId: driveId,
    slotStart: slotStart,
    slotLength: slotLength,
    status: status,
  );

  @override
  List<Object?> get props => [id, donorId, driveId, slotStart, slotLength, status];

  @override
  String toString() => 'Appointment(${id.value}, $status)';
}
