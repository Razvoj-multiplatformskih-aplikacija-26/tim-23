// Na VM-u (telefon, desktop) dart:io klijent, u pregledaču BrowserClient sa kolačićima.
export 'platform_client_io.dart' if (dart.library.js_interop) 'platform_client_web.dart';
