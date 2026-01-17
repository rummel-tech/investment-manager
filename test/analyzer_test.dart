/// Unit tests for the InvestmentAnalyzer class.

import 'package:test/test.dart';
import 'package:investment_manager/investment_manager.dart';

void main() {
  group('InvestmentAnalyzer', () {
    test('analyzing an empty portfolio', () {
      final portfolio = Portfolio();
      final analysis = InvestmentAnalyzer.analyzePortfolio(portfolio);

      expect(analysis['status'], equals('empty'));
    });

    test('analyzing a portfolio with holdings', () {
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

      final analysis = InvestmentAnalyzer.analyzePortfolio(portfolio);

      expect(analysis['status'], equals('analyzed'));
      expect(analysis['winners'], equals(1)); // AAPL
      expect(analysis['losers'], equals(1)); // GOOGL
      expect(analysis['best_performer']['symbol'], equals('AAPL'));
      expect(analysis['worst_performer']['symbol'], equals('GOOGL'));
    });

    test('identifying high-performing stocks', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 100.0,
        currentPrice: 130.0,
      )); // 30% gain
      portfolio.addStock(Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
        currentPrice: 2900.0,
      )); // 3.57% gain

      final highPerformers = InvestmentAnalyzer.identifyHighPerformers(
        portfolio,
        threshold: 20.0,
      );

      expect(highPerformers.length, equals(1));
      expect(highPerformers[0].symbol, equals('AAPL'));
    });

    test('identifying underperforming stocks', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
        currentPrice: 160.0,
      )); // 6.67% gain
      portfolio.addStock(Stock(
        symbol: 'NFLX',
        shares: 5,
        purchasePrice: 500.0,
        currentPrice: 400.0,
      )); // -20% loss

      final underperformers = InvestmentAnalyzer.identifyUnderperformers(
        portfolio,
        threshold: -10.0,
      );

      expect(underperformers.length, equals(1));
      expect(underperformers[0].symbol, equals('NFLX'));
    });

    test('diversification score for empty portfolio', () {
      final portfolio = Portfolio();
      final result = InvestmentAnalyzer.getDiversificationScore(portfolio);

      expect(result.score, equals(0.0));
      expect(result.recommendation, contains('No holdings'));
    });

    test('diversification score for single stock', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      ));

      final result = InvestmentAnalyzer.getDiversificationScore(portfolio);

      expect(result.score, equals(20.0));
      expect(result.recommendation, contains('Poor'));
    });

    test('diversification score for moderate holdings', () {
      final portfolio = Portfolio();
      for (final symbol in ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA']) {
        portfolio.addStock(Stock(
          symbol: symbol,
          shares: 10,
          purchasePrice: 100.0,
        ));
      }

      final result = InvestmentAnalyzer.getDiversificationScore(portfolio);

      expect(result.score, equals(70.0));
      expect(result.recommendation, contains('Moderate'));
    });

    test('rebalancing suggestions for empty portfolio', () {
      final portfolio = Portfolio();
      final suggestions = InvestmentAnalyzer.getRebalancingSuggestions(portfolio);

      expect(suggestions.length, equals(1));
      expect(suggestions[0]['message'], contains('no value'));
    });

    test('rebalancing suggestions with target allocation', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 100.0,
        currentPrice: 200.0,
      )); // $2000
      portfolio.addStock(Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 100.0,
        currentPrice: 100.0,
      )); // $500
      // Total: $2500, AAPL: 80%, GOOGL: 20%

      final target = {'AAPL': 50.0, 'GOOGL': 50.0};
      final suggestions = InvestmentAnalyzer.getRebalancingSuggestions(
        portfolio,
        target,
      );

      // AAPL should have reduce suggestion (80% vs 50%)
      final aaplSuggestion = suggestions.firstWhere(
        (s) => s['symbol'] == 'AAPL',
      );
      expect(aaplSuggestion['action'], equals('reduce'));

      // GOOGL should have increase suggestion (20% vs 50%)
      final googlSuggestion = suggestions.firstWhere(
        (s) => s['symbol'] == 'GOOGL',
      );
      expect(googlSuggestion['action'], equals('increase'));
    });

    test('recommendations for empty portfolio', () {
      final portfolio = Portfolio();
      final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);

      expect(recommendations.length, equals(1));
      expect(recommendations[0], contains('Start building'));
    });

    test('recommendations for losing portfolio', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
        currentPrice: 100.0,
      )); // -33%

      final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);

      // Should recommend reviewing holdings
      expect(
        recommendations.any((r) => r.contains('down significantly')),
        isTrue,
      );
    });

    test('recommendations for winning portfolio', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 100.0,
        currentPrice: 130.0,
      )); // 30%

      final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);

      // Should recommend taking profits
      expect(
        recommendations.any((r) => r.contains('performing well') || r.contains('profits')),
        isTrue,
      );
    });

    test('diversification recommendations', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
      ));

      final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);

      // Should recommend diversifying (only 1 stock)
      expect(
        recommendations.any((r) => r.contains('Diversify')),
        isTrue,
      );
    });

    test('recommendations for high performers', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 100.0,
        currentPrice: 150.0,
      )); // 50%
      portfolio.addStock(Stock(
        symbol: 'GOOGL',
        shares: 5,
        purchasePrice: 2800.0,
        currentPrice: 2850.0,
      )); // ~1.8%

      final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);

      // Should recommend taking profits on AAPL
      expect(
        recommendations.any((r) => r.contains('high performers') && r.contains('AAPL')),
        isTrue,
      );
    });

    test('recommendations for underperformers', () {
      final portfolio = Portfolio();
      portfolio.addStock(Stock(
        symbol: 'AAPL',
        shares: 10,
        purchasePrice: 150.0,
        currentPrice: 160.0,
      ));
      portfolio.addStock(Stock(
        symbol: 'NFLX',
        shares: 5,
        purchasePrice: 500.0,
        currentPrice: 400.0,
      )); // -20%

      final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);

      // Should recommend reviewing NFLX
      expect(
        recommendations.any((r) => r.contains('underperforming') && r.contains('NFLX')),
        isTrue,
      );
    });
  });
}
