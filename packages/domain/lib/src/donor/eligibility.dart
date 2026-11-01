import '../errors.dart';
import '../result.dart';
import 'donor.dart';

/// Najmanje i najviše godina za davanje krvi.
const minDonorAge = 18;
const maxDonorAge = 65;

/// Razmak između dva davanja, u mesecima.
int monthsBetweenDonations(Sex sex) => switch (sex) {
  Sex.male => 3,
  Sex.female => 4,
};

/// Pun broj godina na dan [on].
int ageOn(DateTime birthDate, DateTime on) {
  var age = on.year - birthDate.year;
  final hadBirthday = on.month > birthDate.month || (on.month == birthDate.month && on.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age;
}

/// Pravilo: davalac na dan [on] ima između 18 i 65 godina.
Result<DateTime> checkAge({required DateTime birthDate, required DateTime on}) {
  final age = ageOn(birthDate, on);
  if (age < minDonorAge || age > maxDonorAge) {
    return Failure(AgeOutOfRange(age: age, min: minDonorAge, max: maxDonorAge));
  }
  return Success(birthDate);
}

/// Prvi dan kada davalac ponovo sme da da krv; null ako još nije davao.
DateTime? nextAllowedDonation({required Sex sex, required DateTime? lastDonation}) {
  if (lastDonation == null) return null;
  return addMonths(_day(lastDonation), monthsBetweenDonations(sex));
}

/// Pravilo: od poslednjeg davanja prošlo je najmanje 3 meseca (muškarci),
/// odnosno 4 meseca (žene).
Result<DateTime> checkDonationInterval({
  required Sex sex,
  required DateTime? lastDonation,
  required DateTime donationTime,
}) {
  final next = nextAllowedDonation(sex: sex, lastDonation: lastDonation);
  if (next != null && _day(donationTime).isBefore(next)) return Failure(TooSoonToDonate(next));
  return Success(donationTime);
}

/// Pravilo: datum poslednjeg davanja ne sme biti u budućnosti.
Result<DateTime?> checkLastDonation(DateTime? lastDonation, {required DateTime now}) {
  if (lastDonation != null && _day(lastDonation).isAfter(_day(now))) return const Failure(LastDonationInFuture());
  return Success(lastDonation);
}

/// Izmena profila davaoca: sva pravila profila na jednom mestu.
Result<Donor> updateProfile(
  Donor donor, {
  required String name,
  required DateTime birthDate,
  required Sex sex,
  required BloodGroup bloodGroup,
  required String city,
  required DateTime? lastDonation,
  required DateTime now,
}) {
  final parsedName = DonorName.parse(name);
  if (parsedName case Failure(:final error)) return Failure(error);
  if (checkAge(birthDate: birthDate, on: now) case Failure(:final error)) return Failure(error);
  if (checkLastDonation(lastDonation, now: now) case Failure(:final error)) return Failure(error);
  return Success(
    Donor(
      id: donor.id,
      name: parsedName.valueOrNull!,
      birthDate: birthDate,
      sex: sex,
      bloodGroup: bloodGroup,
      city: city.trim(),
      lastDonation: lastDonation,
    ),
  );
}

/// Dodaje [months] meseci; 31. januar + 1 mesec je 28/29. februar, a ne 3. mart.
DateTime addMonths(DateTime date, int months) {
  final firstOfTarget = DateTime(date.year, date.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(firstOfTarget.year, firstOfTarget.month, day);
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
