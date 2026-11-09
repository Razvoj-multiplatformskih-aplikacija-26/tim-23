import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

ApiClient clientAnswering(int status, Object? body) => ApiClient(
  baseUri: Uri.parse('http://localhost:8080'),
  keepsSessionInCookie: false,
  httpClient: MockClient((request) async => http.Response(jsonEncode(body), status)),
);

final appointment = Appointment(
  id: const AppointmentId('a-1'),
  donorId: const DonorId('u-1'),
  driveId: const DriveId('d-1'),
  slotStart: DateTime.utc(2026, 11, 10, 8),
  status: Cancelled(at: DateTime.utc(2026, 11, 9), byStaff: false),
);

void main() {
  test('odbijanje pravilom postaje ista greška domena kao na klijentu', () async {
    final repository = HttpDonationRepository(
      clientAnswering(422, {'status': 422, 'code': ErrorCodes.cancellationTooLate, 'at': '2026-11-09T21:00:00Z'}),
    );
    final result = await repository.saveAppointment(appointment);
    expect(result.errorOrNull, isA<CancellationTooLate>());
  });

  test('nepoznat kôd sa novijeg servera ne obara aplikaciju', () async {
    final repository = HttpDonationRepository(clientAnswering(422, {'status': 422, 'code': 'some-new-rule'}));
    expect(
      () => repository.saveAppointment(appointment),
      throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.refused)),
    );
  });

  test('istekla prijava se javlja i postaje greška sessionExpired', () async {
    final api = clientAnswering(401, {'status': 401, 'code': ErrorCodes.sessionExpired});
    final expired = expectLater(api.expirations, emits(null));
    await expectLater(
      HttpDonationRepository(api).drives(),
      throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.sessionExpired)),
    );
    await expired;
  });

  test('server koji ne radi daje grešku unreachable, ne beskrajno učitavanje', () async {
    final api = ApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      keepsSessionInCookie: false,
      httpClient: MockClient((request) async => throw http.ClientException('Connection refused')),
    );
    expect(
      HttpDonationRepository(api).drives(),
      throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unreachable)),
    );
  });
}
