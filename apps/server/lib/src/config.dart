import 'dart:convert';

/// Podešavanja servera iz okruženja (Docker Compose) ili iz .env (pokretanje bez Docker-a).
final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.corsOrigins,
    required this.jwtSecret,
    this.sessionTtl = const Duration(hours: 8),
    this.secureCookie = false,
    this.demoPassword,
    this.seedUtcOffset = const Duration(hours: 1),
  });

  factory ServerConfig.fromEnvironment(Map<String, String> environment) => ServerConfig(
    host: environment['HOST'] ?? '127.0.0.1',
    port: int.parse(environment['PORT'] ?? '8080'),
    databaseUrl:
        environment['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL is not set. Copy .env.example to .env in the repository root.')),
    corsOrigins: [
      for (final origin in (environment['CORS_ORIGINS'] ?? 'http://localhost:8081').split(','))
        if (origin.trim().isNotEmpty) origin.trim(),
    ],
    sessionTtl: Duration(minutes: int.parse(environment['SESSION_TTL_MINUTES'] ?? '480')),
    secureCookie: environment['COOKIE_SECURE'] == 'true',
    demoPassword: environment['DEMO_PASSWORD'],
    jwtSecret: _jwtSecret(environment['JWT_SECRET']),
    seedUtcOffset: Duration(hours: int.parse(environment['SEED_UTC_OFFSET_HOURS'] ?? '1')),
  );

  final String host;
  final int port;
  final String databaseUrl;

  /// Adrese sa kojih pregledač sme da zove server (backoffice na vebu).
  final List<String> corsOrigins;

  /// Posle ovoliko vremena prijava ističe i korisnik se vraća na ekran za prijavu.
  final Duration sessionTtl;

  final bool secureCookie;

  /// Lozinka svih demo naloga; upisuje se u bazu samo kao heš.
  final String? demoPassword;

  /// Ključ kojim server potpisuje prijave (JWT). Postoji samo na serveru.
  final String jwtSecret;

  /// Pomak lokalnog vremena za početne podatke (Srbija zimi UTC+1), da akcije
  /// budu u 9:00 po lokalnom vremenu iako server u kontejneru radi u UTC-u.
  final Duration seedUtcOffset;
}

String _jwtSecret(String? secret) => switch (secret) {
  null => throw StateError('JWT_SECRET is not set. Copy .env.example to .env in the repository root.'),
  final secret when utf8.encode(secret).length < 32 => throw StateError('JWT_SECRET must have at least 32 bytes.'),
  final secret => secret,
};
