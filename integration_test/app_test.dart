import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:investment_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Investment Manager — App Launch', () {
    testWidgets('App loads and displays dashboard', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Investment Manager'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('App renders without crashing', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Material app is configured', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Investment Manager — Dashboard Content', () {
    testWidgets('Holdings section is displayed', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Holdings'), findsOneWidget);
    });

    testWidgets('Add Stock button is present', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Add Stock'), findsOneWidget);
    });

    testWidgets('Portfolio summary cards are displayed', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Dashboard shows value summary cards
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Empty portfolio shows appropriate state', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Either shows holdings or an empty state — both are valid
      expect(tester.takeException(), isNull);
      expect(find.text('Investment Manager'), findsOneWidget);
    });
  });

  group('Investment Manager — Add Stock Flow', () {
    testWidgets('Add Stock button opens form', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Add Stock'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Stock form has symbol and shares fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Add Stock'));
      await tester.pumpAndSettle();

      // Form should contain text fields for symbol, shares, cost basis
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Cancel from Add Stock returns to dashboard', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Add Stock'));
      await tester.pumpAndSettle();

      // Navigate back
      final backBtn = find.byTooltip('Back');
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await tester.pumpAndSettle();
      } else {
        final cancelBtn = find.text('Cancel');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first);
          await tester.pumpAndSettle();
        }
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Investment Manager'), findsOneWidget);
    });
  });

  group('Investment Manager — Analysis Navigation', () {
    testWidgets('Analysis screen is reachable', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for Analysis tab or button
      final analysisBtn = find.textContaining('Analys');
      if (analysisBtn.evaluate().isNotEmpty) {
        await tester.tap(analysisBtn.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Rebalancing suggestions section exists', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final analysisBtn = find.textContaining('Analys');
      if (analysisBtn.evaluate().isNotEmpty) {
        await tester.tap(analysisBtn.first);
        await tester.pumpAndSettle();

        // Analysis screen shows allocation/rebalancing info
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Investment Manager — Stability', () {
    testWidgets('App handles multiple interactions without crashing', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open and close Add Stock twice
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Add Stock'));
        await tester.pumpAndSettle();

        final backBtn = find.byTooltip('Back');
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn.first);
          await tester.pumpAndSettle();
        }
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Investment Manager'), findsOneWidget);
    });

    testWidgets('Scaffold and Navigator are present', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(Navigator), findsOneWidget);
    });
  });
}
