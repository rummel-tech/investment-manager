/// Tax lot tracking for cost basis calculations.
library tax_lot;

/// Cost basis calculation methods.
enum CostBasisMethod {
  /// First In, First Out - oldest shares sold first
  fifo,

  /// Last In, First Out - newest shares sold first
  lifo,

  /// Highest In, First Out - highest cost shares sold first (tax optimization)
  hifo,

  /// Specific lot identification - manually select lots
  specificId,
}

/// Represents a tax lot (a specific purchase of shares).
class TaxLot {
  /// Unique lot identifier
  final String id;

  /// Transaction ID that created this lot
  final String transactionId;

  /// Stock ticker symbol
  final String symbol;

  /// Original number of shares purchased
  final double shares;

  /// Total cost basis including fees
  final double costBasis;

  /// Date of purchase
  final DateTime purchaseDate;

  /// Remaining shares not yet sold
  double remainingShares;

  /// Initialize a tax lot.
  ///
  /// Args:
  ///   id: Unique lot identifier
  ///   transactionId: Transaction ID that created this lot
  ///   symbol: Stock ticker symbol
  ///   shares: Number of shares purchased
  ///   costBasis: Total cost basis including fees
  ///   purchaseDate: Date of purchase
  ///   remainingShares: Remaining shares (defaults to shares)
  TaxLot({
    required this.id,
    required this.transactionId,
    required String symbol,
    required this.shares,
    required this.costBasis,
    required this.purchaseDate,
    double? remainingShares,
  })  : symbol = symbol.toUpperCase(),
        remainingShares = remainingShares ?? shares;

  /// Get cost per share.
  double get costPerShare => shares > 0 ? costBasis / shares : 0;

  /// Check if this lot qualifies as long-term (held > 1 year).
  bool get isLongTerm => holdingDays >= 365;

  /// Get number of days held.
  int get holdingDays => DateTime.now().difference(purchaseDate).inDays;

  /// Check if this lot has remaining shares.
  bool get hasRemainingShares => remainingShares > 0;

  /// Get the cost basis for remaining shares.
  double get remainingCostBasis => remainingShares * costPerShare;

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'symbol': symbol,
      'shares': shares,
      'costBasis': costBasis,
      'purchaseDate': purchaseDate.toIso8601String(),
      'remainingShares': remainingShares,
    };
  }

  /// Create a TaxLot from JSON map.
  static TaxLot fromJson(Map<String, dynamic> json) {
    return TaxLot(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      symbol: json['symbol'] as String,
      shares: (json['shares'] as num).toDouble(),
      costBasis: (json['costBasis'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      remainingShares: (json['remainingShares'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'Lot $id: $remainingShares/$shares $symbol @ \$${costPerShare.toStringAsFixed(2)}';
  }
}

/// Result of a cost basis calculation.
class CostBasisResult {
  /// Total cost basis for shares sold
  final double totalCostBasis;

  /// List of lots used in the calculation
  final List<LotUsage> lotsUsed;

  /// Cost basis from short-term lots
  final double shortTermBasis;

  /// Cost basis from long-term lots
  final double longTermBasis;

  /// Shares from short-term lots
  final double shortTermShares;

  /// Shares from long-term lots
  final double longTermShares;

  CostBasisResult({
    required this.totalCostBasis,
    required this.lotsUsed,
    required this.shortTermBasis,
    required this.longTermBasis,
    required this.shortTermShares,
    required this.longTermShares,
  });

  /// Get average cost per share.
  double get averageCostPerShare {
    final totalShares = shortTermShares + longTermShares;
    return totalShares > 0 ? totalCostBasis / totalShares : 0;
  }
}

/// Tracks how much of each lot was used in a sale.
class LotUsage {
  /// The tax lot
  final TaxLot lot;

  /// Shares used from this lot
  final double sharesUsed;

  /// Cost basis for shares used
  final double costBasisUsed;

  LotUsage({
    required this.lot,
    required this.sharesUsed,
    required this.costBasisUsed,
  });
}

/// Unrealized gain/loss for a specific lot.
class UnrealizedGain {
  /// The tax lot
  final TaxLot lot;

  /// Current market value of remaining shares
  final double currentValue;

  /// Cost basis of remaining shares
  final double costBasis;

  /// Unrealized gain/loss amount
  final double gainLoss;

  /// Unrealized gain/loss percentage
  final double gainLossPercent;

  /// Whether this is a long-term holding
  final bool isLongTerm;

  UnrealizedGain({
    required this.lot,
    required this.currentValue,
    required this.costBasis,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.isLongTerm,
  });
}

/// Manages tax lots and calculates cost basis.
class TaxLotManager {
  /// Default cost basis method
  final CostBasisMethod defaultMethod;

  /// Internal map of lots by symbol
  final Map<String, List<TaxLot>> _lotsBySymbol = {};

  /// Initialize a tax lot manager.
  ///
  /// Args:
  ///   defaultMethod: Default cost basis calculation method
  TaxLotManager({this.defaultMethod = CostBasisMethod.fifo});

  /// Add a tax lot.
  void addLot(TaxLot lot) {
    _lotsBySymbol.putIfAbsent(lot.symbol, () => []);
    _lotsBySymbol[lot.symbol]!.add(lot);
  }

  /// Get all lots for a symbol.
  List<TaxLot> getLots(String symbol) {
    return List.unmodifiable(_lotsBySymbol[symbol.toUpperCase()] ?? []);
  }

  /// Get all lots with remaining shares for a symbol.
  List<TaxLot> getAvailableLots(String symbol) {
    return getLots(symbol).where((lot) => lot.hasRemainingShares).toList();
  }

  /// Get total remaining shares for a symbol.
  double getTotalShares(String symbol) {
    return getAvailableLots(symbol).fold(0.0, (sum, lot) => sum + lot.remainingShares);
  }

  /// Get total cost basis for remaining shares of a symbol.
  double getTotalCostBasis(String symbol) {
    return getAvailableLots(symbol).fold(0.0, (sum, lot) => sum + lot.remainingCostBasis);
  }

  /// Calculate cost basis for selling shares.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol
  ///   sharesToSell: Number of shares to sell
  ///   method: Cost basis method (uses default if not specified)
  ///   specificLotIds: Lot IDs to use (for specificId method)
  ///
  /// Returns:
  ///   CostBasisResult with calculation details
  ///
  /// Throws:
  ///   ArgumentError if insufficient shares available
  CostBasisResult calculateCostBasis({
    required String symbol,
    required double sharesToSell,
    CostBasisMethod? method,
    List<String>? specificLotIds,
  }) {
    final useMethod = method ?? defaultMethod;
    final availableLots = getAvailableLots(symbol);

    final totalAvailable = availableLots.fold<double>(0.0, (sum, lot) => sum + lot.remainingShares);
    if (totalAvailable < sharesToSell) {
      throw ArgumentError(
        'Insufficient shares: requested $sharesToSell, available $totalAvailable',
      );
    }

    // Sort lots based on method
    final sortedLots = _sortLotsForMethod(availableLots, useMethod, specificLotIds);

    // Calculate cost basis
    double remainingToSell = sharesToSell;
    double totalCostBasis = 0;
    double shortTermBasis = 0;
    double longTermBasis = 0;
    double shortTermShares = 0;
    double longTermShares = 0;
    final lotsUsed = <LotUsage>[];

    for (final lot in sortedLots) {
      if (remainingToSell <= 0) break;

      final sharesToUse = remainingToSell < lot.remainingShares
          ? remainingToSell
          : lot.remainingShares;
      final costBasisUsed = sharesToUse * lot.costPerShare;

      lotsUsed.add(LotUsage(
        lot: lot,
        sharesUsed: sharesToUse,
        costBasisUsed: costBasisUsed,
      ));

      totalCostBasis += costBasisUsed;
      if (lot.isLongTerm) {
        longTermBasis += costBasisUsed;
        longTermShares += sharesToUse;
      } else {
        shortTermBasis += costBasisUsed;
        shortTermShares += sharesToUse;
      }

      remainingToSell -= sharesToUse;
    }

    return CostBasisResult(
      totalCostBasis: totalCostBasis,
      lotsUsed: lotsUsed,
      shortTermBasis: shortTermBasis,
      longTermBasis: longTermBasis,
      shortTermShares: shortTermShares,
      longTermShares: longTermShares,
    );
  }

  /// Execute a sale, updating lot remaining shares.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol
  ///   sharesToSell: Number of shares to sell
  ///   method: Cost basis method (uses default if not specified)
  ///
  /// Returns:
  ///   CostBasisResult with calculation details
  CostBasisResult executeSale({
    required String symbol,
    required double sharesToSell,
    CostBasisMethod? method,
    List<String>? specificLotIds,
  }) {
    final result = calculateCostBasis(
      symbol: symbol,
      sharesToSell: sharesToSell,
      method: method,
      specificLotIds: specificLotIds,
    );

    // Update remaining shares in lots
    for (final usage in result.lotsUsed) {
      usage.lot.remainingShares -= usage.sharesUsed;
    }

    return result;
  }

  /// Get unrealized gains/losses for a symbol.
  List<UnrealizedGain> getUnrealizedGains(String symbol, double currentPrice) {
    return getAvailableLots(symbol).map((lot) {
      final currentValue = lot.remainingShares * currentPrice;
      final costBasis = lot.remainingCostBasis;
      final gainLoss = currentValue - costBasis;
      final gainLossPercent = costBasis > 0 ? (gainLoss / costBasis) * 100 : 0.0;

      return UnrealizedGain(
        lot: lot,
        currentValue: currentValue,
        costBasis: costBasis,
        gainLoss: gainLoss,
        gainLossPercent: gainLossPercent,
        isLongTerm: lot.isLongTerm,
      );
    }).toList();
  }

  /// Get all symbols with lots.
  List<String> get symbols => _lotsBySymbol.keys.toList();

  /// Sort lots based on cost basis method.
  List<TaxLot> _sortLotsForMethod(
    List<TaxLot> lots,
    CostBasisMethod method,
    List<String>? specificLotIds,
  ) {
    final sortedLots = List<TaxLot>.from(lots);

    switch (method) {
      case CostBasisMethod.fifo:
        // Oldest first
        sortedLots.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        break;
      case CostBasisMethod.lifo:
        // Newest first
        sortedLots.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case CostBasisMethod.hifo:
        // Highest cost first
        sortedLots.sort((a, b) => b.costPerShare.compareTo(a.costPerShare));
        break;
      case CostBasisMethod.specificId:
        // Filter to specific lots if provided
        if (specificLotIds != null) {
          return sortedLots.where((lot) => specificLotIds.contains(lot.id)).toList();
        }
        break;
    }

    return sortedLots;
  }

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'defaultMethod': defaultMethod.name,
      'lots': _lotsBySymbol.map(
        (symbol, lots) => MapEntry(symbol, lots.map((l) => l.toJson()).toList()),
      ),
    };
  }

  /// Create a TaxLotManager from JSON map.
  static TaxLotManager fromJson(Map<String, dynamic> json) {
    final manager = TaxLotManager(
      defaultMethod: CostBasisMethod.values.firstWhere(
        (m) => m.name == json['defaultMethod'],
        orElse: () => CostBasisMethod.fifo,
      ),
    );

    final lotsMap = json['lots'] as Map<String, dynamic>?;
    if (lotsMap != null) {
      for (final entry in lotsMap.entries) {
        for (final lotJson in entry.value as List<dynamic>) {
          manager.addLot(TaxLot.fromJson(lotJson as Map<String, dynamic>));
        }
      }
    }

    return manager;
  }
}
