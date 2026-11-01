import 'package:equatable/equatable.dart';

import '../appointment/appointment.dart';
import 'donation_drive.dart';

/// Koliko je mesta slobodno u jednom slotu akcije.
final class SlotAvailability extends Equatable {
  const SlotAvailability({required this.start, required this.free, required this.capacity, required this.isPast});

  final DateTime start;
  final int free;
  final int capacity;

  /// Slot je već počeo, pa se više ne zakazuje.
  final bool isPast;

  bool get isBookable => free > 0 && !isPast;

  @override
  List<Object?> get props => [start, free, capacity, isPast];
}

/// Koliko termina zauzima slot [slotStart] akcije [drive].
///
/// Pravilo koje zavisi od podataka drugih davalaca: ovde je izračunavanje
/// nad listom, a konačnu odluku donosi server (od KT2).
int takenSpots({required DonationDrive drive, required DateTime slotStart, required List<Appointment> appointments}) =>
    appointments.where((a) => a.driveId == drive.id && a.slotStart == slotStart && a.status.occupiesSlot).length;

/// Slobodna mesta po slotovima akcije.
List<SlotAvailability> slotAvailability({
  required DonationDrive drive,
  required List<Appointment> appointments,
  required DateTime now,
}) => [
  for (final slot in drive.slots)
    SlotAvailability(
      start: slot,
      capacity: drive.slotCapacity,
      free: _atLeastZero(drive.slotCapacity - takenSpots(drive: drive, slotStart: slot, appointments: appointments)),
      isPast: !slot.isAfter(now),
    ),
];

/// Ukupno slobodnih mesta u slotovima koji još nisu počeli.
int freeSpotsInDrive({required DonationDrive drive, required List<Appointment> appointments, required DateTime now}) =>
    slotAvailability(
      drive: drive,
      appointments: appointments,
      now: now,
    ).where((s) => !s.isPast).fold<int>(0, (sum, s) => sum + s.free);

int _atLeastZero(int n) => n < 0 ? 0 : n;
