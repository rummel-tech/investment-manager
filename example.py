#!/usr/bin/env python3
"""
Example usage of the Artemis Investment Manager module.

This script demonstrates the key features of the module:
- Creating stock holdings
- Managing a portfolio
- Analyzing investments
- Getting recommendations
"""

from artemis import Stock, Portfolio, InvestmentAnalyzer


def main():
    print("=" * 60)
    print("Artemis Investment Manager - Example Usage")
    print("=" * 60)
    print()
    
    # Create a portfolio
    print("Creating portfolio...")
    portfolio = Portfolio("My Investment Portfolio")
    print(f"✓ Created: {portfolio}")
    print()
    
    # Add some stocks
    print("Adding stocks to portfolio...")
    stocks = [
        Stock("AAPL", shares=10, purchase_price=150.0, current_price=165.0),
        Stock("GOOGL", shares=5, purchase_price=2800.0, current_price=2900.0),
        Stock("MSFT", shares=15, purchase_price=300.0, current_price=320.0),
        Stock("TSLA", shares=8, purchase_price=700.0, current_price=650.0),
        Stock("AMZN", shares=3, purchase_price=3000.0, current_price=3150.0),
    ]
    
    for stock in stocks:
        portfolio.add_stock(stock)
        print(f"  ✓ Added: {stock}")
    print()
    
    # Display portfolio summary
    print("-" * 60)
    print("Portfolio Summary")
    print("-" * 60)
    summary = portfolio.get_summary()
    print(f"Name: {summary['name']}")
    print(f"Number of Holdings: {summary['num_holdings']}")
    print(f"Total Cost: ${summary['total_cost']:,.2f}")
    print(f"Total Value: ${summary['total_value']:,.2f}")
    print(f"Total Gain/Loss: ${summary['total_gain_loss']:,.2f}")
    print(f"Total Gain/Loss %: {summary['total_gain_loss_percent']:.2f}%")
    print()
    
    # Display individual holdings
    print("-" * 60)
    print("Individual Holdings")
    print("-" * 60)
    print(f"{'Symbol':<10} {'Shares':<10} {'Cost':<15} {'Value':<15} {'Gain/Loss':<15}")
    print("-" * 60)
    for stock in portfolio.holdings:
        gain_loss_str = f"${stock.gain_loss:,.2f} ({stock.gain_loss_percent:+.2f}%)"
        print(f"{stock.symbol:<10} {stock.shares:<10} ${stock.total_cost:<14,.2f} "
              f"${stock.current_value:<14,.2f} {gain_loss_str:<15}")
    print()
    
    # Analyze portfolio
    print("-" * 60)
    print("Portfolio Analysis")
    print("-" * 60)
    analysis = InvestmentAnalyzer.analyze_portfolio(portfolio)
    print(f"Winning positions: {analysis['winners']}")
    print(f"Losing positions: {analysis['losers']}")
    print(f"Best performer: {analysis['best_performer']['symbol']} "
          f"({analysis['best_performer']['gain_loss_percent']:.2f}%)")
    print(f"Worst performer: {analysis['worst_performer']['symbol']} "
          f"({analysis['worst_performer']['gain_loss_percent']:.2f}%)")
    print()
    
    # Check diversification
    print("-" * 60)
    print("Diversification Analysis")
    print("-" * 60)
    score, recommendation = InvestmentAnalyzer.get_diversification_score(portfolio)
    print(f"Diversification Score: {score}/100")
    print(f"Recommendation: {recommendation}")
    print()
    
    # Identify high performers and underperformers
    print("-" * 60)
    print("Performance Analysis")
    print("-" * 60)
    high_performers = InvestmentAnalyzer.identify_high_performers(portfolio, threshold=10.0)
    if high_performers:
        print("High Performers (>10% gain):")
        for stock in high_performers:
            print(f"  • {stock.symbol}: {stock.gain_loss_percent:+.2f}%")
    
    underperformers = InvestmentAnalyzer.identify_underperformers(portfolio, threshold=-5.0)
    if underperformers:
        print("Underperformers (<-5% loss):")
        for stock in underperformers:
            print(f"  • {stock.symbol}: {stock.gain_loss_percent:+.2f}%")
    print()
    
    # Get recommendations
    print("-" * 60)
    print("Investment Recommendations")
    print("-" * 60)
    recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
    for i, rec in enumerate(recommendations, 1):
        print(f"{i}. {rec}")
    print()
    
    # Rebalancing suggestions
    print("-" * 60)
    print("Rebalancing Suggestions")
    print("-" * 60)
    # Target allocation percentages should sum to 100%
    target_allocation = {
        "AAPL": 25.0,
        "GOOGL": 25.0,
        "MSFT": 25.0,
        "TSLA": 15.0,
        "AMZN": 10.0
    }
    # Verify allocation sums to 100%
    assert sum(target_allocation.values()) == 100.0, "Target allocation must sum to 100%"
    
    suggestions = InvestmentAnalyzer.get_rebalancing_suggestions(portfolio, target_allocation)
    for suggestion in suggestions:
        if "action" in suggestion:
            print(f"{suggestion['symbol']}: {suggestion['action'].upper()} position")
            print(f"  Current: {suggestion['current_allocation']:.1f}% | "
                  f"Target: {suggestion['target_allocation']:.1f}% | "
                  f"Difference: {suggestion['difference']:.1f}%")
    print()
    
    print("=" * 60)
    print("Example completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    main()
