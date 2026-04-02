import 'package:test/test.dart';
import 'package:investment_manager/src/account.dart';

void main() {
  group('Account', () {
    late Account account;

    setUp(() {
      account = Account(
        id: 'acct1',
        name: 'Brokerage',
        type: AccountType.brokerage,
      );
    });

    test('construction with defaults', () {
      expect(account.id, 'acct1');
      expect(account.name, 'Brokerage');
      expect(account.type, AccountType.brokerage);
      expect(account.holdings, isEmpty);
      expect(account.totalValue, 0.0);
    });

    test('isTaxAdvantaged only for retirement', () {
      final brokerage = Account(id: 'b', name: 'b', type: AccountType.brokerage);
      final retirement = Account(id: 'r', name: 'r', type: AccountType.retirement);
      final personal = Account(id: 'p', name: 'p', type: AccountType.personal);
      expect(brokerage.isTaxAdvantaged, isFalse);
      expect(retirement.isTaxAdvantaged, isTrue);
      expect(personal.isTaxAdvantaged, isFalse);
    });

    test('buyStock adds to portfolio and records transaction', () {
      account.buyStock(
        transactionId: 'tx1',
        symbol: 'AAPL',
        shares: 10,
        pricePerShare: 150.0,
      );
      expect(account.holdings.length, 1);
      expect(account.holdings.first.symbol, 'AAPL');
      expect(account.holdings.first.shares, 10);
      expect(account.transactions.all.length, 1);
      expect(account.totalValue, 1500.0);
    });

    test('sellStock removes shares and records transaction', () {
      account.buyStock(
        transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, pricePerShare: 150.0,
      );
      final result = account.sellStock(
        transactionId: 'tx2', symbol: 'AAPL',
        shares: 5, pricePerShare: 160.0,
      );
      expect(result, isTrue);
      expect(account.holdings.first.shares, 5);
      expect(account.transactions.all.length, 2);
    });

    test('sellStock all shares removes from portfolio', () {
      account.buyStock(
        transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, pricePerShare: 150.0,
      );
      account.sellStock(
        transactionId: 'tx2', symbol: 'AAPL',
        shares: 10, pricePerShare: 160.0,
      );
      expect(account.holdings, isEmpty);
    });

    test('sellStock returns false for insufficient shares', () {
      account.buyStock(
        transactionId: 'tx1', symbol: 'AAPL',
        shares: 5, pricePerShare: 150.0,
      );
      final result = account.sellStock(
        transactionId: 'tx2', symbol: 'AAPL',
        shares: 10, pricePerShare: 160.0,
      );
      expect(result, isFalse);
      expect(account.holdings.first.shares, 5);
    });

    test('sellStock returns false for unknown symbol', () {
      final result = account.sellStock(
        transactionId: 'tx1', symbol: 'NOPE',
        shares: 1, pricePerShare: 100,
      );
      expect(result, isFalse);
    });

    test('getSummary returns expected keys', () {
      account.buyStock(
        transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, pricePerShare: 150.0,
      );
      final summary = account.getSummary();
      expect(summary['id'], 'acct1');
      expect(summary['name'], 'Brokerage');
      expect(summary['numHoldings'], 1);
      expect(summary['isTaxAdvantaged'], isFalse);
    });

    test('JSON round-trip', () {
      account.buyStock(
        transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, pricePerShare: 150.0,
      );
      final json = account.toJson();
      final restored = Account.fromJson(json);
      expect(restored.id, 'acct1');
      expect(restored.name, 'Brokerage');
      expect(restored.holdings.length, 1);
      expect(restored.transactions.all.length, 1);
    });
  });

  group('AccountManager', () {
    late AccountManager manager;

    setUp(() {
      manager = AccountManager();
    });

    test('starts empty', () {
      expect(manager.all, isEmpty);
    });

    test('addAccount and getAccount', () {
      final acct = Account(id: 'a1', name: 'Test', type: AccountType.brokerage);
      manager.addAccount(acct);
      expect(manager.getAccount('a1'), isNotNull);
      expect(manager.all.length, 1);
    });

    test('removeAccount', () {
      manager.addAccount(
        Account(id: 'a1', name: 'Test', type: AccountType.brokerage),
      );
      final removed = manager.removeAccount('a1');
      expect(removed, isNotNull);
      expect(manager.all, isEmpty);
    });

    test('getByType filters correctly', () {
      manager.addAccount(
        Account(id: 'b1', name: 'Brokerage', type: AccountType.brokerage),
      );
      manager.addAccount(
        Account(id: 'r1', name: 'IRA', type: AccountType.retirement),
      );
      expect(manager.getByType(AccountType.brokerage).length, 1);
      expect(manager.getByType(AccountType.retirement).length, 1);
      expect(manager.getByType(AccountType.personal).length, 0);
    });

    test('getAggregateView sums across accounts', () {
      final a1 = Account(id: 'a1', name: 'One', type: AccountType.brokerage);
      a1.buyStock(transactionId: 'tx1', symbol: 'AAPL', shares: 10, pricePerShare: 100);
      final a2 = Account(id: 'a2', name: 'Two', type: AccountType.retirement);
      a2.buyStock(transactionId: 'tx2', symbol: 'GOOGL', shares: 5, pricePerShare: 200);
      manager.addAccount(a1);
      manager.addAccount(a2);

      final view = manager.getAggregateView();
      expect(view['numAccounts'], 2);
      expect(view['totalValue'], 2000.0);
      expect(view['uniqueSymbols'], 2);
    });

    test('getAllocationByType returns percentages', () {
      final a1 = Account(id: 'a1', name: 'Brokerage', type: AccountType.brokerage);
      a1.buyStock(transactionId: 'tx1', symbol: 'AAPL', shares: 10, pricePerShare: 100);
      final a2 = Account(id: 'a2', name: 'IRA', type: AccountType.retirement);
      a2.buyStock(transactionId: 'tx2', symbol: 'GOOGL', shares: 10, pricePerShare: 100);
      manager.addAccount(a1);
      manager.addAccount(a2);

      final alloc = manager.getAllocationByType();
      expect(alloc[AccountType.brokerage], closeTo(50.0, 0.1));
      expect(alloc[AccountType.retirement], closeTo(50.0, 0.1));
    });

    test('JSON round-trip', () {
      manager.addAccount(
        Account(id: 'a1', name: 'Test', type: AccountType.brokerage),
      );
      final json = manager.toJson();
      final restored = AccountManager.fromJson(json);
      expect(restored.all.length, 1);
      expect(restored.getAccount('a1')?.name, 'Test');
    });
  });
}
