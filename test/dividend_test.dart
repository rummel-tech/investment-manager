import 'package:test/test.dart';
import 'package:investment_manager/src/dividend.dart';

void main() {
  group('Dividend', () {
    test('constructor uppercases symbol', () {
      final d = Dividend(
        id: 'd1', accountId: 'a1', symbol: 'aapl',
        amount: 8.80, sharesHeld: 10,
        payDate: DateTime(2026, 3, 15), exDate: DateTime(2026, 3, 1),
      );
      expect(d.symbol, 'AAPL');
    });

    test('perShareAmount calculation', () {
      final d = Dividend(
        id: 'd1', accountId: 'a1', symbol: 'AAPL',
        amount: 10.0, sharesHeld: 4,
        payDate: DateTime(2026, 6, 15), exDate: DateTime(2026, 6, 1),
      );
      expect(d.perShareAmount, 2.5);
    });

    test('perShareAmount is 0 when no shares held', () {
      final d = Dividend(
        id: 'd1', accountId: 'a1', symbol: 'AAPL',
        amount: 10.0, sharesHeld: 0,
        payDate: DateTime(2026, 6, 15), exDate: DateTime(2026, 6, 1),
      );
      expect(d.perShareAmount, 0);
    });

    test('year and quarter from payDate', () {
      expect(
        Dividend(
          id: 'd1', accountId: 'a', symbol: 'X',
          amount: 1, sharesHeld: 1,
          payDate: DateTime(2026, 1, 15), exDate: DateTime(2026, 1, 1),
        ).quarter,
        1,
      );
      expect(
        Dividend(
          id: 'd2', accountId: 'a', symbol: 'X',
          amount: 1, sharesHeld: 1,
          payDate: DateTime(2026, 4, 15), exDate: DateTime(2026, 4, 1),
        ).quarter,
        2,
      );
      expect(
        Dividend(
          id: 'd3', accountId: 'a', symbol: 'X',
          amount: 1, sharesHeld: 1,
          payDate: DateTime(2026, 7, 15), exDate: DateTime(2026, 7, 1),
        ).quarter,
        3,
      );
      expect(
        Dividend(
          id: 'd4', accountId: 'a', symbol: 'X',
          amount: 1, sharesHeld: 1,
          payDate: DateTime(2026, 12, 15), exDate: DateTime(2026, 12, 1),
        ).quarter,
        4,
      );
    });

    test('default reinvested is false', () {
      final d = Dividend(
        id: 'd1', accountId: 'a', symbol: 'X',
        amount: 1, sharesHeld: 1,
        payDate: DateTime(2026, 1, 1), exDate: DateTime(2026, 1, 1),
      );
      expect(d.reinvested, isFalse);
      expect(d.reinvestTransactionId, isNull);
    });

    test('JSON round-trip', () {
      final d = Dividend(
        id: 'd1', accountId: 'a1', symbol: 'MSFT',
        amount: 12.50, sharesHeld: 20,
        payDate: DateTime(2026, 6, 15), exDate: DateTime(2026, 6, 1),
        reinvested: true, reinvestTransactionId: 'tx99',
      );
      final json = d.toJson();
      final restored = Dividend.fromJson(json);
      expect(restored.id, 'd1');
      expect(restored.symbol, 'MSFT');
      expect(restored.amount, 12.50);
      expect(restored.reinvested, isTrue);
      expect(restored.reinvestTransactionId, 'tx99');
    });
  });

  group('DividendTracker', () {
    late DividendTracker tracker;

    Dividend _makeDividend({
      required String id,
      String symbol = 'AAPL',
      double amount = 10.0,
      bool reinvested = false,
      DateTime? payDate,
    }) {
      return Dividend(
        id: id, accountId: 'a1', symbol: symbol,
        amount: amount, sharesHeld: 10,
        payDate: payDate ?? DateTime(2026, 3, 15),
        exDate: DateTime(2026, 3, 1),
        reinvested: reinvested,
      );
    }

    setUp(() {
      tracker = DividendTracker();
    });

    test('starts empty', () {
      expect(tracker.all, isEmpty);
      expect(tracker.totalDividends, 0.0);
    });

    test('addDividend and all', () {
      tracker.addDividend(_makeDividend(id: 'd1'));
      expect(tracker.all.length, 1);
    });

    test('removeDividend by id', () {
      tracker.addDividend(_makeDividend(id: 'd1'));
      final removed = tracker.removeDividend('d1');
      expect(removed, isNotNull);
      expect(tracker.all, isEmpty);
    });

    test('removeDividend returns null for missing id', () {
      expect(tracker.removeDividend('nope'), isNull);
    });

    test('getTotalDividends by symbol', () {
      tracker.addDividend(_makeDividend(id: 'd1', symbol: 'AAPL', amount: 10));
      tracker.addDividend(_makeDividend(id: 'd2', symbol: 'AAPL', amount: 15));
      tracker.addDividend(_makeDividend(id: 'd3', symbol: 'GOOGL', amount: 20));
      expect(tracker.getTotalDividends('AAPL'), 25.0);
      expect(tracker.getTotalDividends('GOOGL'), 20.0);
    });

    test('getBySymbol filters correctly', () {
      tracker.addDividend(_makeDividend(id: 'd1', symbol: 'AAPL'));
      tracker.addDividend(_makeDividend(id: 'd2', symbol: 'GOOGL'));
      expect(tracker.getBySymbol('aapl').length, 1);
    });

    test('getByYear filters correctly', () {
      tracker.addDividend(_makeDividend(
        id: 'd1', payDate: DateTime(2025, 6, 1),
      ));
      tracker.addDividend(_makeDividend(
        id: 'd2', payDate: DateTime(2026, 3, 1),
      ));
      expect(tracker.getByYear(2025).length, 1);
      expect(tracker.getByYear(2026).length, 1);
    });

    test('totalDividends sums all', () {
      tracker.addDividend(_makeDividend(id: 'd1', amount: 10));
      tracker.addDividend(_makeDividend(id: 'd2', amount: 20));
      expect(tracker.totalDividends, 30.0);
    });

    test('totalReinvested and totalCash', () {
      tracker.addDividend(_makeDividend(id: 'd1', amount: 10, reinvested: true));
      tracker.addDividend(_makeDividend(id: 'd2', amount: 20, reinvested: false));
      expect(tracker.totalReinvested, 10.0);
      expect(tracker.totalCash, 20.0);
    });

    test('getSummaryBySymbol groups correctly', () {
      tracker.addDividend(_makeDividend(id: 'd1', symbol: 'AAPL', amount: 10));
      tracker.addDividend(_makeDividend(id: 'd2', symbol: 'AAPL', amount: 15, reinvested: true));
      tracker.addDividend(_makeDividend(id: 'd3', symbol: 'GOOGL', amount: 20));

      final summaries = tracker.getSummaryBySymbol();
      expect(summaries.length, 2);
      expect(summaries['AAPL']!.totalReceived, 25.0);
      expect(summaries['AAPL']!.totalReinvested, 15.0);
      expect(summaries['AAPL']!.paymentCount, 2);
      expect(summaries['GOOGL']!.totalReceived, 20.0);
    });

    test('getMonthlyIncome returns 12 months', () {
      tracker.addDividend(_makeDividend(
        id: 'd1', amount: 10, payDate: DateTime(2026, 3, 15),
      ));
      final monthly = tracker.getMonthlyIncome(year: 2026);
      expect(monthly.length, 12);
      expect(monthly[3], 10.0);
      expect(monthly[1], 0.0);
    });

    test('getQuarterlyIncome returns 4 quarters', () {
      tracker.addDividend(_makeDividend(
        id: 'd1', amount: 10, payDate: DateTime(2026, 3, 15),
      ));
      tracker.addDividend(_makeDividend(
        id: 'd2', amount: 20, payDate: DateTime(2026, 7, 15),
      ));
      final quarterly = tracker.getQuarterlyIncome(year: 2026);
      expect(quarterly.length, 4);
      expect(quarterly[1], 10.0);
      expect(quarterly[3], 20.0);
    });

    test('JSON round-trip', () {
      tracker.addDividend(_makeDividend(id: 'd1', symbol: 'AAPL', amount: 10));
      tracker.addDividend(_makeDividend(id: 'd2', symbol: 'GOOGL', amount: 20));
      final json = tracker.toJson();
      final restored = DividendTracker.fromJson(json);
      expect(restored.all.length, 2);
      expect(restored.totalDividends, 30.0);
    });
  });
}
