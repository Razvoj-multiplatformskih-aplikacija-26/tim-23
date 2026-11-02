import 'package:backoffice/app.dart';
import 'package:backoffice/dependencies.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('raspored se vodi tastaturom', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(BackofficeApp(dependencies: BackofficeDependencies.fake(latency: Duration.zero)));
    await tester.pumpAndSettle();
    expect(find.text('Raspored akcije'), findsOneWidget);
    expect(find.text('Izaberite termin'), findsOneWidget);

    // Strelica dole i Enter otvaraju drugi termin u bočnom panelu.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Izaberite termin'), findsNothing);

    // Esc zatvara detalj.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Izaberite termin'), findsOneWidget);
  });
}
