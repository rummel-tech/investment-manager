import 'package:test/test.dart';
import 'package:investment_manager/src/transaction.dart';

void main() {
  group('Transaction', () {
    test('constructor uppercases symbol', () {
      final t = Transaction(
        id: 'tx1',
        accountId: 'acct1',
        symbol: 'aapl',
        type: TransactionType.buy,
        shares: 10,
        pricePerShare: 150.0,
      );
      expect(t.symbol, 'AAPL');
    });

    test('totalAmount is shares * price', () {
      final t = Transaction(
        id: 'tx1',
        accountId: 'acct1',
        symbol: 'AAPL',
        type: TransactionType.buy,
        shares: 10,
        pricePerShare: 150.0,
      );
      expect(t.totalAmount, 1500.0);
    });

    test('netAmount for buy includes fees', () {
      final t = Transaction(
        id: 'tx1',
        accountId: 'acct1',
        symbol: 'AAPL',
        type: TransactionType.buy,
        shares: 10,
        pricePerShare: 150.0,
        fees: 9.99,
      );
      expect(t.netAmount, 1509.99);
    });

    test('netAmount for sell subtracts fees', () {
      final t = Transaction(
        id: 'tx1',
        accountId: 'acct1',
        symbol: 'AAPL',
        type: TransactionType.sell,
        shares: 10,
        pricePerShare: 150.0,
        fees: 9.99,
      );
      expect(t.netAmount, 1490.01);
    });

    test('isPurchase is true for buy and dividendReinvest', () {
      final buy = Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 1, pricePerShare: 1,
      );
      final reinvest = Transaction(
        id: 'tx2', accountId: 'a', symbol: 'X',
        type: TransactionType.dividendReinvest, shares: 1, pricePerShare: 1,
      );
      final sell = Transaction(
        id: 'tx3', accountId: 'a', symbol: 'X',
        type: TransactionType.sell, shares: 1, pricePerShare: 1,
      );
      expect(buy.isPurchase, isTrue);
      expect(reinvest.isPurchase, isTrue);
      expect(sell.isPurchase, isFalse);
    });

    test('isSale is true only for sell', () {
      final sell = Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.sell, shares: 1, pricePerShare: 1,
      );
      final buy = Transaction(
        id: 'tx2', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 1, pricePerShare: 1,
      );
      expect(sell.isSale, isTrue);
      expect(buy.isSale, isFalse);
    });

    test('JSON round-trip', () {
      final date = DateTime(2026, 3, 1);
      final t = Transaction(
        id: 'tx1',
        accountId: 'acct1',
        symbol: 'GOOGL',
        type: TransactionType.sell,
        shares: 5,
        pricePerShare: 180.0,
        fees: 4.99,
        date: date,
        notes: 'profit taking',
      );
      final json = t.toJson();
      final restored = Transaction.fromJson(json);
      expect(restored.id, 'tx1');
      expect(restored.symbol, 'GOOGL');
      expect(restored.type, TransactionType.sell);
      expect(restored.shares, 5);
      expect(restored.pricePerShare, 180.0);
      expect(restored.fees, 4.99);
      expect(restored.notes, 'profit taking');
    });

    test('default fees is 0', () {
      final t = Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 1, pricePerShare: 100,
      );
      expect(t.fees, 0.0);
    });
  });

  group('TransactionHistory', () {
    late TransactionHistory history;

    setUp(() {
      history = TransactionHistory();
    });

    test('starts empty', () {
      expect(history.all, isEmpty);
    });

    test('addTransaction stores and sorts by date desc', () {
      final older = Transaction(
        id: 'tx1', accountId: 'a', symbol: 'AAPL',
        type: TransactionType.buy, shares: 10, pricePerShare: 100,
        date: DateTime(2026, 1, 1),
      );
      final newer = Transaction(
        id: 'tx2', accountId: 'a', symbol: 'AAPL',
        type: TransactionType.buy, shares: 5, pricePerShare: 110,
        date: DateTime(2026, 3, 1),
      );
      history.addTransaction(older);
      history.addTransaction(newer);
      expect(history.all.length, 2);
      expect(history.all.first.id, 'tx2');
    });

    test('removeTransaction by id', () {
      final t = Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 1, pricePerShare: 1,
      );
      history.addTransaction(t);
      final removed = history.removeTransaction('tx1');
      expect(removed, isNotNull);
      expect(history.all, isEmpty);
    });

    test('removeTransaction returns null for missing id', () {
      expect(history.removeTransaction('nope'), isNull);
    });

    test('getBySymbol filters correctly', () {
      history.addTransaction(Transaction(
        id: 'tx1', accountId: 'a', symbol: 'AAPL',
        type: TransactionType.buy, shares: 10, pricePerShare: 100,
      ));
      history.addTransaction(Transaction(
        id: 'tx2', accountId: 'a', symbol: 'GOOGL',
        type: TransactionType.buy, shares: 5, pricePerShare: 200,
      ));
      expect(history.getBySymbol('aapl').length, 1);
      expect(history.getBySymbol('GOOGL').length, 1);
    });

    test('getByType filters correctly', () {
      history.addTransaction(Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 1, pricePerShare: 1,
      ));
      history.addTransaction(Transaction(
        id: 'tx2', accountId: 'a', symbol: 'X',
        type: TransactionType.sell, shares: 1, pricePerShare: 1,
      ));
      expect(history.getByType(TransactionType.buy).length, 1);
      expect(history.getByType(TransactionType.sell).length, 1);
    });

    test('purchases and sales getters', () {
      history.addTransaction(Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 10, pricePerShare: 100,
      ));
      history.addTransaction(Transaction(
        id: 'tx2', accountId: 'a', symbol: 'X',
        type: TransactionType.sell, shares: 5, pricePerShare: 110,
      ));
      history.addTransaction(Transaction(
        id: 'tx3', accountId: 'a', symbol: 'X',
        type: TransactionType.dividendReinvest, shares: 1, pricePerShare: 105,
      ));
      expect(history.purchases.length, 2);
      expect(history.sales.length, 1);
    });

    test('totalFees sums all fees', () {
      history.addTransaction(Transaction(
        id: 'tx1', accountId: 'a', symbol: 'X',
        type: TransactionType.buy, shares: 1, pricePerShare: 100, fees: 5.0,
      ));
      history.addTransaction(Transaction(
        id: 'tx2', accountId: 'a', symbol: 'X',
        type: TransactionType.sell, shares: 1, pricePerShare: 100, fees: 4.99,
      ));
      expect(history.totalFees, closeTo(9.99, 0.01));
    });

    test('JSON round-trip', () {
      history.addTransaction(Transaction(
        id: 'tx1', accountId: 'a', symbol: 'AAPL',
        type: TransactionType.buy, shares: 10, pricePerShare: 150,
        date: DateTime(2026, 1, 15),
      ));
      final json = history.toJson();
      final restored = TransactionHistory.fromJson(json);
      expect(restored.all.length, 1);
      expect(restored.all.first.symbol, 'AAPL');
    });
  });
}
