import 'package:domain/domain.dart';
import 'package:test/test.dart';

const donor = User(id: UserId('u-1'), name: 'Petar Jovanović', role: Role.donor);
const otherDonor = User(id: UserId('u-2'), name: 'Ana Marković', role: Role.donor);
const nurse = User(id: UserId('u-sestra'), name: 'Jovana Ilić', role: Role.nurse);
const coordinator = User(id: UserId('u-koordinator'), name: 'Dragan Simić', role: Role.coordinator);

final appointment = Appointment(
  id: const AppointmentId('a-1'),
  donorId: const DonorId('u-1'),
  driveId: const DriveId('d-1'),
  slotStart: DateTime.utc(2026, 11, 10, 9),
  status: const Scheduled(),
);

void main() {
  test('mobilna aplikacija je za davaoce, backoffice za osoblje', () {
    expect(AccessPolicy.canUseMobileApp(donor), isTrue);
    expect(AccessPolicy.canUseMobileApp(nurse), isFalse);
    expect(AccessPolicy.canUseBackoffice(donor), isFalse);
    expect(AccessPolicy.canUseBackoffice(coordinator), isTrue);
  });

  test('davalac otkazuje i potvrđuje samo svoj termin', () {
    expect(AccessPolicy.canCancel(donor, appointment), isTrue);
    expect(AccessPolicy.canCancel(otherDonor, appointment), isFalse);
    expect(AccessPolicy.canConfirm(donor, appointment), isTrue);
    expect(AccessPolicy.canConfirm(otherDonor, appointment), isFalse);
  });

  test('ishod pregleda beleži osoblje, a otkazuje koordinator', () {
    expect(AccessPolicy.canPerform(donor, StaffAction.donated), isFalse);
    expect(AccessPolicy.canPerform(nurse, StaffAction.donated), isTrue);
    expect(AccessPolicy.canPerform(nurse, StaffAction.cancel), isFalse);
    expect(AccessPolicy.canPerform(coordinator, StaffAction.cancel), isTrue);
  });

  test('davalac vidi samo svoj profil', () {
    expect(AccessPolicy.canViewDonor(donor, const DonorId('u-1')), isTrue);
    expect(AccessPolicy.canViewDonor(donor, const DonorId('u-2')), isFalse);
    expect(AccessPolicy.canViewDonor(nurse, const DonorId('u-2')), isTrue);
  });
}
