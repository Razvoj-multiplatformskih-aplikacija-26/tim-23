import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

/// Backoffice za osoblje. Bez prijave se vidi samo ekran za prijavu;
/// davalac koji se prijavi dobija poruku zašto ne može da uđe.
class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final BackofficeDependencies dependencies;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
  // Isti SessionBloc kao u mobilnoj aplikaciji; razlika je samo koju ulogu prima.
  late final SessionBloc _session = SessionBloc(
    sessions: widget.dependencies.sessions,
    admits: AccessPolicy.canUseBackoffice,
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
                title: 'Kap · Backoffice',
                sessions: deps.sessions,
                reason: reason,
                roleNotAllowedMessage: 'Backoffice je za medicinsko osoblje. Davaoci koriste mobilnu aplikaciju.',
                hint: 'Demo nalozi: sestra1, koordinator1 (lozinka je u .env, DEMO_PASSWORD).',
                onSignedIn: (user) => _session.add(SessionStarted(user)),
              ),
            ),
            SignedIn(:final user) => _SignedInApp(key: ValueKey(user.id), staff: user, dependencies: deps),
          },
        ),
      ),
    );
  }
}

/// Deo posle prijave: Bloc-ovi za prijavljenog člana osoblja i ruter.
class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.staff, required this.dependencies});

  final User staff;
  final BackofficeDependencies dependencies;

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
    return RepositoryProvider.value(
      value: widget.staff,
      child: MultiBlocProvider(
        providers: [
          // Osoblje vidi i prošle akcije, ne samo predstojeće.
          BlocProvider(
            create: (_) =>
                DrivesBloc(repository: deps.repository, clock: deps.clock, upcomingOnly: false)
                  ..add(const DrivesRequested()),
          ),
          // Raspored je iznad rutera: izbor i kursor ostaju dok se menja adresa i širina prozora.
          // Akcije zavise od uloge prijavljenog člana osoblja (AccessPolicy).
          BlocProvider(
            create: (_) => DriveScheduleBloc(repository: deps.repository, clock: deps.clock, staff: widget.staff),
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
      title: 'Kap · Backoffice',
      debugShowCheckedModeBanner: false,
      theme: KapTheme.light(),
      darkTheme: KapTheme.dark(),
      locale: BackofficeApp.locale,
      supportedLocales: const [BackofficeApp.locale],
      localizationsDelegates: delegates,
      routerConfig: router,
    );
  }
  return MaterialApp(
    key: key,
    title: 'Kap · Backoffice',
    debugShowCheckedModeBanner: false,
    theme: KapTheme.light(),
    darkTheme: KapTheme.dark(),
    locale: BackofficeApp.locale,
    supportedLocales: const [BackofficeApp.locale],
    localizationsDelegates: delegates,
    home: home,
  );
}
