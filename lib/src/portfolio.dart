/// Portfolio management for tracking multiple stock holdings.
library portfolio;

import 'stock.dart';

/// Manages a collection of stock holdings.
class Portfolio {
  /// Name of the portfolio
  final String name;
  
  /// Internal holdings map
  final Map<String, Stock> _holdings = {};
  
  /// Initialize a portfolio.
  ///
  /// Args:
  ///   name: Name of the portfolio
  Portfolio({this.name = "My Portfolio"});
  
  /// Add a stock to the portfolio.
  ///
  /// Args:
  ///   stock: Stock instance to add
  void addStock(Stock stock) {
    final symbol = stock.symbol;
    if (_holdings.containsKey(symbol)) {
      // Merge with existing holding (average cost basis)
      final existing = _holdings[symbol]!;
      final totalShares = existing.shares + stock.shares;
      final totalCostValue = existing.totalCost + stock.totalCost;
      final newAvgPrice = totalCostValue / totalShares;
      
      existing.shares = totalShares;
      existing.purchasePrice = newAvgPrice;
      existing.currentPrice = stock.currentPrice;
    } else {
      _holdings[symbol] = stock;
    }
  }
  
  /// Remove a stock from the portfolio.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol
  ///
  /// Returns:
  ///   Removed stock or null if not found
  Stock? removeStock(String symbol) {
    return _holdings.remove(symbol.toUpperCase());
  }
  
  /// Get a stock from the portfolio.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol
  ///
  /// Returns:
  ///   Stock instance or null if not found
  Stock? getStock(String symbol) {
    return _holdings[symbol.toUpperCase()];
  }
  
  /// Update the current price of a stock.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol
  ///   newPrice: New current price
  ///
  /// Returns:
  ///   true if updated, false if stock not found
  bool updateStockPrice(String symbol, double newPrice) {
    final stock = getStock(symbol);
    if (stock != null) {
      stock.updatePrice(newPrice);
      return true;
    }
    return false;
  }
  
  /// Get all stocks in the portfolio.
  List<Stock> get holdings => _holdings.values.toList();
  
  /// Calculate total current value of portfolio.
  double get totalValue {
    return _holdings.values.fold(0.0, (sum, stock) => sum + stock.currentValue);
  }
  
  /// Calculate total cost basis of portfolio.
  double get totalCost {
    return _holdings.values.fold(0.0, (sum, stock) => sum + stock.totalCost);
  }
  
  /// Calculate total gain/loss in dollars.
  double get totalGainLoss => totalValue - totalCost;
  
  /// Calculate total gain/loss as a percentage.
  double get totalGainLossPercent {
    if (totalCost == 0) {
      return 0.0;
    }
    return (totalGainLoss / totalCost) * 100;
  }
  
  /// Get a summary of the portfolio.
  ///
  /// Returns:
  ///   Map with portfolio summary statistics
  Map<String, dynamic> getSummary() {
    return {
      'name': name,
      'num_holdings': _holdings.length,
      'total_value': totalValue,
      'total_cost': totalCost,
      'total_gain_loss': totalGainLoss,
      'total_gain_loss_percent': totalGainLossPercent,
    };
  }
  
  @override
  String toString() {
    return '$name: ${_holdings.length} stocks, \$${totalValue.toStringAsFixed(2)} value';
  }

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'holdings': _holdings.values.map((stock) => stock.toJson()).toList(),
    };
  }

  /// Create a Portfolio from JSON map.
  ///
  /// Args:
  ///   json: Map containing portfolio data
  ///
  /// Returns:
  ///   Portfolio instance
  static Portfolio fromJson(Map<String, dynamic> json) {
    final portfolio = Portfolio(name: json['name'] as String? ?? 'My Portfolio');
    final holdingsList = json['holdings'] as List<dynamic>?;
    if (holdingsList != null) {
      for (final holdingJson in holdingsList) {
        portfolio.addStock(Stock.fromJson(holdingJson as Map<String, dynamic>));
      }
    }
    return portfolio;
  }
}
