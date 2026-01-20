# Artemis Investment Manager

A Dart library for managing investments, tracking stock holdings, and providing guidance to maximize returns.

## Features

- **Stock Tracking**: Track individual stock holdings with purchase price, current price, and performance metrics
- **Portfolio Management**: Manage multiple stocks in a portfolio with automatic cost basis averaging
- **Investment Analysis**: Get insights and recommendations to maximize returns
- **Performance Metrics**: Calculate gains/losses, diversification scores, and allocation percentages

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  investment_manager:
    path: .
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Stock Management

```dart
import 'package:investment_manager/investment_manager.dart';

// Create a stock holding
final stock = Stock(
  symbol: 'AAPL',
  shares: 10,
  purchasePrice: 150.0,
  currentPrice: 160.0,
);

// Access stock information
print('Total cost: \$${stock.totalCost}');
print('Current value: \$${stock.currentValue}');
print('Gain/Loss: \$${stock.gainLoss} (${stock.gainLossPercent.toStringAsFixed(2)}%)');

// Update price
stock.updatePrice(165.0);
```

### Portfolio Management

```dart
import 'package:investment_manager/investment_manager.dart';

// Create a portfolio
final portfolio = Portfolio(name: 'My Investment Portfolio');

// Add stocks
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

// Get portfolio summary
final summary = portfolio.getSummary();
print('Total Value: \$${summary['total_value'].toStringAsFixed(2)}');
print('Total Gain/Loss: \$${summary['total_gain_loss'].toStringAsFixed(2)}');

// Update stock prices
portfolio.updateStockPrice('AAPL', 165.0);
```

### Investment Analysis

```dart
import 'package:investment_manager/investment_manager.dart';

// Create and populate portfolio
final portfolio = Portfolio(name: 'My Portfolio');
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

// Analyze portfolio
final analysis = InvestmentAnalyzer.analyzePortfolio(portfolio);
print('Winners: ${analysis['winners']}');
print('Losers: ${analysis['losers']}');
print('Best performer: ${analysis['best_performer']['symbol']}');

// Get recommendations
final recommendations = InvestmentAnalyzer.generateRecommendations(portfolio);
for (final rec in recommendations) {
  print('- $rec');
}

// Check diversification
final divResult = InvestmentAnalyzer.getDiversificationScore(portfolio);
print('Diversification Score: ${divResult.score.toStringAsFixed(0)}/100');
print('Recommendation: ${divResult.recommendation}');

// Identify high performers
final highPerformers = InvestmentAnalyzer.identifyHighPerformers(
  portfolio,
  threshold: 20.0,
);
for (final stock in highPerformers) {
  print('${stock.symbol}: ${stock.gainLossPercent.toStringAsFixed(2)}%');
}
```

### Rebalancing Suggestions

```dart
import 'package:investment_manager/investment_manager.dart';

// Get rebalancing suggestions with target allocation
final targetAllocation = {
  'AAPL': 50.0,   // 50% of portfolio
  'GOOGL': 30.0,  // 30% of portfolio
  'MSFT': 20.0,   // 20% of portfolio
};

final suggestions = InvestmentAnalyzer.getRebalancingSuggestions(
  portfolio,
  targetAllocation,
);

for (final suggestion in suggestions) {
  if (suggestion.containsKey('action')) {
    print('${suggestion['symbol']}: ${suggestion['action']} '
          '(current: ${suggestion['current_allocation'].toStringAsFixed(1)}%, '
          'target: ${suggestion['target_allocation'].toStringAsFixed(1)}%)');
  }
}
```

## Running the Example

```bash
dart run bin/example.dart
```

## Running Tests

```bash
dart test
```

## Library Structure

```
lib/
├── investment_manager.dart  # Library exports
└── src/
    ├── stock.dart           # Stock class for individual holdings
    ├── portfolio.dart       # Portfolio class for managing multiple stocks
    └── analyzer.dart        # InvestmentAnalyzer for analysis and recommendations

bin/
└── example.dart             # Example application

test/
├── stock_test.dart          # Tests for Stock class
├── portfolio_test.dart      # Tests for Portfolio class
└── analyzer_test.dart       # Tests for InvestmentAnalyzer class
```

## Documentation

- [Objectives](./OBJECTIVES.md) - Goals, requirements, and success criteria
- [Architecture](docs/ARCHITECTURE.md) - System design
- [Deployment](docs/DEPLOYMENT.md) - Deployment guide
- [Changelog](./CHANGELOG.md) - Version history

## License

MIT License - see LICENSE file for details.

---

[Platform Documentation](../../../docs/) | [Product Overview](../../../docs/products/investment-manager.md)