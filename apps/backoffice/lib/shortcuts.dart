import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Prečica ima dva koraka: Shortcuts pretvara taster u Intent (šta korisnik
/// hoće), a Actions za taj Intent nalazi kod koji ga izvršava.

/// Akcija osoblja nad izabranim terminom.
class StaffActionIntent extends Intent {
  const StaffActionIntent(this.action);

  final StaffAction action;
}

/// Zatvori detalj (Esc).
class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

/// Ponovo učitaj raspored (R).
class RefreshIntent extends Intent {
  const RefreshIntent();
}

/// Pregled prečica (?).
class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

Map<ShortcutActivator, Intent> scheduleShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.keyA): const StaffActionIntent(StaffAction.checkIn),
  const SingleActivator(LogicalKeyboardKey.keyK): const StaffActionIntent(StaffAction.donated),
  const SingleActivator(LogicalKeyboardKey.keyO): const StaffActionIntent(StaffAction.deferred),
  const SingleActivator(LogicalKeyboardKey.keyN): const StaffActionIntent(StaffAction.noShow),
  const SingleActivator(LogicalKeyboardKey.keyX): const StaffActionIntent(StaffAction.cancel),
  const SingleActivator(LogicalKeyboardKey.escape): const ClearSelectionIntent(),
  const SingleActivator(LogicalKeyboardKey.keyR): const RefreshIntent(),
  const CharacterActivator('?'): const ShowShortcutsIntent(),
};

/// Akcija koja radi samo kad [enabled] kaže da sme; inače taster ide dalje.
class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function(T intent) enabled;

  @override
  bool isEnabled(T intent) => enabled(intent);
}

const shortcutDescriptions = [
  ('↑ ↓', 'Kretanje kroz termine'),
  ('Enter', 'Otvori termin pod kursorom'),
  ('Esc', 'Zatvori detalj'),
  ('A', 'Davalac je pristupio'),
  ('K', 'Davalac je dao krv'),
  ('O', 'Odbijen na pregledu (uz razlog)'),
  ('N', 'Davalac nije došao'),
  ('X', 'Otkaži termin'),
  ('R', 'Osveži raspored'),
  ('?', 'Pregled prečica'),
];
