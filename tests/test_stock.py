"""Unit tests for the Stock class."""

import unittest
from datetime import datetime
from artemis.stock import Stock


class TestStock(unittest.TestCase):
    """Test cases for Stock class."""
    
    def test_stock_initialization(self):
        """Test basic stock initialization."""
        stock = Stock("AAPL", 10, 150.0)
        self.assertEqual(stock.symbol, "AAPL")
        self.assertEqual(stock.shares, 10)
        self.assertEqual(stock.purchase_price, 150.0)
        self.assertEqual(stock.current_price, 150.0)
    
    def test_stock_symbol_uppercase(self):
        """Test that stock symbol is converted to uppercase."""
        stock = Stock("aapl", 10, 150.0)
        self.assertEqual(stock.symbol, "AAPL")
    
    def test_total_cost(self):
        """Test total cost calculation."""
        stock = Stock("GOOGL", 5, 2800.0)
        self.assertEqual(stock.total_cost, 14000.0)
    
    def test_current_value(self):
        """Test current value calculation."""
        stock = Stock("MSFT", 20, 300.0, current_price=350.0)
        self.assertEqual(stock.current_value, 7000.0)
    
    def test_gain_loss(self):
        """Test gain/loss calculation."""
        stock = Stock("TSLA", 10, 700.0, current_price=800.0)
        self.assertEqual(stock.gain_loss, 1000.0)
        
        stock2 = Stock("NFLX", 5, 500.0, current_price=450.0)
        self.assertEqual(stock2.gain_loss, -250.0)
    
    def test_gain_loss_percent(self):
        """Test gain/loss percentage calculation."""
        stock = Stock("AMZN", 10, 3000.0, current_price=3300.0)
        self.assertEqual(stock.gain_loss_percent, 10.0)
        
        stock2 = Stock("FB", 20, 350.0, current_price=315.0)
        self.assertEqual(stock2.gain_loss_percent, -10.0)
    
    def test_gain_loss_percent_zero_cost(self):
        """Test gain/loss percentage with zero cost."""
        stock = Stock("TEST", 10, 0.0)
        self.assertEqual(stock.gain_loss_percent, 0.0)
    
    def test_update_price(self):
        """Test price update functionality."""
        stock = Stock("NVDA", 15, 500.0)
        stock.update_price(600.0)
        self.assertEqual(stock.current_price, 600.0)
        self.assertEqual(stock.gain_loss, 1500.0)
    
    def test_repr(self):
        """Test string representation."""
        stock = Stock("AMD", 25, 100.0)
        repr_str = repr(stock)
        self.assertIn("AMD", repr_str)
        self.assertIn("25", repr_str)
    
    def test_str(self):
        """Test string conversion."""
        stock = Stock("INTC", 30, 50.0, current_price=55.0)
        str_repr = str(stock)
        self.assertIn("INTC", str_repr)
        self.assertIn("30", str_repr)


if __name__ == '__main__':
    unittest.main()
