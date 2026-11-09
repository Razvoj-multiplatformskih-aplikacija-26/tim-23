import 'json.dart';

/// Akcija davanja krvi. Vreme putuje kao trenutak u UTC-u („2026-11-10T08:00:00Z“).
final class DriveDto {
  const DriveDto({
    required this.id,
    required this.title,
    required this.city,
    required this.address,
    required this.start,
    required this.end,
    required this.slotMinutes,
    required this.slotCapacity,
  });

  final String id;
  final String title;
  final String city;
  final String address;
  final DateTime start;
  final DateTime end;
  final int slotMinutes;
  final int slotCapacity;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'city': city,
    'address': address,
    'start': instantToJson(start),
    'end': instantToJson(end),
    'slotMinutes': slotMinutes,
    'slotCapacity': slotCapacity,
  };

  factory DriveDto.fromJson(Map<String, Object?> json) => DriveDto(
    id: jsonString(json, 'id'),
    title: jsonString(json, 'title'),
    city: jsonString(json, 'city'),
    address: jsonString(json, 'address'),
    start: jsonInstant(json, 'start'),
    end: jsonInstant(json, 'end'),
    slotMinutes: jsonInt(json, 'slotMinutes'),
    slotCapacity: jsonInt(json, 'slotCapacity'),
  );
}

/// Davalac. Datumi (rođenje, poslednje davanje) putuju kao kalendarski dan „2003-04-12“.
/// Pol i krvna grupa putuju kao reči („male“, „aPositive“).
final class DonorDto {
  const DonorDto({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.bloodGroup,
    required this.city,
    this.lastDonation,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final String sex;
  final String bloodGroup;
  final String city;
  final DateTime? lastDonation;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'birthDate': dayToJson(birthDate),
    'sex': sex,
    'bloodGroup': bloodGroup,
    'city': city,
    if (lastDonation case final day?) 'lastDonation': dayToJson(day),
  };

  factory DonorDto.fromJson(Map<String, Object?> json) => DonorDto(
    id: jsonString(json, 'id'),
    name: jsonString(json, 'name'),
    birthDate: jsonDay(json, 'birthDate'),
    sex: jsonString(json, 'sex'),
    bloodGroup: jsonString(json, 'bloodGroup'),
    city: jsonString(json, 'city'),
    lastDonation: jsonOptionalDay(json, 'lastDonation'),
  );
}

/// Izmena profila: isto što i davalac, bez id-ja (id je u putanji).
final class ProfileDto {
  const ProfileDto({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.bloodGroup,
    required this.city,
    this.lastDonation,
  });

  final String name;
  final DateTime birthDate;
  final String sex;
  final String bloodGroup;
  final String city;
  final DateTime? lastDonation;

  Map<String, Object?> toJson() => {
    'name': name,
    'birthDate': dayToJson(birthDate),
    'sex': sex,
    'bloodGroup': bloodGroup,
    'city': city,
    if (lastDonation case final day?) 'lastDonation': dayToJson(day),
  };

  factory ProfileDto.fromJson(Map<String, Object?> json) => ProfileDto(
    name: jsonString(json, 'name'),
    birthDate: jsonDay(json, 'birthDate'),
    sex: jsonString(json, 'sex'),
    bloodGroup: jsonString(json, 'bloodGroup'),
    city: jsonString(json, 'city'),
    lastDonation: jsonOptionalDay(json, 'lastDonation'),
  );
}

/// Stanje termina na mreži: vrsta stanja i podaci koje to stanje nosi.
final class AppointmentStatusDto {
  const AppointmentStatusDto({required this.kind, this.at, this.reason, this.byStaff});

  static const scheduled = 'scheduled';
  static const confirmed = 'confirmed';
  static const checkedIn = 'checked-in';
  static const donated = 'donated';
  static const deferred = 'deferred';
  static const cancelled = 'cancelled';
  static const noShow = 'no-show';

  final String kind;
  final DateTime? at;
  final String? reason;
  final bool? byStaff;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (at case final at?) 'at': instantToJson(at),
    'reason': ?reason,
    'byStaff': ?byStaff,
  };

  factory AppointmentStatusDto.fromJson(Map<String, Object?> json) => AppointmentStatusDto(
    kind: jsonString(json, 'kind'),
    at: jsonOptionalInstant(json, 'at'),
    reason: jsonOptionalString(json, 'reason'),
    byStaff: jsonOptionalBool(json, 'byStaff'),
  );
}

/// Termin davanja. Davalac za tuđe termine dobija samo zauzetost slota:
/// bez id-ja davaoca i bez razloga (vidi server).
final class AppointmentDto {
  const AppointmentDto({
    required this.id,
    required this.donorId,
    required this.driveId,
    required this.slotStart,
    required this.slotMinutes,
    required this.status,
  });

  final String id;
  final String donorId;
  final String driveId;
  final DateTime slotStart;
  final int slotMinutes;
  final AppointmentStatusDto status;

  Map<String, Object?> toJson() => {
    'id': id,
    'donorId': donorId,
    'driveId': driveId,
    'slotStart': instantToJson(slotStart),
    'slotMinutes': slotMinutes,
    'status': status.toJson(),
  };

  factory AppointmentDto.fromJson(Map<String, Object?> json) => AppointmentDto(
    id: jsonString(json, 'id'),
    donorId: jsonString(json, 'donorId'),
    driveId: jsonString(json, 'driveId'),
    slotStart: jsonInstant(json, 'slotStart'),
    slotMinutes: jsonInt(json, 'slotMinutes'),
    status: AppointmentStatusDto.fromJson(jsonObject(json['status'])),
  );
}

/// Zahtev za novi termin. Davalac je onaj ko je prijavljen, pa ne putuje u telu.
final class NewAppointmentDto {
  const NewAppointmentDto({required this.driveId, required this.slotStart});

  final String driveId;
  final DateTime slotStart;

  Map<String, Object?> toJson() => {'driveId': driveId, 'slotStart': instantToJson(slotStart)};

  factory NewAppointmentDto.fromJson(Map<String, Object?> json) =>
      NewAppointmentDto(driveId: jsonString(json, 'driveId'), slotStart: jsonInstant(json, 'slotStart'));
}

/// Razlog uz otkazivanje ili odbijanje na pregledu.
final class ReasonDto {
  const ReasonDto({this.reason = ''});

  final String reason;

  Map<String, Object?> toJson() => {'reason': reason};

  factory ReasonDto.fromJson(Map<String, Object?> json) => ReasonDto(reason: jsonOptionalString(json, 'reason') ?? '');
}
