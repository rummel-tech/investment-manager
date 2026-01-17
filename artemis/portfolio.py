"""Portfolio management for tracking multiple stock holdings."""

from typing import Dict, List, Optional
from .stock import Stock


class Portfolio:
    """Manages a collection of stock holdings."""
    
    def __init__(self, name: str = "My Portfolio"):
        """
        Initialize a portfolio.
        
        Args:
            name: Name of the portfolio
        """
        self.name = name
        self._holdings: Dict[str, Stock] = {}
    
    def add_stock(self, stock: Stock) -> None:
        """
        Add a stock to the portfolio.
        
        Args:
            stock: Stock instance to add
        """
        symbol = stock.symbol
        if symbol in self._holdings:
            # Merge with existing holding (average cost basis)
            existing = self._holdings[symbol]
            total_shares = existing.shares + stock.shares
            total_cost = existing.total_cost + stock.total_cost
            new_avg_price = total_cost / total_shares
            
            existing.shares = total_shares
            existing.purchase_price = new_avg_price
            existing.current_price = stock.current_price
        else:
            self._holdings[symbol] = stock
    
    def remove_stock(self, symbol: str) -> Optional[Stock]:
        """
        Remove a stock from the portfolio.
        
        Args:
            symbol: Stock ticker symbol
            
        Returns:
            Removed stock or None if not found
        """
        return self._holdings.pop(symbol.upper(), None)
    
    def get_stock(self, symbol: str) -> Optional[Stock]:
        """
        Get a stock from the portfolio.
        
        Args:
            symbol: Stock ticker symbol
            
        Returns:
            Stock instance or None if not found
        """
        return self._holdings.get(symbol.upper())
    
    def update_stock_price(self, symbol: str, new_price: float) -> bool:
        """
        Update the current price of a stock.
        
        Args:
            symbol: Stock ticker symbol
            new_price: New current price
            
        Returns:
            True if updated, False if stock not found
        """
        stock = self.get_stock(symbol)
        if stock:
            stock.update_price(new_price)
            return True
        return False
    
    @property
    def holdings(self) -> List[Stock]:
        """Get all stocks in the portfolio."""
        return list(self._holdings.values())
    
    @property
    def total_value(self) -> float:
        """Calculate total current value of portfolio."""
        return sum(stock.current_value for stock in self._holdings.values())
    
    @property
    def total_cost(self) -> float:
        """Calculate total cost basis of portfolio."""
        return sum(stock.total_cost for stock in self._holdings.values())
    
    @property
    def total_gain_loss(self) -> float:
        """Calculate total gain/loss in dollars."""
        return self.total_value - self.total_cost
    
    @property
    def total_gain_loss_percent(self) -> float:
        """Calculate total gain/loss as a percentage."""
        if self.total_cost == 0:
            return 0.0
        return (self.total_gain_loss / self.total_cost) * 100
    
    def get_summary(self) -> Dict:
        """
        Get a summary of the portfolio.
        
        Returns:
            Dictionary with portfolio summary statistics
        """
        return {
            "name": self.name,
            "num_holdings": len(self._holdings),
            "total_value": self.total_value,
            "total_cost": self.total_cost,
            "total_gain_loss": self.total_gain_loss,
            "total_gain_loss_percent": self.total_gain_loss_percent
        }
    
    def __repr__(self) -> str:
        return f"Portfolio(name='{self.name}', holdings={len(self._holdings)})"
    
    def __str__(self) -> str:
        return f"{self.name}: {len(self._holdings)} stocks, ${self.total_value:.2f} value"
