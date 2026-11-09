import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';

void main() {
  // U pregledaču adrese bez # (localhost:8081/akcije/d-danas); na desktopu ne radi ništa.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(
    BackofficeApp(
      dependencies: BackofficeDependencies.server(
        // Druga adresa servera: flutter run --dart-define=SERVER_URL=http://localhost:9090
        baseUri: Uri.parse(const String.fromEnvironment('SERVER_URL', defaultValue: 'http://localhost:8080')),
        // U pregledaču prijavu čuva pregledač u HttpOnly kolačiću; token se ne čuva u JavaScript-u.
        tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore(),
      ),
    ),
  );
}
