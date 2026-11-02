import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final BackofficeDependencies dependencies;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
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
      value: deps,
      child: MultiBlocProvider(
        providers: [
          // Osoblje vidi i prošle akcije, ne samo predstojeće.
          BlocProvider(
            create: (_) =>
                DrivesBloc(repository: deps.repository, clock: deps.clock, upcomingOnly: false)
                  ..add(const DrivesRequested()),
          ),
          // Raspored je iznad rutera: izbor i kursor ostaju dok se menja adresa i širina prozora.
          BlocProvider(create: (_) => DriveScheduleBloc(repository: deps.repository, clock: deps.clock)),
        ],
        child: MaterialApp.router(
          title: 'Kap · Backoffice',
          debugShowCheckedModeBanner: false,
          theme: KapTheme.light(),
          darkTheme: KapTheme.dark(),
          locale: BackofficeApp.locale,
          supportedLocales: const [BackofficeApp.locale],
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
