part of 'profile_bloc.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

final class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

final class ProfileSubmitted extends ProfileEvent {
  const ProfileSubmitted({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.bloodGroup,
    required this.city,
    required this.lastDonation,
  });

  final String name;
  final DateTime birthDate;
  final Sex sex;
  final BloodGroup bloodGroup;
  final String city;
  final DateTime? lastDonation;
}

final class ProfileNoticeAcknowledged extends ProfileEvent {
  const ProfileNoticeAcknowledged();
}
