@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:server/src/passwords.dart';
import 'package:test/test.dart';

// Testovi rade nad posebnom bazom kap_test; baza iz Docker Compose-a mora da radi:
//   docker compose up -d
//   cd apps/server && dart test

late Pool<void> database;
late RelicServer server;
late Uri base;
late String demoPassword;

Future<String> logIn(String login) async {
  final answer = await http.post(
    base.replace(path: ApiPaths.sessions),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(LoginDto(username: login, password: demoPassword).toJson()),
  );
  return SessionDto.fromJson(jsonDecode(answer.body) as Map<String, Object?>).token!;
}

Map<String, String> as(String token) => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

Future<http.Response> book(String token, String driveId, DateTime slotStart) => http.post(
  base.replace(path: ApiPaths.appointments),
  headers: as(token),
  body: jsonEncode(NewAppointmentDto(driveId: driveId, slotStart: slotStart).toJson()),
);

String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

Future<void> migrateWithDbmate(Uri databaseUrl) async {
  final insideCompose = databaseUrl.replace(host: 'db', port: 5432, path: '/kap_test');
  final result = await Process.run('docker', [
    'compose',
    'run',
    '--rm',
    '-e',
    'DATABASE_URL=$insideCompose',
    'migrate',
  ], workingDirectory: '../..');
  if (result.exitCode != 0) throw StateError('dbmate failed: ${result.stderr}');
}

void main() {
  setUpAll(() async {
    final config = ServerConfig.fromEnvironment(serverEnvironment());
    demoPassword = config.demoPassword!;
    final admin = Pool<void>.withUrl(config.databaseUrl);
    await admin.execute('DROP DATABASE IF EXISTS kap_test WITH (FORCE)');
    await admin.execute('CREATE DATABASE kap_test');
    await admin.close();
    database = Pool<void>.withUrl(Uri.parse(config.databaseUrl).replace(path: '/kap_test').toString());
    await migrateWithDbmate(Uri.parse(config.databaseUrl));
    await seedDemoData(database, now: DateTime.now().toUtc(), demoPassword: demoPassword);
    final hash = await hashPassword(demoPassword);
    final store = KapStore(database);
    for (var n = 1; n <= 3; n++) {
      await store.insertUser(
        User(id: UserId('u-test-$n'), name: 'Test Davalac $n', role: Role.donor),
        login: 'test$n',
        passwordHash: hash,
      );
      await store.insertDonor(
        Donor(
          id: DonorId('u-test-$n'),
          name: DonorName.parse('Test Davalac $n').valueOrNull!,
          birthDate: DateTime(1995, 1, 1),
          sex: Sex.female,
          bloodGroup: BloodGroup.aPositive,
          city: 'Beograd',
        ),
      );
    }
    final handlers = KapHandlers(database: database, clock: () => DateTime.now().toUtc());
    final sessions = SessionHandlers(accounts: AccountStore(database), secret: config.jwtSecret, ttl: const Duration(hours: 1));
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(buildHandler(handlers, sessions, corsOrigins: const []));
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  test('tri davaoca u istom trenutku za slot sa dva mesta: prolaze tačno dva', () async {
    // Akcija u Kragujevcu ima 2 mesta po slotu i prvi slot je prazan.
    final drive = await KapStore(database).drive(const DriveId('d-kragujevac'));
    final slot = drive!.slots.first;
    final tokens = [for (var n = 1; n <= 3; n++) await logIn('test$n')];

    final answers = await Future.wait([for (final token in tokens) book(token, 'd-kragujevac', slot)]);

    expect(answers.map((answer) => answer.statusCode), unorderedEquals([201, 201, 409]));
    expect(codeOf(answers.firstWhere((answer) => answer.statusCode == 409)), ErrorCodes.slotFull);
  });

  test('poziv mimo aplikacije koji krši pravilo server odbija istim kodom', () async {
    // davalac1 već ima aktivan termin (Potvrđen u Domu omladine).
    final drive = await KapStore(database).drive(const DriveId('d-zavod'));
    final answer = await book(await logIn('davalac1'), 'd-zavod', drive!.slots.first);

    expect(answer.statusCode, 409);
    expect(codeOf(answer), ErrorCodes.activeAppointmentExists);
  });

  test('davalac ne sme akciju backoffice-a, a tuđ termin ne vidi', () async {
    final mine = await KapStore(database).appointmentsOfDonor(const DonorId('u-2'));
    final someoneElses = mine.first.id.value;
    final donor = await logIn('davalac1');

    final donation = await http.post(base.replace(path: ApiPaths.donation(someoneElses)), headers: as(donor));
    final cancel = await http.post(
      base.replace(path: ApiPaths.cancellation(someoneElses)),
      headers: as(donor),
      body: jsonEncode(const ReasonDto().toJson()),
    );

    expect([donation.statusCode, cancel.statusCode], [404, 404]);
  });

  test('davalac ne može u backoffice: raspored svih davalaca mu je zabranjen', () async {
    final answer = await http.get(base.replace(path: ApiPaths.donors), headers: as(await logIn('davalac1')));
    expect(answer.statusCode, 403);
    expect(codeOf(answer), ErrorCodes.notAllowed);
  });

  test('bez prijave server odbija i kaže zašto', () async {
    final answer = await http.get(base.replace(path: ApiPaths.drives));
    expect(answer.statusCode, 401);
    expect(codeOf(answer), ErrorCodes.signInRequired);
  });
}
