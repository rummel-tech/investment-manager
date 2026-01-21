/// Investment analysis and guidance to maximize returns.
library analyzer;

import 'account.dart';
import 'dividend.dart';
import 'portfolio.dart';
import 'stock.dart';

/// Performance analysis result for a single stock
class StockPerformance {
  final String symbol;
  final double gainLossPercent;

  StockPerformance(this.symbol, this.gainLossPercent);
}

/// Provides analysis and guidance for investment portfolios.
class InvestmentAnalyzer {
  /// Analyze a portfolio and provide insights.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///
  /// Returns:
  ///   Map with analysis results
  static Map<String, dynamic> analyzePortfolio(Portfolio portfolio) {
    final holdings = portfolio.holdings;
    
    if (holdings.isEmpty) {
      return {
        'status': 'empty',
        'message': 'Portfolio is empty. No analysis available.',
      };
    }
    
    // Calculate metrics
    final winners = holdings.where((s) => s.gainLoss > 0).toList();
    final losers = holdings.where((s) => s.gainLoss < 0).toList();
    
    final bestPerformer = holdings.reduce(
      (a, b) => a.gainLossPercent > b.gainLossPercent ? a : b
    );
    final worstPerformer = holdings.reduce(
      (a, b) => a.gainLossPercent < b.gainLossPercent ? a : b
    );
    
    return {
      'status': 'analyzed',
      'summary': portfolio.getSummary(),
      'winners': winners.length,
      'losers': losers.length,
      'best_performer': {
        'symbol': bestPerformer.symbol,
        'gain_loss_percent': bestPerformer.gainLossPercent,
      },
      'worst_performer': {
        'symbol': worstPerformer.symbol,
        'gain_loss_percent': worstPerformer.gainLossPercent,
      },
    };
  }
  
  /// Get suggestions for rebalancing the portfolio.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///   targetAllocation: Optional map of {symbol: target_percent}
  ///
  /// Returns:
  ///   List of rebalancing suggestions
  static List<Map<String, dynamic>> getRebalancingSuggestions(
    Portfolio portfolio,
    [Map<String, double>? targetAllocation]
  ) {
    final suggestions = <Map<String, dynamic>>[];
    final totalValue = portfolio.totalValue;
    
    if (totalValue == 0) {
      return [
        {'message': 'Portfolio has no value. Cannot provide rebalancing suggestions.'}
      ];
    }
    
    for (final stock in portfolio.holdings) {
      final currentAllocation = (stock.currentValue / totalValue) * 100;
      
      if (targetAllocation != null && targetAllocation.containsKey(stock.symbol)) {
        final target = targetAllocation[stock.symbol]!;
        final diff = currentAllocation - target;
        
        if (diff.abs() > 5) {  // Significant deviation (>5%)
          final action = diff > 0 ? 'reduce' : 'increase';
          suggestions.add({
            'symbol': stock.symbol,
            'action': action,
            'current_allocation': currentAllocation,
            'target_allocation': target,
            'difference': diff.abs(),
          });
        }
      } else {
        // Provide general allocation info
        suggestions.add({
          'symbol': stock.symbol,
          'current_allocation': currentAllocation,
        });
      }
    }
    
    return suggestions;
  }
  
  /// Identify stocks that have exceeded a performance threshold.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///   threshold: Minimum gain percentage to be considered high performer
  ///
  /// Returns:
  ///   List of high-performing stocks
  static List<Stock> identifyHighPerformers(
    Portfolio portfolio,
    {double threshold = 20.0}
  ) {
    return portfolio.holdings
        .where((stock) => stock.gainLossPercent >= threshold)
        .toList();
  }
  
  /// Identify stocks that have fallen below a performance threshold.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///   threshold: Maximum loss percentage to be considered underperformer
  ///
  /// Returns:
  ///   List of underperforming stocks
  static List<Stock> identifyUnderperformers(
    Portfolio portfolio,
    {double threshold = -10.0}
  ) {
    return portfolio.holdings
        .where((stock) => stock.gainLossPercent <= threshold)
        .toList();
  }
  
  /// Calculate a simple diversification score for the portfolio.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///
  /// Returns:
  ///   A record of (score, recommendation)
  static DiversificationResult getDiversificationScore(Portfolio portfolio) {
    final numHoldings = portfolio.holdings.length;
    
    if (numHoldings == 0) {
      return DiversificationResult(
        0.0,
        'No holdings. Cannot assess diversification.'
      );
    }
    
    if (numHoldings == 1) {
      return DiversificationResult(
        20.0,
        'Poor diversification. Consider adding more stocks.'
      );
    } else if (numHoldings <= 3) {
      return DiversificationResult(
        40.0,
        'Low diversification. Consider adding more stocks.'
      );
    } else if (numHoldings <= 7) {
      return DiversificationResult(
        70.0,
        'Moderate diversification. Good balance.'
      );
    } else if (numHoldings <= 15) {
      return DiversificationResult(
        90.0,
        'Good diversification.'
      );
    } else {
      return DiversificationResult(
        85.0,
        'High diversification. May be difficult to manage.'
      );
    }
  }
  
  /// Generate actionable recommendations for the portfolio.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///
  /// Returns:
  ///   List of recommendation strings
  static List<String> generateRecommendations(Portfolio portfolio) {
    final recommendations = <String>[];
    
    if (portfolio.holdings.isEmpty) {
      recommendations.add('Start building your portfolio by adding stocks.');
      return recommendations;
    }
    
    // Check overall performance
    if (portfolio.totalGainLossPercent < -10) {
      recommendations.add(
        'Portfolio is down significantly. Review individual holdings for potential exits.'
      );
    } else if (portfolio.totalGainLossPercent > 20) {
      recommendations.add(
        'Portfolio is performing well. Consider taking some profits.'
      );
    }
    
    // Check diversification
    final divResult = getDiversificationScore(portfolio);
    if (divResult.score < 50) {
      recommendations.add(
        'Diversify your portfolio by adding stocks from different sectors.'
      );
    }
    
    // Check for individual stock risks
    final highPerformers = identifyHighPerformers(portfolio, threshold: 30.0);
    if (highPerformers.isNotEmpty) {
      final symbols = highPerformers.map((s) => s.symbol).join(', ');
      recommendations.add(
        'Consider taking profits on high performers: $symbols'
      );
    }
    
    final underperformers = identifyUnderperformers(portfolio, threshold: -15.0);
    if (underperformers.isNotEmpty) {
      final symbols = underperformers.map((s) => s.symbol).join(', ');
      recommendations.add(
        'Review underperforming stocks for potential exit: $symbols'
      );
    }
    
    return recommendations;
  }
}

/// Result of diversification analysis
class DiversificationResult {
  final double score;
  final String recommendation;

  DiversificationResult(this.score, this.recommendation);
}

/// Extension methods for multi-account analysis.
extension MultiAccountAnalyzer on InvestmentAnalyzer {
  /// Analyze multiple accounts and provide aggregate insights.
  ///
  /// Args:
  ///   accounts: List of accounts to analyze
  ///
  /// Returns:
  ///   Map with aggregate analysis results
  static Map<String, dynamic> analyzeAccounts(List<Account> accounts) {
    if (accounts.isEmpty) {
      return {
        'status': 'empty',
        'message': 'No accounts to analyze.',
      };
    }

    double totalValue = 0;
    double totalCost = 0;
    final allHoldings = <Stock>[];
    final accountSummaries = <Map<String, dynamic>>[];

    for (final account in accounts) {
      totalValue += account.totalValue;
      totalCost += account.totalCost;
      allHoldings.addAll(account.holdings);
      accountSummaries.add(account.getSummary());
    }

    final totalGainLoss = totalValue - totalCost;
    final totalGainLossPercent = totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0.0;

    // Get unique symbols
    final symbolValues = <String, double>{};
    for (final stock in allHoldings) {
      symbolValues[stock.symbol] = (symbolValues[stock.symbol] ?? 0) + stock.currentValue;
    }

    // Find largest positions
    final sortedPositions = symbolValues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'status': 'analyzed',
      'numAccounts': accounts.length,
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGainLoss': totalGainLoss,
      'totalGainLossPercent': totalGainLossPercent,
      'uniqueSymbols': symbolValues.length,
      'totalHoldings': allHoldings.length,
      'largestPositions': sortedPositions.take(5).map((e) => {
        'symbol': e.key,
        'value': e.value,
        'allocation': (e.value / totalValue) * 100,
      }).toList(),
      'accountSummaries': accountSummaries,
    };
  }

  /// Get aggregate allocation across all accounts.
  ///
  /// Args:
  ///   accounts: List of accounts
  ///
  /// Returns:
  ///   Map of symbol to allocation percentage
  static Map<String, double> getAggregateAllocation(List<Account> accounts) {
    if (accounts.isEmpty) return {};

    double totalValue = 0;
    final symbolValues = <String, double>{};

    for (final account in accounts) {
      for (final stock in account.holdings) {
        symbolValues[stock.symbol] = (symbolValues[stock.symbol] ?? 0) + stock.currentValue;
        totalValue += stock.currentValue;
      }
    }

    if (totalValue == 0) return {};

    return symbolValues.map((symbol, value) => MapEntry(symbol, (value / totalValue) * 100));
  }

  /// Get allocation by account type.
  ///
  /// Args:
  ///   accounts: List of accounts
  ///
  /// Returns:
  ///   Map of account type to allocation percentage
  static Map<String, double> getAllocationByAccountType(List<Account> accounts) {
    if (accounts.isEmpty) return {};

    double totalValue = 0;
    final typeValues = <AccountType, double>{};

    for (final account in accounts) {
      typeValues[account.type] = (typeValues[account.type] ?? 0) + account.totalValue;
      totalValue += account.totalValue;
    }

    if (totalValue == 0) return {};

    return typeValues.map((type, value) => MapEntry(type.name, (value / totalValue) * 100));
  }

  /// Calculate total return including dividends.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///   dividends: Dividend tracker with dividend history
  ///
  /// Returns:
  ///   Total return percentage including dividends
  static double calculateTotalReturn({
    required Portfolio portfolio,
    required DividendTracker dividends,
  }) {
    final totalCost = portfolio.totalCost;
    if (totalCost <= 0) return 0;

    // Capital gains
    final capitalGains = portfolio.totalGainLoss;

    // Dividend income (use total dividends for all symbols in portfolio)
    double dividendIncome = 0;
    for (final stock in portfolio.holdings) {
      dividendIncome += dividends.getTotalDividends(stock.symbol);
    }

    // Total return = (Capital Gains + Dividends) / Cost
    return ((capitalGains + dividendIncome) / totalCost) * 100;
  }

  /// Calculate yield on cost for portfolio.
  ///
  /// Args:
  ///   portfolio: Portfolio to analyze
  ///   dividends: Dividend tracker with dividend history
  ///
  /// Returns:
  ///   Map with yield metrics
  static Map<String, dynamic> calculateYieldMetrics({
    required Portfolio portfolio,
    required DividendTracker dividends,
  }) {
    final totalCost = portfolio.totalCost;
    final symbolYields = <String, double>{};
    double totalAnnualDividends = 0;

    for (final stock in portfolio.holdings) {
      final yoc = dividends.getYieldOnCost(stock.symbol, stock.totalCost);
      symbolYields[stock.symbol] = yoc;

      // Estimate annual dividends based on last 12 months
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      final recentDividends = dividends.getBySymbol(stock.symbol)
          .where((d) => d.payDate.isAfter(oneYearAgo))
          .fold<double>(0.0, (sum, d) => sum + d.amount);
      totalAnnualDividends += recentDividends;
    }

    return {
      'portfolioYieldOnCost': totalCost > 0 ? (totalAnnualDividends / totalCost) * 100 : 0,
      'estimatedAnnualIncome': totalAnnualDividends,
      'symbolYields': symbolYields,
    };
  }

  /// Generate recommendations considering multiple accounts.
  ///
  /// Args:
  ///   accounts: List of accounts to analyze
  ///
  /// Returns:
  ///   List of recommendation strings
  static List<String> generateMultiAccountRecommendations(List<Account> accounts) {
    final recommendations = <String>[];

    if (accounts.isEmpty) {
      recommendations.add('Create an account to start tracking investments.');
      return recommendations;
    }

    // Check for account type diversity
    final accountTypes = accounts.map((a) => a.type).toSet();
    if (!accountTypes.contains(AccountType.retirement)) {
      recommendations.add(
        'Consider opening a retirement account for tax-advantaged investing.',
      );
    }

    // Analyze aggregate holdings
    final aggregateAllocation = getAggregateAllocation(accounts);

    // Check for concentration risk
    for (final entry in aggregateAllocation.entries) {
      if (entry.value > 25) {
        recommendations.add(
          '${entry.key} represents ${entry.value.toStringAsFixed(1)}% of total portfolio. Consider rebalancing to reduce concentration.',
        );
      }
    }

    // Check each account
    for (final account in accounts) {
      if (account.holdings.isEmpty) {
        recommendations.add(
          'Account "${account.name}" has no holdings. Consider adding investments.',
        );
      }

      // Check for tax-advantaged accounts with tax-inefficient investments
      if (account.isTaxAdvantaged) {
        final analysis = InvestmentAnalyzer.analyzePortfolio(account.portfolio);
        if (analysis['status'] == 'analyzed') {
          final gainLossPercent = account.totalGainLossPercent;
          if (gainLossPercent > 50) {
            recommendations.add(
              'Tax-advantaged account "${account.name}" has significant gains. This is efficient tax placement.',
            );
          }
        }
      }
    }

    // Overall performance check
    final totalValue = accounts.fold<double>(0.0, (sum, a) => sum + a.totalValue);
    final totalCost = accounts.fold<double>(0.0, (sum, a) => sum + a.totalCost);
    final overallGainLossPercent = totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0;

    if (overallGainLossPercent < -10) {
      recommendations.add(
        'Overall portfolio is down ${overallGainLossPercent.abs().toStringAsFixed(1)}%. Review holdings and consider tax-loss harvesting opportunities.',
      );
    } else if (overallGainLossPercent > 30) {
      recommendations.add(
        'Overall portfolio is up ${overallGainLossPercent.toStringAsFixed(1)}%. Consider rebalancing to lock in gains.',
      );
    }

    return recommendations;
  }
}
