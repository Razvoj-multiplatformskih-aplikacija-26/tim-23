import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  test('termin prolazi kroz JSON i nazad bez gubitka', () {
    final dto = AppointmentDto(
      id: 'a-1',
      donorId: 'u-1',
      driveId: 'd-1',
      slotStart: DateTime.utc(2026, 11, 10, 8, 30),
      slotMinutes: 30,
      status: AppointmentStatusDto(kind: AppointmentStatusDto.cancelled, at: DateTime.utc(2026, 11, 9), reason: 'x'),
    );
    final back = AppointmentDto.fromJson(dto.toJson());
    expect(back.slotStart, dto.slotStart);
    expect(back.status.kind, AppointmentStatusDto.cancelled);
    expect(back.status.reason, 'x');
  });

  test('vreme bez vremenske zone se ne prihvata', () {
    expect(
      () => AppointmentStatusDto.fromJson({'kind': 'confirmed', 'at': '2026-11-10T08:00:00'}),
      throwsFormatException,
    );
  });

  test('kalendarski dan putuje bez vremena', () {
    expect(dayToJson(DateTime(2003, 4, 12)), '2003-04-12');
    expect(dayFromJson('2003-04-12'), DateTime(2003, 4, 12));
  });

  test('greška nosi kôd i podatke pravila', () {
    const problem = ProblemDto(status: 422, code: ErrorCodes.ageOutOfRange, title: 'Age', value: 17, min: 18, max: 65);
    final back = ProblemDto.fromJson(problem.toJson());
    expect([back.code, back.value, back.min, back.max], [ErrorCodes.ageOutOfRange, 17, 18, 65]);
  });
}
