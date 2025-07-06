// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:instab/main.dart';

void main() {
  testWidgets('Social Media Detector smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SocialMediaDetectorApp());

    // Verify that our app starts with monitoring stopped.
    expect(find.text('Aucune app détectée'), findsOneWidget);
    expect(find.text('Démarrer le monitoring'), findsOneWidget);

    // Tap the start monitoring button and trigger a frame.
    await tester.tap(find.text('Démarrer le monitoring'));
    await tester.pump();

    // Verify that monitoring has started.
    expect(find.text('Arrêter le monitoring'), findsOneWidget);
    expect(find.text('Temps passé: 0s'), findsOneWidget);
  });
}
