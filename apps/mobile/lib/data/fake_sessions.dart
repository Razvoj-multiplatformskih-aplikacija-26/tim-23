import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

/// Lažne sesije za demo i testove: jedan korisnik, bilo koja lozinka.
final class FakeSessions implements SessionRepository {
  FakeSessions(this.user, {this.signedIn = true});

  final User user;
  bool signedIn;

  @override
  Future<User?> logIn({required String username, required String password}) async {
    signedIn = true;
    return user;
  }

  @override
  Future<User?> current() async => signedIn ? user : null;

  @override
  Future<void> logOut() async => signedIn = false;

  @override
  Stream<void> get expirations => const Stream.empty();
}