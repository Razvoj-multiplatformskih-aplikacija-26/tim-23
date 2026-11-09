import 'package:domain/domain.dart';

/// Početni podaci sistema Kap: akcije, davaoci, termini u svim stanjima i demo nalozi.
///
/// Isti podaci pune bazu na serveru i lažne repozitorijume u aplikacijama (testovi).
/// Sva vremena se računaju od [now], pa demo radi kad god se pokrene: današnja akcija
/// je uvek u toku.
final class Seed {
  /// [utcOffset] null: vremena u lokalnom vremenu uređaja (aplikacije).
  /// [utcOffset] zadat: vremena u UTC-u, pomerena tako da u toj vremenskoj zoni akcija
  /// počinje u 9:00 (server u kontejneru radi u UTC-u, a Srbija je zimi UTC+1).
  Seed(this.now, {this.utcOffset});

  final DateTime now;
  final Duration? utcOffset;

  /// Davalac sa nalogom davalac1.
  static const firstDonor = DonorId('u-1');

  /// Korisnička imena demo naloga (lozinka je DEMO_PASSWORD iz .env).
  static const logins = {
    'u-1': 'davalac1',
    'u-2': 'davalac2',
    'u-sestra': 'sestra1',
    'u-koordinator': 'koordinator1',
  };

  /// Osoblje (backoffice).
  static const staff = [
    User(id: UserId('u-sestra'), name: 'Jovana Ilić', role: Role.nurse),
    User(id: UserId('u-koordinator'), name: 'Dragan Simić', role: Role.coordinator),
  ];

  /// Lokalni kalendar: današnji dan u zoni u kojoj se prikazuju podaci.
  DateTime get _localNow => switch (utcOffset) {
    null => now,
    final Duration offset => now.toUtc().add(offset),
  };

  DateTime _day(int offset) => DateTime(_localNow.year, _localNow.month, _localNow.day + offset);

  DateTime _at(int dayOffset, int hour, [int minute = 0]) => switch (utcOffset) {
    null => DateTime(now.year, now.month, now.day + dayOffset, hour, minute),
    final Duration offset => DateTime.utc(
      _localNow.year,
      _localNow.month,
      _localNow.day + dayOffset,
      hour,
      minute,
    ).subtract(offset),
  };

  /// Početak današnje akcije: tri sata pre sadašnjeg trenutka, na pola sata.
  late final DateTime _todayStart = _halfHour(now).subtract(const Duration(hours: 3));

  DateTime _halfHour(DateTime t) {
    if (utcOffset == null) return DateTime(t.year, t.month, t.day, t.hour, t.minute < 30 ? 0 : 30);
    final utc = t.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute < 30 ? 0 : 30);
  }

  late final List<DonationDrive> drives = [
    DonationDrive(
      id: const DriveId('d-danas'),
      title: 'Akcija na Računarskom fakultetu',
      city: 'Beograd',
      address: 'Knez Mihailova 6',
      start: _todayStart,
      end: _todayStart.add(const Duration(hours: 8)),
    ),
    DonationDrive(
      id: const DriveId('d-dom-omladine'),
      title: 'Akcija u Domu omladine',
      city: 'Beograd',
      address: 'Makedonska 22',
      start: _at(3, 9),
      end: _at(3, 15),
    ),
    DonationDrive(
      id: const DriveId('d-spens'),
      title: 'Akcija u SPENS-u',
      city: 'Novi Sad',
      address: 'Sutjeska 2',
      start: _at(7, 10),
      end: _at(7, 16),
    ),
    DonationDrive(
      id: const DriveId('d-nis'),
      title: 'Akcija na Univerzitetu u Nišu',
      city: 'Niš',
      address: 'Univerzitetski trg 2',
      start: _at(10, 9),
      end: _at(10, 14),
    ),
    DonationDrive(
      id: const DriveId('d-kragujevac'),
      title: 'Akcija u Domu zdravlja',
      city: 'Kragujevac',
      address: 'Kralja Milutina 1',
      start: _at(14, 9),
      end: _at(14, 13),
      slotCapacity: 2,
    ),
    DonationDrive(
      id: const DriveId('d-zavod'),
      title: 'Dan otvorenih vrata Zavoda',
      city: 'Beograd',
      address: 'Svetog Save 39',
      start: _at(21, 8),
      end: _at(21, 14),
      slotCapacity: 4,
    ),
    // Prošle akcije: istorija davanja.
    for (final (i, days) in [110, 220, 330, 450, 560, 700].indexed)
      DonationDrive(
        id: DriveId('d-proslo-${i + 1}'),
        title: 'Akcija u Domu omladine',
        city: 'Beograd',
        address: 'Makedonska 22',
        start: _at(-days, 9),
        end: _at(-days, 14),
      ),
  ];

  late final List<Donor> donors = [
    Donor(
      id: firstDonor,
      name: _name('Petar Jovanović'),
      birthDate: DateTime(2003, 4, 12),
      sex: Sex.male,
      bloodGroup: BloodGroup.aPositive,
      city: 'Beograd',
      lastDonation: _day(-110),
    ),
    for (final (i, (name, sex, group)) in [
      ('Ana Marković', Sex.female, BloodGroup.oPositive),
      ('Marko Ilić', Sex.male, BloodGroup.oNegative),
      ('Jelena Stojanović', Sex.female, BloodGroup.bPositive),
      ('Nikola Pavlović', Sex.male, BloodGroup.aNegative),
      ('Milica Đorđević', Sex.female, BloodGroup.abPositive),
      ('Stefan Nikolić', Sex.male, BloodGroup.aPositive),
      ('Teodora Lukić', Sex.female, BloodGroup.oPositive),
      ('Luka Popović', Sex.male, BloodGroup.bNegative),
      ('Sara Kovačević', Sex.female, BloodGroup.aPositive),
      ('Vuk Milošević', Sex.male, BloodGroup.oPositive),
      ('Ivana Tomić', Sex.female, BloodGroup.abNegative),
      ('Đorđe Savić', Sex.male, BloodGroup.aPositive),
      ('Katarina Ristić', Sex.female, BloodGroup.oNegative),
      ('Aleksa Jović', Sex.male, BloodGroup.bPositive),
      ('Mina Lazić', Sex.female, BloodGroup.aPositive),
    ].indexed)
      Donor(
        id: DonorId('u-${i + 2}'),
        name: _name(name),
        birthDate: DateTime(1980 + i * 2, 1 + i % 12, 3 + i),
        sex: sex,
        bloodGroup: group,
        city: 'Beograd',
        lastDonation: i.isEven ? _day(-200 - i * 10) : null,
      ),
  ];

  late final List<Appointment> appointments = [
    // Davalac u-1 (mobilna aplikacija): istorija i jedan aktivan termin.
    _a('a-1', 'u-1', 'd-proslo-6', _at(-700, 9), Donated(at: _at(-700, 9, 20))),
    _a('a-2', 'u-1', 'd-proslo-5', _at(-560, 10), Cancelled(at: _at(-562, 18), byStaff: false)),
    _a('a-3', 'u-1', 'd-proslo-4', _at(-450, 11), Donated(at: _at(-450, 11, 25))),
    _a('a-4', 'u-1', 'd-proslo-3', _at(-330, 9, 30), NoShow(at: _at(-330, 10))),
    _a(
      'a-5',
      'u-1',
      'd-proslo-2',
      _at(-220, 12),
      Deferred(at: _at(-220, 12, 15), reason: 'Nizak hemoglobin'),
    ),
    _a('a-6', 'u-1', 'd-proslo-1', _at(-110, 10), Donated(at: _at(-110, 10, 20))),
    _a('a-7', 'u-1', 'd-spens', _at(7, 11), Cancelled(at: _at(-1, 20), byStaff: false)),
    _a('a-8', 'u-1', 'd-dom-omladine', _at(3, 9), Confirmed(at: _at(-1, 9))),

    // Današnja akcija (backoffice): sva stanja na jednom mestu.
    _today('a-20', 'u-2', 0, Donated(at: _todayStart.add(const Duration(minutes: 25)))),
    _today('a-21', 'u-3', 30, Deferred(at: _todayStart.add(const Duration(minutes: 40)), reason: 'Povišen pritisak')),
    _today('a-22', 'u-4', 60, NoShow(at: _todayStart.add(const Duration(minutes: 95)))),
    _today('a-23', 'u-5', 90, Donated(at: _todayStart.add(const Duration(minutes: 110)))),
    _today('a-24', 'u-6', 120, CheckedIn(at: _todayStart.add(const Duration(minutes: 115)))),
    _today('a-25', 'u-7', 150, Confirmed(at: _todayStart.subtract(const Duration(hours: 20)))),
    _today('a-26', 'u-8', 180, const Scheduled()),
    _today('a-27', 'u-9', 180, Confirmed(at: _todayStart.subtract(const Duration(hours: 18)))),
    _today('a-28', 'u-10', 210, const Scheduled()),
    _today('a-29', 'u-11', 240, Cancelled(at: _todayStart, byStaff: true, reason: 'Davalac se razboleo')),
    _today('a-30', 'u-12', 270, const Scheduled()),
    _today('a-31', 'u-13', 330, Confirmed(at: _todayStart.subtract(const Duration(hours: 5)))),

    // Akcija u Domu omladine: pun slot u 10:00 (pravilo kapaciteta).
    _a('a-40', 'u-14', 'd-dom-omladine', _at(3, 10), const Scheduled()),
    _a('a-41', 'u-15', 'd-dom-omladine', _at(3, 10), Confirmed(at: _at(-2, 8))),
    _a('a-42', 'u-16', 'd-dom-omladine', _at(3, 10), const Scheduled()),
  ];

  Appointment _a(String id, String donorId, String driveId, DateTime slotStart, AppointmentStatus status) =>
      Appointment(
        id: AppointmentId(id),
        donorId: DonorId(donorId),
        driveId: DriveId(driveId),
        slotStart: slotStart,
        status: status,
      );

  Appointment _today(String id, String donorId, int minutesFromStart, AppointmentStatus status) =>
      _a(id, donorId, 'd-danas', _todayStart.add(Duration(minutes: minutesFromStart)), status);

  static DonorName _name(String value) => DonorName.parse(value).valueOrNull!;
}
