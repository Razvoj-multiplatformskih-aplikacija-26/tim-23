import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'data/fake_donation_repository.dart';
import 'data/fake_sessions.dart';

/// Sve zavisnosti aplikacije, napravljene na jednom mestu pri pokretanju.
///
/// Ekrani i Bloc-ovi zavise samo od portova (DonationRepository, SessionRepository),
/// pa ne znaju da li podaci stižu sa servera ili iz lažne implementacije.
final class AppDependencies {
  AppDependencies({required this.repository, required this.sessions, required this.clock, this.fake});

  /// Pravi rad: server preko paketa api_client (isti kôd kao u backoffice-u).
  factory AppDependencies.server({required Uri baseUri, required TokenStore tokens, Clock clock = systemClock}) {
    final api = ApiClient(baseUri: baseUri, tokens: tokens);
    return AppDependencies(repository: HttpDonationRepository(api), sessions: HttpSessionRepository(api), clock: clock);
  }

  /// Lažni podaci u memoriji: testovi ekrana i demo bez servera.
  factory AppDependencies.fake({
    Clock clock = systemClock,
    Duration latency = const Duration(milliseconds: 300),
    bool signedIn = true,
  }) {
    final fake = FakeDonationRepository(clock: clock, latency: latency);
    return AppDependencies(
      repository: fake,
      sessions: FakeSessions(demoDonor, signedIn: signedIn),
      clock: clock,
      fake: fake,
    );
  }

  /// Davalac iz lažnih podataka (isti kao nalog davalac1 na serveru).
  static const demoDonor = User(id: UserId('u-1'), name: 'Petar Jovanović', role: Role.donor);

  final DonationRepository repository;
  final SessionRepository sessions;
  final Clock clock;

  /// Lažni repozitorijum, ako je izabran; služi za demo meni (greška, prazno).
  final FakeDonationRepository? fake;
}
