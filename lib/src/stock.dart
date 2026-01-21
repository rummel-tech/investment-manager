/// Stock representation and management.
library stock;

/// Represents a stock holding.
class Stock {
  /// Stock ticker symbol (e.g., 'AAPL', 'GOOGL')
  final String symbol;
  
  /// Number of shares owned
  double shares;
  
  /// Price per share at purchase
  double purchasePrice;
  
  /// Current price per share
  double currentPrice;
  
  /// Date of purchase
  final DateTime purchaseDate;
  
  /// Initialize a stock holding.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol (e.g., 'AAPL', 'GOOGL')
  ///   shares: Number of shares owned
  ///   purchasePrice: Price per share at purchase
  ///   currentPrice: Current price per share (defaults to purchasePrice)
  ///   purchaseDate: Date of purchase (defaults to now)
  Stock({
    required String symbol,
    required this.shares,
    required this.purchasePrice,
    double? currentPrice,
    DateTime? purchaseDate,
  })  : symbol = symbol.toUpperCase(),
        currentPrice = currentPrice ?? purchasePrice,
        purchaseDate = purchaseDate ?? DateTime.now();
  
  /// Calculate total cost basis.
  double get totalCost => shares * purchasePrice;
  
  /// Calculate current market value.
  double get currentValue => shares * currentPrice;
  
  /// Calculate gain or loss in dollars.
  double get gainLoss => currentValue - totalCost;
  
  /// Calculate gain or loss as a percentage.
  double get gainLossPercent {
    if (totalCost == 0) {
      return 0.0;
    }
    return (gainLoss / totalCost) * 100;
  }
  
  /// Update the current price of the stock.
  void updatePrice(double newPrice) {
    currentPrice = newPrice;
  }
  
  @override
  String toString() {
    return '$symbol: $shares shares @ \$${currentPrice.toStringAsFixed(2)}';
  }

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'shares': shares,
      'purchasePrice': purchasePrice,
      'currentPrice': currentPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  /// Create a Stock from JSON map.
  ///
  /// Args:
  ///   json: Map containing stock data
  ///
  /// Returns:
  ///   Stock instance
  static Stock fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      shares: (json['shares'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentPrice: json['currentPrice'] != null
          ? (json['currentPrice'] as num).toDouble()
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
    );
  }
}
