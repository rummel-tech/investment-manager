"""Unit tests for the Portfolio class."""

import unittest
from artemis.stock import Stock
from artemis.portfolio import Portfolio


class TestPortfolio(unittest.TestCase):
    """Test cases for Portfolio class."""
    
    def test_portfolio_initialization(self):
        """Test basic portfolio initialization."""
        portfolio = Portfolio("Test Portfolio")
        self.assertEqual(portfolio.name, "Test Portfolio")
        self.assertEqual(len(portfolio.holdings), 0)
    
    def test_add_stock(self):
        """Test adding a stock to portfolio."""
        portfolio = Portfolio()
        stock = Stock("AAPL", 10, 150.0)
        portfolio.add_stock(stock)
        
        self.assertEqual(len(portfolio.holdings), 1)
        self.assertEqual(portfolio.get_stock("AAPL").shares, 10)
    
    def test_add_duplicate_stock_merges(self):
        """Test that adding duplicate stock merges holdings."""
        portfolio = Portfolio()
        stock1 = Stock("AAPL", 10, 150.0)
        stock2 = Stock("AAPL", 5, 160.0, current_price=165.0)
        
        portfolio.add_stock(stock1)
        portfolio.add_stock(stock2)
        
        self.assertEqual(len(portfolio.holdings), 1)
        merged = portfolio.get_stock("AAPL")
        self.assertEqual(merged.shares, 15)
        # Average price: (10*150 + 5*160) / 15 = 2300/15 = 153.33...
        self.assertAlmostEqual(merged.purchase_price, 153.33, places=2)
        self.assertEqual(merged.current_price, 165.0)
    
    def test_remove_stock(self):
        """Test removing a stock from portfolio."""
        portfolio = Portfolio()
        stock = Stock("GOOGL", 5, 2800.0)
        portfolio.add_stock(stock)
        
        removed = portfolio.remove_stock("GOOGL")
        self.assertIsNotNone(removed)
        self.assertEqual(removed.symbol, "GOOGL")
        self.assertEqual(len(portfolio.holdings), 0)
    
    def test_remove_nonexistent_stock(self):
        """Test removing a stock that doesn't exist."""
        portfolio = Portfolio()
        removed = portfolio.remove_stock("INVALID")
        self.assertIsNone(removed)
    
    def test_get_stock(self):
        """Test retrieving a stock from portfolio."""
        portfolio = Portfolio()
        stock = Stock("MSFT", 20, 300.0)
        portfolio.add_stock(stock)
        
        retrieved = portfolio.get_stock("MSFT")
        self.assertIsNotNone(retrieved)
        self.assertEqual(retrieved.symbol, "MSFT")
    
    def test_get_nonexistent_stock(self):
        """Test retrieving a stock that doesn't exist."""
        portfolio = Portfolio()
        retrieved = portfolio.get_stock("INVALID")
        self.assertIsNone(retrieved)
    
    def test_update_stock_price(self):
        """Test updating stock price in portfolio."""
        portfolio = Portfolio()
        stock = Stock("TSLA", 10, 700.0)
        portfolio.add_stock(stock)
        
        result = portfolio.update_stock_price("TSLA", 800.0)
        self.assertTrue(result)
        self.assertEqual(portfolio.get_stock("TSLA").current_price, 800.0)
    
    def test_update_nonexistent_stock_price(self):
        """Test updating price of non-existent stock."""
        portfolio = Portfolio()
        result = portfolio.update_stock_price("INVALID", 100.0)
        self.assertFalse(result)
    
    def test_total_value(self):
        """Test total portfolio value calculation."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
        portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2900.0))
        
        # 10*160 + 5*2900 = 1600 + 14500 = 16100
        self.assertEqual(portfolio.total_value, 16100.0)
    
    def test_total_cost(self):
        """Test total cost basis calculation."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0))
        portfolio.add_stock(Stock("GOOGL", 5, 2800.0))
        
        # 10*150 + 5*2800 = 1500 + 14000 = 15500
        self.assertEqual(portfolio.total_cost, 15500.0)
    
    def test_total_gain_loss(self):
        """Test total gain/loss calculation."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
        portfolio.add_stock(Stock("GOOGL", 5, 2800.0, current_price=2700.0))
        
        # Value: 1600 + 13500 = 15100
        # Cost: 1500 + 14000 = 15500
        # Gain/Loss: -400
        self.assertEqual(portfolio.total_gain_loss, -400.0)
    
    def test_total_gain_loss_percent(self):
        """Test total gain/loss percentage calculation."""
        portfolio = Portfolio()
        portfolio.add_stock(Stock("AAPL", 10, 100.0, current_price=110.0))
        
        # Cost: 1000, Value: 1100, Gain: 100, Percent: 10%
        self.assertEqual(portfolio.total_gain_loss_percent, 10.0)
    
    def test_get_summary(self):
        """Test portfolio summary generation."""
        portfolio = Portfolio("My Test Portfolio")
        portfolio.add_stock(Stock("AAPL", 10, 150.0, current_price=160.0))
        
        summary = portfolio.get_summary()
        self.assertEqual(summary["name"], "My Test Portfolio")
        self.assertEqual(summary["num_holdings"], 1)
        self.assertEqual(summary["total_value"], 1600.0)
        self.assertEqual(summary["total_cost"], 1500.0)
        self.assertEqual(summary["total_gain_loss"], 100.0)
    
    def test_repr(self):
        """Test string representation."""
        portfolio = Portfolio("Test")
        repr_str = repr(portfolio)
        self.assertIn("Test", repr_str)
    
    def test_str(self):
        """Test string conversion."""
        portfolio = Portfolio("My Portfolio")
        portfolio.add_stock(Stock("AAPL", 10, 150.0))
        str_repr = str(portfolio)
        self.assertIn("My Portfolio", str_repr)


if __name__ == '__main__':
    unittest.main()
