import 'package:demo_data/demo_data.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'kap_store.dart';
import 'passwords.dart';

/// Upisuje početne podatke u praznu bazu: akcije, davaoce, termine u svakom stanju
/// i demo naloge (davalac1, davalac2, sestra1, koordinator1). Isti podaci kao u
/// lažnim repozitorijumima aplikacija (paket demo_data). Lozinka ide u bazu samo kao heš.
Future<void> seedDemoData(
  Pool<void> database, {
  required DateTime now,
  required String? demoPassword,
  Duration utcOffset = const Duration(hours: 1),
}) async {
  if (!await KapStore(database).isEmpty()) return;
  if (demoPassword == null) throw StateError('DEMO_PASSWORD is not set. Copy .env.example to .env.');
  final seed = Seed(now, utcOffset: utcOffset);
  final hash = await hashPassword(demoPassword);
  await database.runTx((session) async {
    final store = KapStore(session);
    for (final donor in seed.donors) {
      final login = Seed.logins[donor.id.value];
      await store.insertUser(
        User(id: UserId(donor.id.value), name: donor.name.value, role: Role.donor),
        login: login,
        passwordHash: login == null ? null : hash,
      );
      await store.insertDonor(donor);
    }
    for (final member in Seed.staff) {
      await store.insertUser(member, login: Seed.logins[member.id.value], passwordHash: hash);
    }
    for (final drive in seed.drives) {
      await store.insertDrive(drive);
    }
    for (final appointment in seed.appointments) {
      await store.insertAppointment(appointment);
    }
  });
}
