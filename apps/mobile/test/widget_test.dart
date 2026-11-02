import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';

void main() {
  testWidgets('prikazuje akcije, pa grešku i „Pokušaj ponovo“', (tester) async {
    final deps = AppDependencies.fake(latency: Duration.zero);
    await tester.pumpWidget(KapApp(dependencies: deps));
    await tester.pumpAndSettle();
    expect(find.text('Predstojeće akcije'), findsOneWidget);

    deps.fake!.failingRequests = 1;
    await tester.tap(find.byTooltip('Osveži').first);
    await tester.pumpAndSettle();
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Predstojeće akcije'), findsOneWidget);
  });

  testWidgets('moji termini prikazuju aktivni termin i istoriju', (tester) async {
    await tester.pumpWidget(KapApp(dependencies: AppDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Aktivni'), findsOneWidget);
    expect(find.text('Potvrđen'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });
}
