# Artemis Investment Manager

A Python module for managing investments, tracking stock holdings, and providing guidance to maximize returns.

## Features

- **Stock Tracking**: Track individual stock holdings with purchase price, current price, and performance metrics
- **Portfolio Management**: Manage multiple stocks in a portfolio with automatic cost basis averaging
- **Investment Analysis**: Get insights and recommendations to maximize returns
- **Performance Metrics**: Calculate gains/losses, diversification scores, and allocation percentages

## Installation

```bash
pip install -e .
```

## Usage

### Basic Stock Management

```python
from artemis import Stock

# Create a stock holding
stock = Stock("AAPL", shares=10, purchase_price=150.0, current_price=160.0)

# Access stock information
print(f"Total cost: ${stock.total_cost}")
print(f"Current value: ${stock.current_value}")
print(f"Gain/Loss: ${stock.gain_loss} ({stock.gain_loss_percent:.2f}%)")

# Update price
stock.update_price(165.0)
```

### Portfolio Management

```python
from artemis import Portfolio, Stock

# Create a portfolio
portfolio = Portfolio("My Investment Portfolio")

# Add stocks
portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2900.0))

# Get portfolio summary
summary = portfolio.get_summary()
print(f"Total Value: ${summary['total_value']:.2f}")
print(f"Total Gain/Loss: ${summary['total_gain_loss']:.2f}")

# Update stock prices
portfolio.update_stock_price("AAPL", 165.0)
```

### Investment Analysis

```python
from artemis import Portfolio, Stock, InvestmentAnalyzer

# Create and populate portfolio
portfolio = Portfolio("My Portfolio")
portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2700.0))

# Analyze portfolio
analysis = InvestmentAnalyzer.analyze_portfolio(portfolio)
print(f"Winners: {analysis['winners']}")
print(f"Losers: {analysis['losers']}")
print(f"Best performer: {analysis['best_performer']['symbol']}")

# Get recommendations
recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
for rec in recommendations:
    print(f"- {rec}")

# Check diversification
score, recommendation = InvestmentAnalyzer.get_diversification_score(portfolio)
print(f"Diversification Score: {score}/100")
print(f"Recommendation: {recommendation}")

# Identify high performers
high_performers = InvestmentAnalyzer.identify_high_performers(portfolio, threshold=20.0)
for stock in high_performers:
    print(f"{stock.symbol}: {stock.gain_loss_percent:.2f}%")
```

### Rebalancing Suggestions

```python
from artemis import InvestmentAnalyzer

# Get rebalancing suggestions with target allocation
target_allocation = {
    "AAPL": 50.0,   # 50% of portfolio
    "GOOGL": 30.0,  # 30% of portfolio
    "MSFT": 20.0    # 20% of portfolio
}

suggestions = InvestmentAnalyzer.get_rebalancing_suggestions(
    portfolio, 
    target_allocation
)

for suggestion in suggestions:
    if "action" in suggestion:
        print(f"{suggestion['symbol']}: {suggestion['action']} "
              f"(current: {suggestion['current_allocation']:.1f}%, "
              f"target: {suggestion['target_allocation']:.1f}%)")
```

## Running Tests

```bash
python -m pytest tests/
# or
python tests/__init__.py
```

## Module Structure

```
artemis/
├── __init__.py          # Module initialization
├── stock.py             # Stock class for individual holdings
├── portfolio.py         # Portfolio class for managing multiple stocks
└── analyzer.py          # InvestmentAnalyzer for analysis and recommendations

tests/
├── __init__.py          # Test runner
├── test_stock.py        # Tests for Stock class
├── test_portfolio.py    # Tests for Portfolio class
└── test_analyzer.py     # Tests for InvestmentAnalyzer class
```

## License

MIT License - see LICENSE file for details.