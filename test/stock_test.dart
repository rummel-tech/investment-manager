/// Unit tests for the Stock class.

import 'package:test/test.dart';
import 'package:investment_manager/investment_manager.dart';

void main() {
  group('Stock', () {
    test('basic stock initialization', () {
      final stock = Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      );
      expect(stock.symbol, equals('AAPL'));
      expect(stock.shares, equals(10));
      expect(stock.purchasePrice, equals(150.0));
      expect(stock.currentPrice, equals(150.0));
    });

    test('stock symbol is converted to uppercase', () {
      final stock = Stock(
        symbol: 'aapl',
        shares: 10,
        purchasePrice: 150.0,
      );
      expect(stock.symbol, equals('AAPL'));
    });

    test('total cost calculation', () {
      final stock = Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
      );
      expect(stock.totalCost, equals(14000.0));
    });

    test('current value calculation', () {
      final stock = Stock(
        symbol: 'MSFT',
        shares: 20,
        purchasePrice: 300.0,
        currentPrice: 350.0,
      );
      expect(stock.currentValue, equals(7000.0));
    });

    test('gain/loss calculation', () {
      final stock = Stock(
        symbol: 'TSLA',
        shares: 10,
        purchasePrice: 700.0,
        currentPrice: 800.0,
      );
      expect(stock.gainLoss, equals(1000.0));

      final stock2 = Stock(
        symbol: 'NFLX',
        shares: 5,
        purchasePrice: 500.0,
        currentPrice: 450.0,
      );
      expect(stock2.gainLoss, equals(-250.0));
    });

    test('gain/loss percentage calculation', () {
      final stock = Stock(
        symbol: 'AMZN',
        shares: 10,
        purchasePrice: 3000.0,
        currentPrice: 3300.0,
      );
      expect(stock.gainLossPercent, equals(10.0));

      final stock2 = Stock(
        symbol: 'FB',
        shares: 20,
        purchasePrice: 350.0,
        currentPrice: 315.0,
      );
      expect(stock2.gainLossPercent, equals(-10.0));
    });

    test('gain/loss percentage with zero cost', () {
      final stock = Stock(
        symbol: 'TEST',
        shares: 10,
        purchasePrice: 0.0,
      );
      expect(stock.gainLossPercent, equals(0.0));
    });

    test('price update functionality', () {
      final stock = Stock(
        symbol: 'NVDA',
        shares: 15,
        purchasePrice: 500.0,
      );
      stock.updatePrice(600.0);
      expect(stock.currentPrice, equals(600.0));
      expect(stock.gainLoss, equals(1500.0));
    });

    test('string representation', () {
      final stock = Stock(
        symbol: 'INTC',
        shares: 30,
        purchasePrice: 50.0,
        currentPrice: 55.0,
      );
      final strRepr = stock.toString();
      expect(strRepr, contains('INTC'));
      expect(strRepr, contains('30'));
    });
  });
}
