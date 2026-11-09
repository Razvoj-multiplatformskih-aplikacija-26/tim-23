import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../ports/session_repository.dart';

part 'login_form_event.dart';
part 'login_form_state.dart';

/// Forma za prijavu. Lozinka se ne čuva nigde; ide samo serveru.
final class LoginFormBloc extends Bloc<LoginFormEvent, LoginFormState> {
  LoginFormBloc({required this.sessions}) : super(const LoginIdle()) {
    on<LoginSubmitted>((event, emit) async {
      emit(const LoginSubmitting());
      try {
        final user = await sessions.logIn(username: event.username.trim(), password: event.password);
        emit(user == null ? const LoginRejected() : LoginSucceeded(user));
      } on Exception catch (cause) {
        emit(LoginFailed(cause));
      }
    });
  }

  final SessionRepository sessions;
}
