import 'package:equatable/equatable.dart';

import '../identifiers.dart';

/// Akcija davanja krvi: mesto i vreme u kom se davaoci primaju u slotovima.
final class DonationDrive extends Equatable {
  const DonationDrive({
    required this.id,
    required this.title,
    required this.city,
    required this.address,
    required this.start,
    required this.end,
    this.slotLength = const Duration(minutes: 30),
    this.slotCapacity = 3,
  });

  final DriveId id;
  final String title;
  final String city;
  final String address;
  final DateTime start;
  final DateTime end;

  /// Trajanje jednog slota (podrazumevano pola sata).
  final Duration slotLength;

  /// Koliko davalaca može da se primi u jednom slotu.
  final int slotCapacity;

  /// Počeci svih slotova akcije, redom.
  List<DateTime> get slots => [
    for (var t = start; !t.add(slotLength).isAfter(end); t = t.add(slotLength)) t,
  ];

  bool hasSlot(DateTime slotStart) => slots.contains(slotStart);

  @override
  List<Object?> get props => [id, title, city, address, start, end, slotLength, slotCapacity];

  @override
  String toString() => 'DonationDrive(${id.value}, $title)';
}
