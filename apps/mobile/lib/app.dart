import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

/// Aplikacija za davaoce. Bez prijave se vidi samo ekran za prijavu;
/// posle prijave Bloc-ovi se prave za tog davaoca.
class KapApp extends StatefulWidget {
  const KapApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final AppDependencies dependencies;

  @override
  State<KapApp> createState() => _KapAppState();
}

class _KapAppState extends State<KapApp> {
  // Mobilna aplikacija prima samo davaoce (pravo iz domena, isto kao na serveru).
  late final SessionBloc _session = SessionBloc(
    sessions: widget.dependencies.sessions,
    admits: AccessPolicy.canUseMobileApp,
  )..add(const SessionRestoreRequested());

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    return RepositoryProvider.value(
      value: deps,
      child: BlocProvider.value(
        value: _session,
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, session) => switch (session) {
            SessionUnknown() => _material(
              key: const ValueKey('session-unknown'),
              home: const Scaffold(body: LoadingView()),
            ),
            SignedOut(:final reason) => _material(
              key: ValueKey('signed-out ${reason?.name}'),
              home: LoginScreen(
                title: 'Prijava davaoca',
                sessions: deps.sessions,
                reason: reason,
                roleNotAllowedMessage: 'Aplikacija je za davaoce krvi. Osoblje koristi backoffice.',
                hint: 'Demo nalozi: davalac1, davalac2 (lozinka je u .env, DEMO_PASSWORD).',
                onSignedIn: (user) => _session.add(SessionStarted(user)),
              ),
            ),
            SignedIn(:final user) => _SignedInApp(key: ValueKey(user.id), donor: user, dependencies: deps),
          },
        ),
      ),
    );
  }
}

/// Deo aplikacije posle prijave: Bloc-ovi za prijavljenog davaoca i ruter.
class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.donor, required this.dependencies});

  final User donor;
  final AppDependencies dependencies;

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    final donorId = widget.donor.donorId;
    return RepositoryProvider.value(
      value: widget.donor,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => DrivesBloc(repository: deps.repository, clock: deps.clock)..add(const DrivesRequested()),
          ),
          BlocProvider(
            create: (_) =>
                MyAppointmentsBloc(repository: deps.repository, clock: deps.clock, donorId: donorId)
                  ..add(const MyAppointmentsRequested()),
          ),
          BlocProvider(
            create: (_) =>
                ProfileBloc(repository: deps.repository, clock: deps.clock, donorId: donorId)
                  ..add(const ProfileRequested()),
          ),
        ],
        child: _material(router: _router),
      ),
    );
  }
}

Widget _material({Key? key, Widget? home, GoRouter? router}) {
  const delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (router != null) {
    return MaterialApp.router(
      key: key,
      title: 'Kap',
      debugShowCheckedModeBanner: false,
      theme: KapTheme.light(),
      darkTheme: KapTheme.dark(),
      locale: KapApp.locale,
      supportedLocales: const [KapApp.locale],
      localizationsDelegates: delegates,
      routerConfig: router,
    );
  }
  return MaterialApp(
    key: key,
    title: 'Kap',
    debugShowCheckedModeBanner: false,
    theme: KapTheme.light(),
    darkTheme: KapTheme.dark(),
    locale: KapApp.locale,
    supportedLocales: const [KapApp.locale],
    localizationsDelegates: delegates,
    home: home,
  );
}
