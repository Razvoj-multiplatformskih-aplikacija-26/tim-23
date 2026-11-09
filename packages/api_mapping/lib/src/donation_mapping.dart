import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

// Vreme na mreži je uvek UTC; klijent ga za prikaz pretvara u lokalno.

extension DonationDriveMapping on DonationDrive {
  DriveDto toDto() => DriveDto(
    id: id.value,
    title: title,
    city: city,
    address: address,
    start: start.toUtc(),
    end: end.toUtc(),
    slotMinutes: slotLength.inMinutes,
    slotCapacity: slotCapacity,
  );
}

extension DriveDtoMapping on DriveDto {
  DonationDrive toDomain() => DonationDrive(
    id: DriveId(id),
    title: title,
    city: city,
    address: address,
    start: start,
    end: end,
    slotLength: Duration(minutes: slotMinutes),
    slotCapacity: slotCapacity,
  );
}

extension DonorMapping on Donor {
  DonorDto toDto() => DonorDto(
    id: id.value,
    name: name.value,
    birthDate: birthDate,
    sex: sex.name,
    bloodGroup: bloodGroup.name,
    city: city,
    lastDonation: lastDonation,
  );

  ProfileDto toProfileDto() => ProfileDto(
    name: name.value,
    birthDate: birthDate,
    sex: sex.name,
    bloodGroup: bloodGroup.name,
    city: city,
    lastDonation: lastDonation,
  );
}

extension DonorDtoMapping on DonorDto {
  Donor toDomain() => Donor(
    id: DonorId(id),
    name: switch (DonorName.parse(name)) {
      Success(:final value) => value,
      Failure() => throw FormatException('Invalid donor name', name),
    },
    birthDate: birthDate,
    sex: sexFromJson(sex),
    bloodGroup: bloodGroupFromJson(bloodGroup),
    city: city,
    lastDonation: lastDonation,
  );
}

Sex sexFromJson(String value) =>
    Sex.values.asNameMap()[value] ?? (throw FormatException('Unknown sex', value));

BloodGroup bloodGroupFromJson(String value) =>
    BloodGroup.values.asNameMap()[value] ?? (throw FormatException('Unknown blood group', value));

extension AppointmentStatusMapping on AppointmentStatus {
  String get kind => switch (this) {
    Scheduled() => AppointmentStatusDto.scheduled,
    Confirmed() => AppointmentStatusDto.confirmed,
    CheckedIn() => AppointmentStatusDto.checkedIn,
    Donated() => AppointmentStatusDto.donated,
    Deferred() => AppointmentStatusDto.deferred,
    Cancelled() => AppointmentStatusDto.cancelled,
    NoShow() => AppointmentStatusDto.noShow,
  };

  AppointmentStatusDto toDto() => switch (this) {
    Scheduled() => const AppointmentStatusDto(kind: AppointmentStatusDto.scheduled),
    Confirmed(:final at) => AppointmentStatusDto(kind: kind, at: at.toUtc()),
    CheckedIn(:final at) => AppointmentStatusDto(kind: kind, at: at.toUtc()),
    Donated(:final at) => AppointmentStatusDto(kind: kind, at: at.toUtc()),
    Deferred(:final at, :final reason) => AppointmentStatusDto(kind: kind, at: at.toUtc(), reason: reason),
    Cancelled(:final at, :final byStaff, :final reason) => AppointmentStatusDto(
      kind: kind,
      at: at.toUtc(),
      reason: reason,
      byStaff: byStaff,
    ),
    NoShow(:final at) => AppointmentStatusDto(kind: kind, at: at.toUtc()),
  };
}

extension AppointmentStatusDtoMapping on AppointmentStatusDto {
  AppointmentStatus toDomain() => switch (this) {
    AppointmentStatusDto(kind: AppointmentStatusDto.scheduled) => const Scheduled(),
    AppointmentStatusDto(kind: AppointmentStatusDto.confirmed, :final at?) => Confirmed(at: at),
    AppointmentStatusDto(kind: AppointmentStatusDto.checkedIn, :final at?) => CheckedIn(at: at),
    AppointmentStatusDto(kind: AppointmentStatusDto.donated, :final at?) => Donated(at: at),
    AppointmentStatusDto(kind: AppointmentStatusDto.deferred, :final at?, :final reason) => Deferred(
      at: at,
      reason: reason ?? '',
    ),
    AppointmentStatusDto(kind: AppointmentStatusDto.cancelled, :final at?, :final reason, :final byStaff) =>
      Cancelled(at: at, byStaff: byStaff ?? false, reason: reason ?? ''),
    AppointmentStatusDto(kind: AppointmentStatusDto.noShow, :final at?) => NoShow(at: at),
    _ => throw FormatException('Unknown appointment status', kind),
  };
}

extension AppointmentMapping on Appointment {
  AppointmentDto toDto() => AppointmentDto(
    id: id.value,
    donorId: donorId.value,
    driveId: driveId.value,
    slotStart: slotStart.toUtc(),
    slotMinutes: slotLength.inMinutes,
    status: status.toDto(),
  );
}

extension AppointmentDtoMapping on AppointmentDto {
  Appointment toDomain() => Appointment(
    id: AppointmentId(id),
    donorId: DonorId(donorId),
    driveId: DriveId(driveId),
    slotStart: slotStart,
    slotLength: Duration(minutes: slotMinutes),
    status: status.toDomain(),
  );
}

extension UserMapping on User {
  UserDto toDto() => UserDto(id: id.value, name: name, role: role.name);
}

extension UserDtoMapping on UserDto {
  User toDomain() => User(
    id: UserId(id),
    name: name,
    role: Role.values.asNameMap()[role] ?? (throw FormatException('Unknown role', role)),
  );
}
