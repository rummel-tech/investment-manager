/// Tax analysis and optimization tools.
library tax_analyzer;

import 'portfolio.dart';
import 'tax_lot.dart';
import 'transaction.dart';

/// A tax-loss harvesting suggestion.
class TaxLossHarvestingSuggestion {
  /// Stock ticker symbol
  final String symbol;

  /// Current market price
  final double currentPrice;

  /// Total unrealized loss amount
  final double unrealizedLoss;

  /// Potential tax savings at given marginal rate
  final double potentialTaxSavings;

  /// Whether selling would trigger wash sale rules
  final bool isWashSaleRisk;

  /// Number of days until wash sale window expires (null if no risk)
  final int? daysUntilWashSaleClear;

  /// Suggested alternative symbol (similar investment)
  final String? alternativeSymbol;

  /// Shares that could be sold
  final double shares;

  /// Cost basis of shares
  final double costBasis;

  TaxLossHarvestingSuggestion({
    required this.symbol,
    required this.currentPrice,
    required this.unrealizedLoss,
    required this.potentialTaxSavings,
    required this.isWashSaleRisk,
    this.daysUntilWashSaleClear,
    this.alternativeSymbol,
    required this.shares,
    required this.costBasis,
  });

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'currentPrice': currentPrice,
      'unrealizedLoss': unrealizedLoss,
      'potentialTaxSavings': potentialTaxSavings,
      'isWashSaleRisk': isWashSaleRisk,
      'daysUntilWashSaleClear': daysUntilWashSaleClear,
      'alternativeSymbol': alternativeSymbol,
      'shares': shares,
      'costBasis': costBasis,
    };
  }
}

/// Estimated tax liability.
class TaxEstimate {
  /// Short-term capital gains (taxed as ordinary income)
  final double shortTermGains;

  /// Long-term capital gains (taxed at preferential rates)
  final double longTermGains;

  /// Short-term capital losses
  final double shortTermLosses;

  /// Long-term capital losses
  final double longTermLosses;

  /// Net short-term gain/loss
  final double netShortTerm;

  /// Net long-term gain/loss
  final double netLongTerm;

  /// Estimated short-term tax (at provided rate)
  final double estimatedShortTermTax;

  /// Estimated long-term tax (at provided rate)
  final double estimatedLongTermTax;

  /// Total estimated tax liability
  final double totalEstimatedTax;

  /// Capital loss carryover (if losses exceed gains + $3000)
  final double lossCarryover;

  TaxEstimate({
    required this.shortTermGains,
    required this.longTermGains,
    required this.shortTermLosses,
    required this.longTermLosses,
    required this.netShortTerm,
    required this.netLongTerm,
    required this.estimatedShortTermTax,
    required this.estimatedLongTermTax,
    required this.totalEstimatedTax,
    required this.lossCarryover,
  });

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'shortTermGains': shortTermGains,
      'longTermGains': longTermGains,
      'shortTermLosses': shortTermLosses,
      'longTermLosses': longTermLosses,
      'netShortTerm': netShortTerm,
      'netLongTerm': netLongTerm,
      'estimatedShortTermTax': estimatedShortTermTax,
      'estimatedLongTermTax': estimatedLongTermTax,
      'totalEstimatedTax': totalEstimatedTax,
      'lossCarryover': lossCarryover,
    };
  }
}

/// Summary of realized gains/losses.
class RealizedGainsSummary {
  /// Year of the summary
  final int year;

  /// Total proceeds from sales
  final double totalProceeds;

  /// Total cost basis
  final double totalCostBasis;

  /// Total realized gain/loss
  final double totalGainLoss;

  /// Short-term gains
  final double shortTermGains;

  /// Short-term losses
  final double shortTermLosses;

  /// Long-term gains
  final double longTermGains;

  /// Long-term losses
  final double longTermLosses;

  /// Number of transactions
  final int transactionCount;

  RealizedGainsSummary({
    required this.year,
    required this.totalProceeds,
    required this.totalCostBasis,
    required this.totalGainLoss,
    required this.shortTermGains,
    required this.shortTermLosses,
    required this.longTermGains,
    required this.longTermLosses,
    required this.transactionCount,
  });

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'totalProceeds': totalProceeds,
      'totalCostBasis': totalCostBasis,
      'totalGainLoss': totalGainLoss,
      'shortTermGains': shortTermGains,
      'shortTermLosses': shortTermLosses,
      'longTermGains': longTermGains,
      'longTermLosses': longTermLosses,
      'transactionCount': transactionCount,
    };
  }
}

/// Static utility class for tax analysis.
class TaxAnalyzer {
  /// Maximum capital loss deduction per year.
  static const double maxLossDeduction = 3000.0;

  /// Wash sale window in days (30 days before and after).
  static const int washSaleWindow = 30;

  /// Find tax-loss harvesting opportunities.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///   lotManager: Tax lot manager with cost basis data
  ///   marginalTaxRate: Estimated marginal tax rate (default 24%)
  ///   minimumLoss: Minimum loss to consider harvesting (default $100)
  ///   recentTransactions: Recent transactions to check for wash sales
  ///
  /// Returns:
  ///   List of harvesting suggestions sorted by potential savings
  static List<TaxLossHarvestingSuggestion> findHarvestingOpportunities({
    required Portfolio portfolio,
    required TaxLotManager lotManager,
    double marginalTaxRate = 0.24,
    double minimumLoss = 100.0,
    List<Transaction>? recentTransactions,
  }) {
    final suggestions = <TaxLossHarvestingSuggestion>[];

    for (final stock in portfolio.holdings) {
      final unrealizedGains = lotManager.getUnrealizedGains(
        stock.symbol,
        stock.currentPrice,
      );

      // Sum up losses from lots with negative gains
      double totalLoss = 0;
      double totalShares = 0;
      double totalCostBasis = 0;

      for (final gain in unrealizedGains) {
        if (gain.gainLoss < 0) {
          totalLoss += gain.gainLoss.abs();
          totalShares += gain.lot.remainingShares;
          totalCostBasis += gain.costBasis;
        }
      }

      if (totalLoss >= minimumLoss) {
        // Check for wash sale risk
        final washSaleRisk = _checkWashSaleRisk(
          stock.symbol,
          recentTransactions,
        );

        suggestions.add(TaxLossHarvestingSuggestion(
          symbol: stock.symbol,
          currentPrice: stock.currentPrice,
          unrealizedLoss: totalLoss,
          potentialTaxSavings: totalLoss * marginalTaxRate,
          isWashSaleRisk: washSaleRisk != null,
          daysUntilWashSaleClear: washSaleRisk,
          alternativeSymbol: _getSimilarInvestment(stock.symbol),
          shares: totalShares,
          costBasis: totalCostBasis,
        ));
      }
    }

    // Sort by potential savings (highest first)
    suggestions.sort((a, b) => b.potentialTaxSavings.compareTo(a.potentialTaxSavings));

    return suggestions;
  }

  /// Estimate taxes on realized gains.
  ///
  /// Args:
  ///   realizedTransactions: List of sell transactions with cost basis info
  ///   shortTermRate: Tax rate for short-term gains (default 24%)
  ///   longTermRate: Tax rate for long-term gains (default 15%)
  ///
  /// Returns:
  ///   TaxEstimate with detailed breakdown
  static TaxEstimate estimateTaxes({
    required List<RealizedTransaction> realizedTransactions,
    double shortTermRate = 0.24,
    double longTermRate = 0.15,
  }) {
    double shortTermGains = 0;
    double longTermGains = 0;
    double shortTermLosses = 0;
    double longTermLosses = 0;

    for (final rt in realizedTransactions) {
      final gainLoss = rt.proceeds - rt.costBasis;

      if (rt.isLongTerm) {
        if (gainLoss >= 0) {
          longTermGains += gainLoss;
        } else {
          longTermLosses += gainLoss.abs();
        }
      } else {
        if (gainLoss >= 0) {
          shortTermGains += gainLoss;
        } else {
          shortTermLosses += gainLoss.abs();
        }
      }
    }

    // Calculate net gains/losses
    final netShortTerm = shortTermGains - shortTermLosses;
    final netLongTerm = longTermGains - longTermLosses;

    // Apply loss netting rules
    double taxableShortTerm = netShortTerm;
    double taxableLongTerm = netLongTerm;
    double lossCarryover = 0;

    // Net short-term losses against long-term gains and vice versa
    if (netShortTerm < 0 && netLongTerm > 0) {
      taxableLongTerm = netLongTerm + netShortTerm;
      taxableShortTerm = 0;
      if (taxableLongTerm < 0) {
        taxableLongTerm = 0;
      }
    } else if (netLongTerm < 0 && netShortTerm > 0) {
      taxableShortTerm = netShortTerm + netLongTerm;
      taxableLongTerm = 0;
      if (taxableShortTerm < 0) {
        taxableShortTerm = 0;
      }
    }

    // Calculate loss deduction and carryover
    final totalNetLoss = (netShortTerm < 0 ? netShortTerm : 0) +
        (netLongTerm < 0 ? netLongTerm : 0);
    if (totalNetLoss < -maxLossDeduction) {
      lossCarryover = totalNetLoss.abs() - maxLossDeduction;
    }

    // Calculate estimated taxes
    final estimatedShortTermTax = taxableShortTerm > 0 ? taxableShortTerm * shortTermRate : 0.0;
    final estimatedLongTermTax = taxableLongTerm > 0 ? taxableLongTerm * longTermRate : 0.0;

    return TaxEstimate(
      shortTermGains: shortTermGains,
      longTermGains: longTermGains,
      shortTermLosses: shortTermLosses,
      longTermLosses: longTermLosses,
      netShortTerm: netShortTerm,
      netLongTerm: netLongTerm,
      estimatedShortTermTax: estimatedShortTermTax,
      estimatedLongTermTax: estimatedLongTermTax,
      totalEstimatedTax: estimatedShortTermTax + estimatedLongTermTax,
      lossCarryover: lossCarryover,
    );
  }

  /// Get year-to-date realized gains summary.
  ///
  /// Args:
  ///   transactions: All transactions
  ///   lotManager: Tax lot manager for cost basis lookups
  ///   year: Year to summarize (defaults to current year)
  ///
  /// Returns:
  ///   RealizedGainsSummary for the specified year
  static RealizedGainsSummary getYTDRealizedGains({
    required List<Transaction> transactions,
    required TaxLotManager lotManager,
    int? year,
  }) {
    final targetYear = year ?? DateTime.now().year;

    // Filter to sell transactions in the target year
    final sales = transactions
        .where((t) => t.type == TransactionType.sell && t.date.year == targetYear)
        .toList();

    double totalProceeds = 0;
    double totalCostBasis = 0;
    double shortTermGains = 0;
    double shortTermLosses = 0;
    double longTermGains = 0;
    double longTermLosses = 0;

    for (final sale in sales) {
      final proceeds = sale.netAmount;
      totalProceeds += proceeds;

      // Get cost basis from lot manager
      final lots = lotManager.getLots(sale.symbol);
      if (lots.isNotEmpty) {
        // Estimate cost basis using average
        final avgCost = lots.fold<double>(0.0, (sum, l) => sum + l.costPerShare) / lots.length;
        final costBasis = sale.shares * avgCost;
        totalCostBasis += costBasis;

        final gainLoss = proceeds - costBasis;

        // Check holding period (simplified: use oldest lot)
        final oldestLot = lots.reduce((a, b) =>
            a.purchaseDate.isBefore(b.purchaseDate) ? a : b);
        final holdingDays = sale.date.difference(oldestLot.purchaseDate).inDays;
        final isLongTerm = holdingDays >= 365;

        if (isLongTerm) {
          if (gainLoss >= 0) {
            longTermGains += gainLoss;
          } else {
            longTermLosses += gainLoss.abs();
          }
        } else {
          if (gainLoss >= 0) {
            shortTermGains += gainLoss;
          } else {
            shortTermLosses += gainLoss.abs();
          }
        }
      }
    }

    return RealizedGainsSummary(
      year: targetYear,
      totalProceeds: totalProceeds,
      totalCostBasis: totalCostBasis,
      totalGainLoss: totalProceeds - totalCostBasis,
      shortTermGains: shortTermGains,
      shortTermLosses: shortTermLosses,
      longTermGains: longTermGains,
      longTermLosses: longTermLosses,
      transactionCount: sales.length,
    );
  }

  /// Check if a symbol has wash sale risk from recent transactions.
  ///
  /// Returns days until wash sale window expires, or null if no risk.
  static int? _checkWashSaleRisk(
    String symbol,
    List<Transaction>? recentTransactions,
  ) {
    if (recentTransactions == null) return null;

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: washSaleWindow));

    // Look for recent purchases of the same symbol
    for (final tx in recentTransactions) {
      if (tx.symbol == symbol &&
          tx.isPurchase &&
          tx.date.isAfter(windowStart)) {
        final daysSincePurchase = now.difference(tx.date).inDays;
        return washSaleWindow - daysSincePurchase;
      }
    }

    return null;
  }

  /// Get a similar investment suggestion for tax-loss harvesting.
  ///
  /// This returns a broadly similar ETF that would maintain market exposure
  /// while avoiding wash sale rules.
  static String? _getSimilarInvestment(String symbol) {
    // Common ETF alternatives (simplified mapping)
    const alternatives = {
      'SPY': 'VOO',
      'VOO': 'IVV',
      'IVV': 'SPY',
      'QQQ': 'VGT',
      'VGT': 'QQQ',
      'VTI': 'ITOT',
      'ITOT': 'VTI',
      'BND': 'AGG',
      'AGG': 'BND',
      'VEA': 'IEFA',
      'IEFA': 'VEA',
      'VWO': 'IEMG',
      'IEMG': 'VWO',
    };

    return alternatives[symbol.toUpperCase()];
  }
}

/// A realized transaction with cost basis information.
class RealizedTransaction {
  /// Stock ticker symbol
  final String symbol;

  /// Sale date
  final DateTime saleDate;

  /// Shares sold
  final double shares;

  /// Sale proceeds (after fees)
  final double proceeds;

  /// Cost basis of shares sold
  final double costBasis;

  /// Whether this was a long-term holding
  final bool isLongTerm;

  RealizedTransaction({
    required this.symbol,
    required this.saleDate,
    required this.shares,
    required this.proceeds,
    required this.costBasis,
    required this.isLongTerm,
  });

  /// Calculate gain/loss.
  double get gainLoss => proceeds - costBasis;

  /// Calculate gain/loss percentage.
  double get gainLossPercent => costBasis > 0 ? (gainLoss / costBasis) * 100 : 0;
}
