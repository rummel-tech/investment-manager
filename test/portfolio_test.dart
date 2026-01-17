/// Unit tests for the Portfolio class.

import 'package:test/test.dart';
import 'package:investment_manager/investment_manager.dart';

void main() {
  group('Portfolio', () {
    test('basic portfolio initialization', () {
      final portfolio = Portfolio(name: 'Test Portfolio');
      expect(portfolio.name, equals('Test Portfolio'));
      expect(portfolio.holdings.length, equals(0));
    });

    test('adding a stock to portfolio', () {
      final portfolio = Portfolio();
      final stock = Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      );
      portfolio.addStock(stock);

      expect(portfolio.holdings.length, equals(1));
      expect(portfolio.getStock('AAPL')!.shares, equals(10));
    });

    test('adding duplicate stock merges holdings', () {
      final portfolio = Portfolio();
      final stock1 = Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      );
      final stock2 = Stock(
        symbol: 'AAPL',
        shares: 5,
        purchasePrice: 160.0,
        currentPrice: 165.0,
      );

      portfolio.addStock(stock1);
      portfolio.addStock(stock2);

      expect(portfolio.holdings.length, equals(1));
      final merged = portfolio.getStock('AAPL')!;
      expect(merged.shares, equals(15));
      // Average price: (10*150 + 5*160) / 15 = 2300/15 = 153.33...
      expect(merged.purchasePrice, closeTo(153.33, 0.01));
      expect(merged.currentPrice, equals(165.0));
    });

    test('removing a stock from portfolio', () {
      final portfolio = Portfolio();
      final stock = Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
      );
      portfolio.addStock(stock);

      final removed = portfolio.removeStock('GOOGL');
      expect(removed, isNotNull);
      expect(removed!.symbol, equals('GOOGL'));
      expect(portfolio.holdings.length, equals(0));
    });

    test('removing a stock that does not exist', () {
      final portfolio = Portfolio();
      final removed = portfolio.removeStock('INVALID');
      expect(removed, isNull);
    });

    test('retrieving a stock from portfolio', () {
      final portfolio = Portfolio();
      final stock = Stock(
        symbol: 'MSFT',
        shares: 20,
        purchasePrice: 300.0,
      );
      portfolio.addStock(stock);

      final retrieved = portfolio.getStock('MSFT');
      expect(retrieved, isNotNull);
      expect(retrieved!.symbol, equals('MSFT'));
    });

    test('retrieving a stock that does not exist', () {
      final portfolio = Portfolio();
      final retrieved = portfolio.getStock('INVALID');
      expect(retrieved, isNull);
    });

    test('updating stock price in portfolio', () {
      final portfolio = Portfolio();
      final stock = Stock(
        symbol: 'TSLA',
        shares: 10,
        purchasePrice: 700.0,
      );
      portfolio.addStock(stock);

      final result = portfolio.updateStockPrice('TSLA', 800.0);
      expect(result, isTrue);
      expect(portfolio.getStock('TSLA')!.currentPrice, equals(800.0));
    });

    test('updating price of non-existent stock', () {
      final portfolio = Portfolio();
      final result = portfolio.updateStockPrice('INVALID', 100.0);
      expect(result, isFalse);
    });

    test('total portfolio value calculation', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
        currentPrice: 160.0,
      ));
      portfolio.addStock(Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
        currentPrice: 2900.0,
      ));

      // 10*160 + 5*2900 = 1600 + 14500 = 16100
      expect(portfolio.totalValue, equals(16100.0));
    });

    test('total cost basis calculation', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      ));
      portfolio.addStock(Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
      ));

      // 10*150 + 5*2800 = 1500 + 14000 = 15500
      expect(portfolio.totalCost, equals(15500.0));
    });

    test('total gain/loss calculation', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
        currentPrice: 160.0,
      ));
      portfolio.addStock(Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
        currentPrice: 2700.0,
      ));

      // Value: 1600 + 13500 = 15100
      // Cost: 1500 + 14000 = 15500
      // Gain/Loss: -400
      expect(portfolio.totalGainLoss, equals(-400.0));
    });

    test('total gain/loss percentage calculation', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 100.0,
        currentPrice: 110.0,
      ));

      // Cost: 1000, Value: 1100, Gain: 100, Percent: 10%
      expect(portfolio.totalGainLossPercent, equals(10.0));
    });

    test('portfolio summary generation', () {
      final portfolio = Portfolio(name: 'My Test Portfolio');
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
        currentPrice: 160.0,
      ));

      final summary = portfolio.getSummary();
      expect(summary['name'], equals('My Test Portfolio'));
      expect(summary['num_holdings'], equals(1));
      expect(summary['total_value'], equals(1600.0));
      expect(summary['total_cost'], equals(1500.0));
      expect(summary['total_gain_loss'], equals(100.0));
    });

    test('string conversion', () {
      final portfolio = Portfolio(name: 'My Portfolio');
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      ));
      final strRepr = portfolio.toString();
      expect(strRepr, contains('My Portfolio'));
    });
  });
}
