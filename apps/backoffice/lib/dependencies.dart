import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'data/fake_donation_repository.dart';
import 'data/fake_sessions.dart';

/// Zavisnosti backoffice-a, napravljene na jednom mestu.
/// Isti portovi, isti Bloc-ovi i isti HTTP kôd (api_client) kao u mobilnoj aplikaciji.
final class BackofficeDependencies {
  BackofficeDependencies({required this.repository, required this.sessions, required this.clock, this.fake});

  /// Pravi rad: server. Na desktopu prijava ide u Credential Manager, u pregledaču u HttpOnly kolačić.
  factory BackofficeDependencies.server({
    required Uri baseUri,
    required TokenStore tokens,
    Clock clock = systemClock,
  }) {
    final api = ApiClient(baseUri: baseUri, tokens: tokens);
    return BackofficeDependencies(
      repository: HttpDonationRepository(api),
      sessions: HttpSessionRepository(api),
      clock: clock,
    );
  }

  /// Lažni podaci u memoriji: testovi ekrana i demo bez servera.
  factory BackofficeDependencies.fake({
    Clock clock = systemClock,
    Duration latency = const Duration(milliseconds: 300),
    User staff = demoCoordinator,
  }) {
    final fake = FakeDonationRepository(clock: clock, latency: latency);
    return BackofficeDependencies(repository: fake, sessions: FakeSessions(staff), clock: clock, fake: fake);
  }

  static const demoCoordinator = User(id: UserId('u-koordinator'), name: 'Dragan Simić', role: Role.coordinator);

  final DonationRepository repository;
  final SessionRepository sessions;
  final Clock clock;
  final FakeDonationRepository? fake;
}
