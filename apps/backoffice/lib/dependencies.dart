import 'package:blocs/blocs.dart';

import 'data/fake_donation_repository.dart';

/// Zavisnosti backoffice-a, napravljene na jednom mestu.
/// Isti port i isti Bloc-ovi kao mobilna aplikacija; svoji lažni podaci.
final class BackofficeDependencies {
  BackofficeDependencies({required this.repository, required this.clock, this.fake});

  factory BackofficeDependencies.fake({
    Clock clock = systemClock,
    Duration latency = const Duration(milliseconds: 300),
  }) {
    final fake = FakeDonationRepository(clock: clock, latency: latency);
    return BackofficeDependencies(repository: fake, clock: clock, fake: fake);
  }

  final DonationRepository repository;
  final Clock clock;
  final FakeDonationRepository? fake;
}
