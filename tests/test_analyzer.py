"""Unit tests for the InvestmentAnalyzer class."""

import unittest
from artemis.stock import Stock
from artemis.portfolio import Portfolio
from artemis.analyzer import InvestmentAnalyzer


class TestInvestmentAnalyzer(unittest.TestCase):
    """Test cases for InvestmentAnalyzer class."""
    
    def test_analyze_empty_portfolio(self):
        """Test analyzing an empty portfolio."""
        portfolio = Portfolio()
        analysis = InvestmentAnalyzer.analyze_portfolio(portfolio)
        
        self.assertEqual(analysis["status"], "empty")
    
    def test_analyze_portfolio_with_holdings(self):
        """Test analyzing a portfolio with holdings."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
        portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2700.0))
        
        analysis = InvestmentAnalyzer.analyze_portfolio(portfolio)
        
        self.assertEqual(analysis["status"], "analyzed")
        self.assertEqual(analysis["winners"], 1)  # AAPL
        self.assertEqual(analysis["losers"], 1)   # GOOGL
        self.assertEqual(analysis["best_performer"]["symbol"], "AAPL")
        self.assertEqual(analysis["worst_performer"]["symbol"], "GOOGL")
    
    def test_identify_high_performers(self):
        """Test identifying high-performing stocks."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 100.0, current_price=130.0))  # 30% gain
        portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2900.0))  # ~3.6% gain
        
        high_performers = InvestmentAnalyzer.identify_high_performers(portfolio, 20.0)
        
        self.assertEqual(len(high_performers), 1)
        self.assertEqual(high_performers[0].symbol, "AAPL")
    
    def test_identify_underperformers(self):
        """Test identifying underperforming stocks."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))  # 6.67% gain
        portfolio.add_stock(Stock("NFLX", 5, 500.0, current_price=400.0))  # -20% loss
        
        underperformers = InvestmentAnalyzer.identify_underperformers(portfolio, -10.0)
        
        self.assertEqual(len(underperformers), 1)
        self.assertEqual(underperformers[0].symbol, "NFLX")
    
    def test_get_diversification_score_empty(self):
        """Test diversification score for empty portfolio."""
        portfolio = Portfolio()
        score, recommendation = InvestmentAnalyzer.get_diversification_score(portfolio)
        
        self.assertEqual(score, 0.0)
        self.assertIn("No holdings", recommendation)
    
    def test_get_diversification_score_one_stock(self):
        """Test diversification score for single stock."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0))
        
        score, recommendation = InvestmentAnalyzer.get_diversification_score(portfolio)
        
        self.assertEqual(score, 20.0)
        self.assertIn("Poor", recommendation)
    
    def test_get_diversification_score_moderate(self):
        """Test diversification score for moderate holdings."""
        portfolio = Portfolio()
        for i, symbol in enumerate(["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]):
            portfolio.add_stock(Stock(symbol, 10, 100.0))
        
        score, recommendation = InvestmentAnalyzer.get_diversification_score(portfolio)
        
        self.assertEqual(score, 70.0)
        self.assertIn("Moderate", recommendation)
    
    def test_get_rebalancing_suggestions_empty(self):
        """Test rebalancing suggestions for empty portfolio."""
        portfolio = Portfolio()
        suggestions = InvestmentAnalyzer.get_rebalancing_suggestions(portfolio)
        
        self.assertEqual(len(suggestions), 1)
        self.assertIn("no value", suggestions[0]["message"])
    
    def test_get_rebalancing_suggestions_with_target(self):
        """Test rebalancing suggestions with target allocation."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 100.0, current_price=200.0))  # $2000
        portfolio.add_stock(Stock("GOOGL", 5, 100.0, current_price=100.0))  # $500
        # Total: $2500, AAPL: 80%, GOOGL: 20%
        
        target = {"AAPL": 50.0, "GOOGL": 50.0}
        suggestions = InvestmentAnalyzer.get_rebalancing_suggestions(portfolio, target)
        
        # AAPL should have reduce suggestion (80% vs 50%)
        aapl_suggestion = next(s for s in suggestions if s["symbol"] == "AAPL")
        self.assertEqual(aapl_suggestion["action"], "reduce")
        
        # GOOGL should have increase suggestion (20% vs 50%)
        googl_suggestion = next(s for s in suggestions if s["symbol"] == "GOOGL")
        self.assertEqual(googl_suggestion["action"], "increase")
    
    def test_generate_recommendations_empty_portfolio(self):
        """Test recommendations for empty portfolio."""
        portfolio = Portfolio()
        recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
        
        self.assertEqual(len(recommendations), 1)
        self.assertIn("Start building", recommendations[0])
    
    def test_generate_recommendations_losing_portfolio(self):
        """Test recommendations for losing portfolio."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=100.0))  # -33%
        
        recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
        
        # Should recommend reviewing holdings
        self.assertTrue(any("down significantly" in r for r in recommendations))
    
    def test_generate_recommendations_winning_portfolio(self):
        """Test recommendations for winning portfolio."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 100.0, current_price=130.0))  # 30%
        
        recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
        
        # Should recommend taking profits
        self.assertTrue(any("performing well" in r or "profits" in r for r in recommendations))
    
    def test_generate_recommendations_diversification(self):
        """Test diversification recommendations."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0))
        
        recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
        
        # Should recommend diversifying (only 1 stock)
        self.assertTrue(any("Diversify" in r for r in recommendations))
    
    def test_generate_recommendations_high_performers(self):
        """Test recommendations for high performers."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 100.0, current_price=150.0))  # 50%
        portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2850.0))  # ~1.8%
        
        recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
        
        # Should recommend taking profits on AAPL
        self.assertTrue(any("high performers" in r and "AAPL" in r for r in recommendations))
    
    def test_generate_recommendations_underperformers(self):
        """Test recommendations for underperformers."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
        portfolio.add_stock(Stock("NFLX", 5, 500.0, current_price=400.0))  # -20%
        
        recommendations = InvestmentAnalyzer.generate_recommendations(portfolio)
        
        # Should recommend reviewing NFLX
        self.assertTrue(any("underperforming" in r and "NFLX" in r for r in recommendations))


if __name__ == '__main__':
    unittest.main()
