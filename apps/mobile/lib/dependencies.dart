import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'data/fake_donation_repository.dart';
import 'data/seed.dart';

/// Sve zavisnosti aplikacije, napravljene na jednom mestu pri pokretanju.
///
/// Ekrani i Bloc-ovi ne znaju koja je implementacija porta izabrana.
/// Od KT2 dodaje se AppDependencies.server(...) sa HTTP adapterom, a ekrani
/// ostaju isti.
final class AppDependencies {
  AppDependencies({required this.repository, required this.clock, required this.donorId, this.fake});

  factory AppDependencies.fake({Clock clock = systemClock, Duration latency = const Duration(milliseconds: 300)}) {
    final fake = FakeDonationRepository(clock: clock, latency: latency);
    return AppDependencies(repository: fake, clock: clock, donorId: Seed.currentDonor, fake: fake);
  }

  final DonationRepository repository;
  final Clock clock;

  /// Prijavljeni davalac; do KT2 uvek isti.
  final DonorId donorId;

  /// Lažni repozitorijum, ako je izabran; služi za demo meni (greška, prazno).
  final FakeDonationRepository? fake;
}
