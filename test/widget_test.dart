import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_manager/src/ui/app.dart';

void main() {
  group('InvestmentManagerApp', () {
    testWidgets('renders MaterialApp with correct title', (tester) async {
      await tester.pumpWidget(const InvestmentManagerApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows Investment Manager title', (tester) async {
      await tester.pumpWidget(const InvestmentManagerApp());
      expect(find.text('Investment Manager'), findsOneWidget);
    });

    testWidgets('shows Add Stock FAB', (tester) async {
      await tester.pumpWidget(const InvestmentManagerApp());
      expect(find.text('Add Stock'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no holdings', (tester) async {
      await tester.pumpWidget(const InvestmentManagerApp());
      expect(find.text('Add your first stock to get started'), findsOneWidget);
    });

    testWidgets('does not show analysis button when empty', (tester) async {
      await tester.pumpWidget(const InvestmentManagerApp());
      expect(find.byIcon(Icons.insights), findsNothing);
    });
  });
}
