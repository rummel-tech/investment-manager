/// Investment analysis and guidance to maximize returns.
library analyzer;

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
