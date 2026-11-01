import 'package:domain/domain.dart';
import 'package:test/test.dart';

final now = DateTime(2026, 11, 3, 10);

final drive = DonationDrive(
  id: const DriveId('d-1'),
  title: 'Akcija u Domu omladine',
  city: 'Beograd',
  address: 'Makedonska 22',
  start: DateTime(2026, 11, 10, 9),
  end: DateTime(2026, 11, 10, 12),
);

Donor donor({DateTime? lastDonation, Sex sex = Sex.male, DateTime? birthDate}) => Donor(
  id: const DonorId('u-1'),
  name: DonorName.parse('Ilija Živadinović').valueOrNull!,
  birthDate: birthDate ?? DateTime(2004, 5, 1),
  sex: sex,
  bloodGroup: BloodGroup.aPositive,
  city: 'Beograd',
  lastDonation: lastDonation,
);

Appointment appointment(AppointmentStatus status, {DateTime? slotStart, String id = 'a-1', String donorId = 'u-1'}) =>
    Appointment(
      id: AppointmentId(id),
      donorId: DonorId(donorId),
      driveId: drive.id,
      slotStart: slotStart ?? DateTime(2026, 11, 10, 9),
      status: status,
    );

Result<Appointment> book({
  Donor? who,
  DateTime? slot,
  List<Appointment> mine = const [],
  List<Appointment> others = const [],
}) => bookAppointment(
  id: const AppointmentId('a-new'),
  donor: who ?? donor(),
  drive: drive,
  slotStart: slot ?? DateTime(2026, 11, 10, 9),
  donorAppointments: mine,
  driveAppointments: [...mine, ...others],
  now: now,
);

void main() {
  group('stanja', () {
    test('zakazan termin može da se potvrdi, otkaže, a davalac da pristupi', () {
      expect(canTransition(const Scheduled(), Confirmed(at: now)), isTrue);
      expect(canTransition(const Scheduled(), Cancelled(at: now, byStaff: false)), isTrue);
      expect(canTransition(const Scheduled(), CheckedIn(at: now)), isTrue);
    });

    test('krv daje samo davalac koji je pristupio', () {
      expect(canTransition(const Scheduled(), Donated(at: now)), isFalse);
      expect(canTransition(CheckedIn(at: now), Donated(at: now)), isTrue);
    });

    test('iz završnog stanja nema prelaza', () {
      expect(canTransition(Donated(at: now), Cancelled(at: now, byStaff: true)), isFalse);
      expect(canTransition(NoShow(at: now), CheckedIn(at: now)), isFalse);
    });
  });

  group('pravila davaoca', () {
    test('ime mora imati od 2 do 60 znakova', () {
      expect(DonorName.parse('A'), isA<Failure<DonorName>>());
      expect(DonorName.parse('  Ana  ').valueOrNull?.value, 'Ana');
    });

    test('davalac mora imati od 18 do 65 godina', () {
      expect(checkAge(birthDate: DateTime(2010, 1, 1), on: now).errorOrNull, isA<AgeOutOfRange>());
      expect(checkAge(birthDate: DateTime(1950, 1, 1), on: now).errorOrNull, isA<AgeOutOfRange>());
      expect(checkAge(birthDate: DateTime(2000, 1, 1), on: now).isSuccess, isTrue);
    });

    test('muškarac čeka 3 meseca, žena 4', () {
      final last = DateTime(2026, 8, 1);
      expect(nextAllowedDonation(sex: Sex.male, lastDonation: last), DateTime(2026, 11, 1));
      expect(nextAllowedDonation(sex: Sex.female, lastDonation: last), DateTime(2026, 12, 1));
    });

    test('31. januar + 1 mesec je kraj februara', () {
      expect(addMonths(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28));
    });
  });

  group('zakazivanje', () {
    test('slobodan slot se zakazuje kao „zakazan“', () {
      final result = book();
      expect(result.valueOrNull?.status, const Scheduled());
    });

    test('prerano od poslednjeg davanja', () {
      final result = book(who: donor(lastDonation: DateTime(2026, 9, 1)));
      expect(result.errorOrNull, TooSoonToDonate(DateTime(2026, 12, 1)));
    });

    test('najviše jedan aktivan termin', () {
      final result = book(mine: [appointment(const Scheduled(), slotStart: DateTime(2026, 11, 10, 11))]);
      expect(result.errorOrNull, const ActiveAppointmentExists());
    });

    test('pun slot se ne može zakazati', () {
      final others = [
        for (var i = 0; i < drive.slotCapacity; i++) appointment(const Scheduled(), id: 'o-$i', donorId: 'u-o$i'),
      ];
      expect(book(others: others).errorOrNull, const SlotFull());
    });

    test('otkazan termin ne zauzima mesto', () {
      final others = [
        for (var i = 0; i < drive.slotCapacity; i++)
          appointment(Cancelled(at: now, byStaff: false), id: 'o-$i', donorId: 'u-o$i'),
      ];
      expect(book(others: others).isSuccess, isTrue);
    });
  });

  group('otkazivanje', () {
    test('davalac otkazuje najkasnije 12 sati pre', () {
      final a = appointment(const Scheduled());
      final late = DateTime(2026, 11, 9, 22);
      expect(cancelAppointment(a, byStaff: false, now: late).errorOrNull, isA<CancellationTooLate>());
      expect(cancelAppointment(a, byStaff: true, now: late).isSuccess, isTrue);
      expect(cancelAppointment(a, byStaff: false, now: now).isSuccess, isTrue);
    });
  });

  group('osoblje', () {
    test('dolazak samo oko vremena termina', () {
      final a = appointment(Confirmed(at: DateTime(2026, 11, 2)));
      expect(checkIn(a, now: now).errorOrNull, const CheckInOutsideWindow());
      expect(checkIn(a, now: DateTime(2026, 11, 10, 8, 30)).isSuccess, isTrue);
    });

    test('razlog odbijanja je obavezan', () {
      final a = appointment(CheckedIn(at: now));
      expect(recordDeferral(a, reason: '', now: now).errorOrNull, isA<InvalidDeferralReason>());
      expect(recordDeferral(a, reason: 'Nizak hemoglobin', now: now).isSuccess, isTrue);
    });

    test('akcije osoblja prate stanje', () {
      final a = appointment(CheckedIn(at: now));
      expect(staffActionsFor(a, now: now), {StaffAction.donated, StaffAction.deferred});
    });
  });

  group('slobodna mesta', () {
    test('računaju se po slotu', () {
      final slots = slotAvailability(
        drive: drive,
        appointments: [appointment(const Scheduled())],
        now: now,
      );
      expect(slots.first.free, drive.slotCapacity - 1);
      expect(slots.length, 6);
    });
  });
}
