import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  // U pregledaču adrese bez # (localhost:xxxx/akcije/d-danas); na desktopu ne radi ništa.
  usePathUrlStrategy();
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(BackofficeApp(dependencies: BackofficeDependencies.fake()));
}
