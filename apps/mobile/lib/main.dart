import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  // U debug izdanju svaki događaj i novo stanje Bloc-a ispisuju se u konzolu.
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(KapApp(dependencies: AppDependencies.fake()));
}
