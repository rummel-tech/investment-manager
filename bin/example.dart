#!/usr/bin/env dart
/// Example usage of the Artemis Investment Manager module.
///
/// This script demonstrates the key features of the module:
/// - Creating stock holdings
/// - Managing a portfolio
/// - Analyzing investments
/// - Getting recommendations

import 'package:investment_manager/investment_manager.dart';

void main() {
  print('=' * 60);
  print('Artemis Investment Manager - Example Usage');
  print('=' * 60);
  print('');
  
  // Create a portfolio
  print('Creating portfolio...');
  final portfolio = Portfolio(name: 'My Investment Portfolio');
  print('✓ Created: $portfolio');
  print('');
  
  // Add some stocks
  print('Adding stocks to portfolio...');
  final stocks = [
    Stock(
      symbol: 'AAPL',
      shares: 10,
      purchasePrice: 150.0,
      currentPrice: 165.0,
    ),
    Stock(
      symbol: 'GOOGL',
      shares: 5,
      purchasePrice: 2800.0,
      currentPrice: 2900.0,
    ),
    Stock(
      symbol: 'MSFT',
      shares: 15,
      purchasePrice: 300.0,
      currentPrice: 320.0,
    ),
    Stock(
      symbol: 'TSLA',
      shares: 8,
      purchasePrice: 700.0,
      currentPrice: 650.0,
    ),
    Stock(
      symbol: 'AMZN',
      shares: 3,
      purchasePrice: 3000.0,
      currentPrice: 3150.0,
    ),
  ];
  
  for (final stock in stocks) {
    portfolio.addStock(stock);
    print('  ✓ Added: $stock');
  }
  print('');
  
  // Display portfolio summary
  print('-' * 60);
  print('Portfolio Summary');
  print('-' * 60);
  final summary = portfolio.getSummary();
  print('Name: ${summary['name']}');
  print('Number of Holdings: ${summary['num_holdings']}');
  print('Total Cost: \$${summary['total_cost'].toStringAsFixed(2)}');
  print('Total Value: \$${summary['total_value'].toStringAsFixed(2)}');
  print('Total Gain/Loss: \$${summary['total_gain_loss'].toStringAsFixed(2)}');
  print('Total Gain/Loss %: ${summary['total_gain_loss_percent'].toStringAsFixed(2)}%');
  print('');
  
  // Display individual holdings
  print('-' * 60);
  print('Individual Holdings');
  print('-' * 60);
  print('Symbol    Shares    Cost            Value           Gain/Loss');
  print('-' * 60);
  for (final stock in portfolio.holdings) {
    final gainLossStr = '\$${stock.gainLoss.toStringAsFixed(2)} (${stock.gainLossPercent >= 0 ? '+' : ''}${stock.gainLossPercent.toStringAsFixed(2)}%)';
    print('${stock.symbol.padRight(10)}${stock.shares.toString().padRight(10)}'
          '\$${stock.totalCost.toStringAsFixed(2).padRight(15)}'
          '\$${stock.currentValue.toStringAsFixed(2).padRight(15)}'
          '$gainLossStr');
  }
  print('');
  
  // Analyze portfolio
  print('-' * 60);
  print('Portfolio Analysis');
  print('-' * 60);
  final analysis = InvestmentAnalyzer.analyzePortfolio(portfolio);
  print('Winning positions: ${analysis['winners']}');
  print('Losing positions: ${analysis['losers']}');
  print('Best performer: ${analysis['best_performer']['symbol']} '
        '(${analysis['best_performer']['gain_loss_percent'].toStringAsFixed(2)}%)');
  print('Worst performer: ${analysis['worst_performer']['symbol']} '
        '(${analysis['worst_performer']['gain_loss_percent'].toStringAsFixed(2)}%)');
  print('');
  
  // Check diversification
  print('-' * 60);
  print('Diversification Analysis');
  print('-' * 60);
  final divResult = InvestmentAnalyzer.getDiversificationScore(portfolio);
  print('Diversification Score: ${divResult.score.toStringAsFixed(0)}/100');
  print('Recommendation: ${divResult.recommendation}');
  print('');
  
  // Identify high performers and underperformers
  print('-' * 60);
  print('Performance Analysis');
  print('-' * 60);
  final highPerformers = InvestmentAnalyzer.identifyHighPerformers(
    portfolio,
    threshold: 10.0,
  );
  if (highPerformers.isNotEmpty) {
    print('High Performers (>10% gain):');
    for (final stock in highPerformers) {
      print('  • ${stock.symbol}: ${stock.gainLossPercent >= 0 ? '+' : ''}${stock.gainLossPercent.toStringAsFixed(2)}%');
    }
  }
  
  final underperformers = InvestmentAnalyzer.identifyUnderperformers(
    portfolio,
    threshold: -5.0,
  );
  if (underperformers.isNotEmpty) {
    print('Underperformers (<-5% loss):');
    for (final stock in underperformers) {
      print('  • ${stock.symbol}: ${stock.gainLossPercent >= 0 ? '+' : ''}${stock.gainLossPercent.toStringAsFixed(2)}%');
    }
  }
  print('');
  
  // Get recommendations
  print('-' * 60);
  print('Investment Recommendations');
  print('-' * 60);
  final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);
  for (var i = 0; i < recommendations.length; i++) {
    print('${i + 1}. ${recommendations[i]}');
  }
  print('');
  
  // Rebalancing suggestions
  print('-' * 60);
  print('Rebalancing Suggestions');
  print('-' * 60);
  // Target allocation percentages should sum to 100%
  final targetAllocation = {
    'AAPL': 25.0,
    'GOOGL': 25.0,
    'MSFT': 25.0,
    'TSLA': 15.0,
    'AMZN': 10.0,
  };
  // Verify allocation sums to 100%
  final sum = targetAllocation.values.reduce((a, b) => a + b);
  assert(sum == 100.0, 'Target allocation must sum to 100%');
  
  final suggestions = InvestmentAnalyzer.getRebalancingSuggestions(
    portfolio,
    targetAllocation,
  );
  for (final suggestion in suggestions) {
    if (suggestion.containsKey('action')) {
      print('${suggestion['symbol']}: ${suggestion['action'].toString().toUpperCase()} position');
      print('  Current: ${suggestion['current_allocation'].toStringAsFixed(1)}% | '
            'Target: ${suggestion['target_allocation'].toStringAsFixed(1)}% | '
            'Difference: ${suggestion['difference'].toStringAsFixed(1)}%');
    }
  }
  print('');
  
  print('=' * 60);
  print('Example completed successfully!');
  print('=' * 60);
}
