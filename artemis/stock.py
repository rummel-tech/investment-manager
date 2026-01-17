"""Stock representation and management."""

from typing import Optional
from datetime import datetime


class Stock:
    """Represents a stock holding."""
    
    def __init__(
        self,
        symbol: str,
        shares: float,
        purchase_price: float,
        current_price: Optional[float] = None,
        purchase_date: Optional[datetime] = None
    ):
        """
        Initialize a stock holding.
        
        Args:
            symbol: Stock ticker symbol (e.g., 'AAPL', 'GOOGL')
            shares: Number of shares owned
            purchase_price: Price per share at purchase
            current_price: Current price per share (defaults to purchase_price)
            purchase_date: Date of purchase (defaults to now)
        """
        self.symbol = symbol.upper()
        self.shares = shares
        self.purchase_price = purchase_price
        self.current_price = current_price if current_price is not None else purchase_price
        self.purchase_date = purchase_date if purchase_date is not None else datetime.now()
    
    @property
    def total_cost(self) -> float:
        """Calculate total cost basis."""
        return self.shares * self.purchase_price
    
    @property
    def current_value(self) -> float:
        """Calculate current market value."""
        return self.shares * self.current_price
    
    @property
    def gain_loss(self) -> float:
        """Calculate gain or loss in dollars."""
        return self.current_value - self.total_cost
    
    @property
    def gain_loss_percent(self) -> float:
        """Calculate gain or loss as a percentage."""
        if self.total_cost == 0:
            return 0.0
        return (self.gain_loss / self.total_cost) * 100
    
    def update_price(self, new_price: float) -> None:
        """Update the current price of the stock."""
        self.current_price = new_price
    
    def __repr__(self) -> str:
        return f"Stock(symbol='{self.symbol}', shares={self.shares}, current_price={self.current_price})"
    
    def __str__(self) -> str:
        return f"{self.symbol}: {self.shares} shares @ ${self.current_price:.2f}"
