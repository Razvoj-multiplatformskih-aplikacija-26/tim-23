import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('svaka greška domena ide na mrežu i vraća se ista', () {
    final errors = <DomainError>[
      const InvalidDonorName(length: 1, min: 2, max: 60),
      const AgeOutOfRange(age: 17, min: 18, max: 65),
      const LastDonationInFuture(),
      TooSoonToDonate(DateTime.utc(2026, 12, 1)),
      const ActiveAppointmentExists(),
      const SlotFull(),
      const SlotInPast(),
      const SlotNotInDrive(),
      CancellationTooLate(DateTime.utc(2026, 11, 9, 21)),
      const AppointmentStarted(),
      const CheckInOutsideWindow(),
      const AppointmentNotStarted(),
      const InvalidDeferralReason(length: 0, min: 3, max: 200),
      const NotFound(),
      const NotAllowed(),
    ];
    for (final error in errors) {
      final back = ProblemDto.fromJson(error.toProblem().toJson()).toDomainError();
      expect(back.runtimeType, error.runtimeType, reason: '$error');
    }
  });

  test('nepoznat kôd (novo pravilo na serveru) daje null, a ne pad', () {
    const problem = ProblemDto(status: 422, code: 'new-rule-from-the-future', title: 'New rule');
    expect(problem.toDomainError(), isNull);
  });

  test('termin prolazi kroz ugovor i nazad', () {
    final appointment = Appointment(
      id: const AppointmentId('a-1'),
      donorId: const DonorId('u-1'),
      driveId: const DriveId('d-1'),
      slotStart: DateTime.utc(2026, 11, 10, 8),
      status: Deferred(at: DateTime.utc(2026, 11, 10, 8, 20), reason: 'Nizak hemoglobin'),
    );
    final back = AppointmentDto.fromJson(appointment.toDto().toJson()).toDomain();
    expect(back, appointment);
  });
}
