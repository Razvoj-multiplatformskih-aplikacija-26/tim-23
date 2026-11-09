import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

/// Svi tekstovi za korisnika su ovde, na srpskom. Domen vraća grešku kao tip,
/// a ovde se bira reč. switch bez default grane: nova greška u domenu
/// prijavi grešku kompajliranja dok joj se ne doda poruka.
String errorMessage(DomainError error) => switch (error) {
  InvalidDonorName(:final min, :final max) => 'Ime i prezime mora imati od $min do $max znakova.',
  AgeOutOfRange(:final min, :final max) => 'Krv mogu da daju osobe od $min do $max godina.',
  LastDonationInFuture() => 'Datum poslednjeg davanja ne može biti u budućnosti.',
  TooSoonToDonate(:final nextAllowed) => 'Krv ponovo možete dati od ${formatDate(nextAllowed)}.',
  ActiveAppointmentExists() => 'Već imate zakazan termin. Otkažite ga da biste zakazali novi.',
  SlotFull() => 'U ovom terminu više nema slobodnih mesta. Izaberite drugi.',
  SlotInPast() => 'Ovaj termin je već počeo.',
  SlotNotInDrive() => 'Izabrano vreme nije termin ove akcije.',
  CancellationTooLate(:final deadline) => 'Termin je mogao da se otkaže najkasnije do ${formatDateTime(deadline)}.',
  AppointmentStarted() => 'Termin je već počeo.',
  CheckInOutsideWindow() => 'Dolazak se beleži od sat vremena pre do dva sata posle početka termina.',
  AppointmentNotStarted() => '„Nije došao“ može tek kada termin počne.',
  InvalidDeferralReason(:final min, :final max) => 'Razlog mora imati od $min do $max znakova.',
  InvalidTransition() => 'Ova promena nije dozvoljena u trenutnom stanju termina.',
  NotFound() => 'Zapis nije pronađen.',
  NotAllowed() => 'Nemate pravo na ovu akciju.',
};

String statusLabel(AppointmentStatus status) => switch (status) {
  Scheduled() => 'Zakazan',
  Confirmed() => 'Potvrđen',
  CheckedIn() => 'Pristupio',
  Donated() => 'Dao krv',
  Deferred() => 'Odbijen na pregledu',
  Cancelled() => 'Otkazan',
  NoShow() => 'Nije se pojavio',
};

String bloodGroupLabel(BloodGroup group) => switch (group) {
  BloodGroup.oPositive => '0+',
  BloodGroup.oNegative => '0−',
  BloodGroup.aPositive => 'A+',
  BloodGroup.aNegative => 'A−',
  BloodGroup.bPositive => 'B+',
  BloodGroup.bNegative => 'B−',
  BloodGroup.abPositive => 'AB+',
  BloodGroup.abNegative => 'AB−',
};

String sexLabel(Sex sex) => switch (sex) {
  Sex.male => 'Muški',
  Sex.female => 'Ženski',
};

String staffActionLabel(StaffAction action) => switch (action) {
  StaffAction.checkIn => 'Pristupio',
  StaffAction.donated => 'Dao krv',
  StaffAction.deferred => 'Odbijen na pregledu',
  StaffAction.noShow => 'Nije došao',
  StaffAction.cancel => 'Otkaži',
};

/// Prečica na tastaturi za akciju osoblja (prikazuje se uz dugme).
String staffActionKey(StaffAction action) => switch (action) {
  StaffAction.checkIn => 'A',
  StaffAction.donated => 'K',
  StaffAction.deferred => 'O',
  StaffAction.noShow => 'N',
  StaffAction.cancel => 'X',
};

String staffActionDoneMessage(StaffAction action) => switch (action) {
  StaffAction.checkIn => 'Zabeležen je dolazak davaoca.',
  StaffAction.donated => 'Zabeleženo je davanje krvi. Hvala!',
  StaffAction.deferred => 'Zabeleženo je odbijanje na pregledu.',
  StaffAction.noShow => 'Zabeleženo je da davalac nije došao.',
  StaffAction.cancel => 'Termin je otkazan.',
};

/// Poruka kada podaci nisu stigli, a razlog nije poznat.
const failureMessage = 'Podaci trenutno nisu dostupni. Proverite vezu i pokušajte ponovo.';

const serverUnreachableMessage = 'Nema veze sa serverom. Proverite vezu i pokušajte ponovo.';

const sessionExpiredMessage = 'Prijava je istekla. Prijavite se ponovo.';

/// Poruka za grešku pristupa podacima, bez tehničkog teksta.
String failureMessageFor(Object? cause) => switch (cause) {
  RepositoryException(failure: RepositoryFailure.unreachable) => serverUnreachableMessage,
  RepositoryException(failure: RepositoryFailure.serverError) => 'Greška na serveru. Pokušajte ponovo malo kasnije.',
  // Kôd koji ova verzija aplikacije ne zna (npr. novo pravilo na serveru).
  RepositoryException(failure: RepositoryFailure.refused) =>
    'Server nije dozvolio ovu akciju. Osvežite podatke ili ažurirajte aplikaciju.',
  RepositoryException(failure: RepositoryFailure.sessionExpired) => sessionExpiredMessage,
  _ => failureMessage,
};

String roleLabel(Role role) => switch (role) {
  Role.donor => 'Davalac',
  Role.nurse => 'Medicinska sestra',
  Role.coordinator => 'Koordinator',
};

const _weekdays = ['ponedeljak', 'utorak', 'sreda', 'četvrtak', 'petak', 'subota', 'nedelja'];
const _months = [
  'januar',
  'februar',
  'mart',
  'april',
  'maj',
  'jun',
  'jul',
  'avgust',
  'septembar',
  'oktobar',
  'novembar',
  'decembar',
];

String _two(int n) => n.toString().padLeft(2, '0');

// Vreme sa servera stiže u UTC-u; prikazuje se u lokalnom vremenu uređaja.

/// 10. 11. 2026.
String formatDate(DateTime t) {
  final local = t.toLocal();
  return '${local.day}. ${local.month}. ${local.year}.';
}

/// 09:30
String formatTime(DateTime t) {
  final local = t.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// 10. 11. 2026. u 09:30
String formatDateTime(DateTime t) => '${formatDate(t)} u ${formatTime(t)}';

/// utorak, 10. novembar
String formatLongDate(DateTime t) {
  final local = t.toLocal();
  return '${_weekdays[local.weekday - 1]}, ${local.day}. ${_months[local.month - 1]}';
}

/// 09:00–15:00
String formatTimeRange(DateTime start, DateTime end) => '${formatTime(start)}–${formatTime(end)}';

/// Čita datum u obliku dd.mm.gggg (tačka na kraju i razmaci su dozvoljeni).
DateTime? parseDate(String input) {
  final match = RegExp(r'^\s*(\d{1,2})\s*\.\s*(\d{1,2})\s*\.\s*(\d{4})\s*\.?\s*$').firstMatch(input);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  // DateTime(2026, 2, 31) postaje 3. mart; takav datum ne postoji.
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// 10.11.2026 (za polje forme).
String formatDateInput(DateTime t) => '${_two(t.day)}.${_two(t.month)}.${t.year}';
