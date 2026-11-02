import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class KapApp extends StatefulWidget {
  const KapApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final AppDependencies dependencies;

  @override
  State<KapApp> createState() => _KapAppState();
}

class _KapAppState extends State<KapApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    // RepositoryProvider daje zavisnosti celom stablu, a MultiBlocProvider
    // pravi globalne Bloc-ove koje vide svi ekrani (tabovi i detalji).
    return RepositoryProvider.value(
      value: deps,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => DrivesBloc(repository: deps.repository, clock: deps.clock)..add(const DrivesRequested()),
          ),
          BlocProvider(
            create: (_) =>
                MyAppointmentsBloc(repository: deps.repository, clock: deps.clock, donorId: deps.donorId)
                  ..add(const MyAppointmentsRequested()),
          ),
          BlocProvider(
            create: (_) =>
                ProfileBloc(repository: deps.repository, clock: deps.clock, donorId: deps.donorId)
                  ..add(const ProfileRequested()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Kap',
          debugShowCheckedModeBanner: false,
          theme: KapTheme.light(),
          darkTheme: KapTheme.dark(),
          locale: KapApp.locale,
          supportedLocales: const [KapApp.locale],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
