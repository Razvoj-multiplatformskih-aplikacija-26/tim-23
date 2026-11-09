import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../ports/repository_exception.dart';
import '../ports/session_repository.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Ko je prijavljen u aplikaciji. Isti Bloc koriste mobilna aplikacija i backoffice;
/// razlikuje ih samo [admits]: koju ulogu aplikacija prima (AccessPolicy iz domena).
final class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({required this.sessions, required this.admits}) : super(const SessionUnknown()) {
    on<SessionRestoreRequested>(_onRestoreRequested);
    on<SessionStarted>(_onStarted);
    on<SessionLogOutRequested>(_onLogOutRequested);
    on<SessionExpired>((event, emit) {
      if (state is SignedIn) emit(const SignedOut(reason: SignOutReason.expired));
    });
    _expirations = sessions.expirations.listen((_) => add(const SessionExpired()));
  }

  final SessionRepository sessions;
  final bool Function(User user) admits;
  late final StreamSubscription<void> _expirations;

  /// Pri pokretanju: prijava sačuvana od ranije (bezbedno skladište ili kolačić).
  Future<void> _onRestoreRequested(SessionRestoreRequested event, Emitter<SessionState> emit) async {
    try {
      final user = await sessions.current();
      if (user == null) return emit(const SignedOut());
      add(SessionStarted(user));
    } on RepositoryException {
      emit(const SignedOut(reason: SignOutReason.unreachable));
    }
  }

  /// Nalog pogrešne uloge (npr. davalac u backoffice-u) se odjavljuje uz razlog.
  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) async {
    if (admits(event.user)) {
      emit(SignedIn(event.user));
      return;
    }
    await _logOutQuietly();
    emit(const SignedOut(reason: SignOutReason.roleNotAllowed));
  }

  Future<void> _onLogOutRequested(SessionLogOutRequested event, Emitter<SessionState> emit) async {
    await _logOutQuietly();
    emit(const SignedOut(reason: SignOutReason.loggedOut));
  }

  Future<void> _logOutQuietly() async {
    try {
      await sessions.logOut();
    } on RepositoryException catch (cause, stackTrace) {
      addError(cause, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    await _expirations.cancel();
    return super.close();
  }
}
