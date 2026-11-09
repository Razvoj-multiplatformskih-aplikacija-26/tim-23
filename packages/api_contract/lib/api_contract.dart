/// Ugovor između klijenata i servera: putanje, kodovi grešaka i oblik JSON-a.
///
/// Čist Dart bez zavisnosti: ne uvozi domen, Flutter ni dart:io, pa ga
/// koriste i server, i aplikacije na telefonu, desktopu i u pregledaču.
library;

export 'src/donation_dto.dart';
export 'src/error_codes.dart';
export 'src/json.dart';
export 'src/paths.dart';
export 'src/problem_dto.dart';
export 'src/session_dto.dart';
