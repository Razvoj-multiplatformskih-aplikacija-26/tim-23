import 'package:domain/domain.dart';

/// Port za prijavu. Implementiraju ga lažne sesije (demo i testovi)
/// i HttpSessionRepository iz paketa api_client (server).
abstract interface class SessionRepository {
  /// Vraća korisnika, ili null kada su korisničko ime ili lozinka pogrešni.
  Future<User?> logIn({required String username, required String password});

  /// Prijava sačuvana od ranije (posle ponovnog pokretanja), ili null.
  Future<User?> current();

  Future<void> logOut();

  /// Javlja kada server kaže da je prijava istekla.
  Stream<void> get expirations;
}
