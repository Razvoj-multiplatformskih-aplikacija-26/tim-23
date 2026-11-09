import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'kap_logo.dart';
import 'texts.dart';

/// Ekran za prijavu, isti u mobilnoj aplikaciji i u backoffice-u.
/// [reason] je razlog zašto je korisnik odjavljen (istekla prijava, pogrešna aplikacija...).
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.title,
    required this.sessions,
    required this.onSignedIn,
    required this.roleNotAllowedMessage,
    this.reason,
    this.hint,
  });

  final String title;
  final SessionRepository sessions;
  final void Function(User user) onSignedIn;

  /// Poruka kada se prijavi nalog uloge koju ova aplikacija ne prima.
  final String roleNotAllowedMessage;

  final SignOutReason? reason;

  /// Kratka napomena ispod forme (npr. demo nalozi).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginFormBloc(sessions: sessions),
      child: BlocListener<LoginFormBloc, LoginFormState>(
        listener: (context, state) {
          if (state case LoginSucceeded(:final user)) onSignedIn(user);
        },
        child: Scaffold(
          body: SafeArea(
            child: _LoginForm(title: title, reason: reason, roleNotAllowedMessage: roleNotAllowedMessage, hint: hint),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.title, required this.roleNotAllowedMessage, this.reason, this.hint});

  final String title;
  final String roleNotAllowedMessage;
  final SignOutReason? reason;
  final String? hint;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<LoginFormBloc>().add(LoginSubmitted(username: _username.text, password: _password.text));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<LoginFormBloc>().state;
    final busy = state is LoginSubmitting;
    final message = switch (state) {
      LoginRejected() => 'Pogrešno korisničko ime ili lozinka.',
      LoginFailed(:final cause) => failureMessageFor(cause),
      _ => switch (widget.reason) {
        SignOutReason.roleNotAllowed => widget.roleNotAllowedMessage,
        SignOutReason.expired => sessionExpiredMessage,
        SignOutReason.unreachable => serverUnreachableMessage,
        SignOutReason.loggedOut || null => null,
      },
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: KapLogo(size: 48)),
                const SizedBox(height: 16),
                Text(widget.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (message != null) ...[
                  Text(message, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _username,
                  enabled: !busy,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Korisničko ime'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Prijavi se'),
                ),
                if (widget.hint case final hint?) ...[
                  const SizedBox(height: 16),
                  Text(hint, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
