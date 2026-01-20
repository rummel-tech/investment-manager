# Investment Manager Architecture

## Overview

The Investment Manager is a Python application for portfolio tracking, asset allocation, and rebalancing suggestions.

## System Components

```
┌─────────────────────┐
│ Investment Manager  │
│   (Python CLI)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   SQLite Database   │
└─────────────────────┘
```

## Project Structure

```
investment-manager/
├── src/
│   ├── models/             # Data models
│   ├── services/           # Business logic
│   └── utils/              # Utilities
├── tests/                  # Pytest suite
├── requirements.txt        # Dependencies
└── README.md
```

## Data Models

### Account
- id, name, type (brokerage/retirement/savings)
- institution, holdings

### Holding
- id, account_id, symbol
- shares, cost_basis
- current_price, current_value

### AssetAllocation
- asset_class, target_percentage
- current_percentage, difference

## Services

### PortfolioService
- Aggregate holdings across accounts
- Calculate total portfolio value
- Track performance over time

### AllocationService
- Define target allocation
- Calculate current allocation
- Identify drift from targets

### RebalancingService
- Suggest trades to rebalance
- Consider tax implications
- Minimize transaction costs

## Future Enhancements

- Flutter frontend for cross-platform UI
- FastAPI backend for web access
- External data provider integrations
- Automated price updates
- Tax-loss harvesting suggestions

## Related Documentation

- [Module README](../README.md)
- [Platform Architecture](../../../../docs/ARCHITECTURE.md)

---

[Back to Module](../) | [Platform Documentation](../../../../docs/)
