import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';

Future<void> main() async {
  final config = ServerConfig.fromEnvironment(serverEnvironment());
  final database = Pool<void>.withUrl(config.databaseUrl);
  // Prazna baza dobija početne podatke (akcije, davaoce, termine u svim stanjima, demo naloge).
  await seedDemoData(
    database,
    now: DateTime.now().toUtc(),
    demoPassword: config.demoPassword,
    utcOffset: config.seedUtcOffset,
  );
  final handlers = KapHandlers(database: database, clock: () => DateTime.now().toUtc());
  final sessions = SessionHandlers(
    accounts: AccountStore(database),
    secret: config.jwtSecret,
    ttl: config.sessionTtl,
    secureCookie: config.secureCookie,
  );
  final server = RelicServer(() => IOAdapter.bind(InternetAddress(config.host), port: config.port));
  await server.mountAndStart(buildHandler(handlers, sessions, corsOrigins: config.corsOrigins));
  stdout.writeln('Kap server na http://${config.host}:${config.port}');
  await _stopSignal();
  await server.close();
  await database.close();
}

Future<void> _stopSignal() async {
  final stop = Completer<void>();
  final subscriptions = [
    for (final signal in [ProcessSignal.sigint, if (!Platform.isWindows) ProcessSignal.sigterm])
      signal.watch().listen((_) => stop.isCompleted ? null : stop.complete()),
  ];
  await stop.future;
  for (final subscription in subscriptions) {
    await subscription.cancel();
  }
}
