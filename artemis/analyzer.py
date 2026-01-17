"""Investment analysis and guidance to maximize returns."""

from typing import List, Dict, Tuple
from .portfolio import Portfolio
from .stock import Stock


class InvestmentAnalyzer:
    """Provides analysis and guidance for investment portfolios."""
    
    @staticmethod
    def analyze_portfolio(portfolio: Portfolio) -> Dict:
        """
        Analyze a portfolio and provide insights.
        
        Args:
            portfolio: Portfolio to analyze
            
        Returns:
            Dictionary with analysis results
        """
        holdings = portfolio.holdings
        
        if not holdings:
            return {
                "status": "empty",
                "message": "Portfolio is empty. No analysis available."
            }
        
        # Calculate metrics
        winners = [s for s in holdings if s.gain_loss > 0]
        losers = [s for s in holdings if s.gain_loss < 0]
        
        best_performer = max(holdings, key=lambda s: s.gain_loss_percent)
        worst_performer = min(holdings, key=lambda s: s.gain_loss_percent)
        
        return {
            "status": "analyzed",
            "summary": portfolio.get_summary(),
            "winners": len(winners),
            "losers": len(losers),
            "best_performer": {
                "symbol": best_performer.symbol,
                "gain_loss_percent": best_performer.gain_loss_percent
            },
            "worst_performer": {
                "symbol": worst_performer.symbol,
                "gain_loss_percent": worst_performer.gain_loss_percent
            }
        }
    
    @staticmethod
    def get_rebalancing_suggestions(portfolio: Portfolio, target_allocation: Dict[str, float] = None) -> List[Dict]:
        """
        Get suggestions for rebalancing the portfolio.
        
        Args:
            portfolio: Portfolio to analyze
            target_allocation: Optional dict of {symbol: target_percent}
            
        Returns:
            List of rebalancing suggestions
        """
        suggestions = []
        total_value = portfolio.total_value
        
        if total_value == 0:
            return [{"message": "Portfolio has no value. Cannot provide rebalancing suggestions."}]
        
        for stock in portfolio.holdings:
            current_allocation = (stock.current_value / total_value) * 100
            
            if target_allocation and stock.symbol in target_allocation:
                target = target_allocation[stock.symbol]
                diff = current_allocation - target
                
                if abs(diff) > 5:  # Significant deviation (>5%)
                    action = "reduce" if diff > 0 else "increase"
                    suggestions.append({
                        "symbol": stock.symbol,
                        "action": action,
                        "current_allocation": current_allocation,
                        "target_allocation": target,
                        "difference": abs(diff)
                    })
            else:
                # Provide general allocation info
                suggestions.append({
                    "symbol": stock.symbol,
                    "current_allocation": current_allocation
                })
        
        return suggestions
    
    @staticmethod
    def identify_high_performers(portfolio: Portfolio, threshold: float = 20.0) -> List[Stock]:
        """
        Identify stocks that have exceeded a performance threshold.
        
        Args:
            portfolio: Portfolio to analyze
            threshold: Minimum gain percentage to be considered high performer
            
        Returns:
            List of high-performing stocks
        """
        return [
            stock for stock in portfolio.holdings
            if stock.gain_loss_percent >= threshold
        ]
    
    @staticmethod
    def identify_underperformers(portfolio: Portfolio, threshold: float = -10.0) -> List[Stock]:
        """
        Identify stocks that have fallen below a performance threshold.
        
        Args:
            portfolio: Portfolio to analyze
            threshold: Maximum loss percentage to be considered underperformer
            
        Returns:
            List of underperforming stocks
        """
        return [
            stock for stock in portfolio.holdings
            if stock.gain_loss_percent <= threshold
        ]
    
    @staticmethod
    def get_diversification_score(portfolio: Portfolio) -> Tuple[float, str]:
        """
        Calculate a simple diversification score for the portfolio.
        
        Args:
            portfolio: Portfolio to analyze
            
        Returns:
            Tuple of (score, recommendation)
        """
        num_holdings = len(portfolio.holdings)
        
        if num_holdings == 0:
            return 0.0, "No holdings. Cannot assess diversification."
        
        if num_holdings == 1:
            return 20.0, "Poor diversification. Consider adding more stocks."
        elif num_holdings <= 3:
            return 40.0, "Low diversification. Consider adding more stocks."
        elif num_holdings <= 7:
            return 70.0, "Moderate diversification. Good balance."
        elif num_holdings <= 15:
            return 90.0, "Good diversification."
        else:
            return 85.0, "High diversification. May be difficult to manage."
    
    @staticmethod
    def generate_recommendations(portfolio: Portfolio) -> List[str]:
        """
        Generate actionable recommendations for the portfolio.
        
        Args:
            portfolio: Portfolio to analyze
            
        Returns:
            List of recommendation strings
        """
        recommendations = []
        
        if not portfolio.holdings:
            recommendations.append("Start building your portfolio by adding stocks.")
            return recommendations
        
        # Check overall performance
        if portfolio.total_gain_loss_percent < -10:
            recommendations.append("Portfolio is down significantly. Review individual holdings for potential exits.")
        elif portfolio.total_gain_loss_percent > 20:
            recommendations.append("Portfolio is performing well. Consider taking some profits.")
        
        # Check diversification
        score, _ = InvestmentAnalyzer.get_diversification_score(portfolio)
        if score < 50:
            recommendations.append("Diversify your portfolio by adding stocks from different sectors.")
        
        # Check for individual stock risks
        high_performers = InvestmentAnalyzer.identify_high_performers(portfolio, 30.0)
        if high_performers:
            symbols = [s.symbol for s in high_performers]
            recommendations.append(f"Consider taking profits on high performers: {', '.join(symbols)}")
        
        underperformers = InvestmentAnalyzer.identify_underperformers(portfolio, -15.0)
        if underperformers:
            symbols = [s.symbol for s in underperformers]
            recommendations.append(f"Review underperforming stocks for potential exit: {', '.join(symbols)}")
        
        return recommendations
