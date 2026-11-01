import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';

enum Sex { male, female }

enum BloodGroup { oPositive, oNegative, aPositive, aNegative, bPositive, bNegative, abPositive, abNegative }

/// Ime i prezime davaoca. Nevažeće ime ne može da postoji:
/// vrednost nastaje samo kroz [DonorName.parse].
final class DonorName extends Equatable {
  const DonorName._(this.value);

  static const minLength = 2;
  static const maxLength = 60;

  final String value;

  static Result<DonorName> parse(String input) {
    final text = input.trim();
    if (text.length < minLength || text.length > maxLength) {
      return Failure(InvalidDonorName(length: text.length, min: minLength, max: maxLength));
    }
    return Success(DonorName._(text));
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

final class Donor extends Equatable {
  const Donor({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.bloodGroup,
    required this.city,
    this.lastDonation,
  });

  final DonorId id;
  final DonorName name;
  final DateTime birthDate;
  final Sex sex;
  final BloodGroup bloodGroup;
  final String city;

  /// Poslednje davanje krvi; null ako davalac još nije davao.
  final DateTime? lastDonation;

  Donor copyWith({
    DonorName? name,
    DateTime? birthDate,
    Sex? sex,
    BloodGroup? bloodGroup,
    String? city,
    DateTime? lastDonation,
    bool clearLastDonation = false,
  }) => Donor(
    id: id,
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
    bloodGroup: bloodGroup ?? this.bloodGroup,
    city: city ?? this.city,
    lastDonation: clearLastDonation ? null : (lastDonation ?? this.lastDonation),
  );

  @override
  List<Object?> get props => [id, name, birthDate, sex, bloodGroup, city, lastDonation];

  @override
  String toString() => 'Donor(${id.value}, $name)';
}
