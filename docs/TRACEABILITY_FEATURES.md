# Investment Manager — Feature Traceability Matrix

Maps each user-facing feature from OBJECTIVES.md through specification, tests, implementation, and release verification.

---

## Traceability Chain

```
OBJECTIVES.md (product description)
    → docs/SPECIFICATION.md / docs/ARCHITECTURE.md (specification)
    → docs/WORKFLOWS.md (primary user journeys and screen map)
        → test/*.dart — model and service unit tests
        → integration_test/app_test.dart — end-to-end workflow tests
            → Source implementation
                → docs/DEPLOYMENT.md smoke test (release gate)
```

---

## Development Status Note

Investment Manager core models (Portfolio, Account, Stock, Analyzer, Tax) are implemented and unit-tested. Flutter UI screens exist but have no widget tests. Backend API and price feed integration are planned.

---

## FR-1 · Account Management

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-1.1 | Create investment accounts (brokerage, retirement, etc.) | OBJECTIVES.md FR-1.1 | `account_test` — "addAccount and getAccount", "isTaxAdvantaged only for retirement" | `lib/src/account.dart` · `lib/src/repository.dart` | — |
| FR-1.2 | Track multiple accounts per user | OBJECTIVES.md FR-1.2 | `account_test` — "addAccount and getAccount", "removeAccount", "getByType filters correctly", "getAggregateView sums across accounts" | `lib/src/repository.dart` · `lib/src/ui/screens/dashboard_screen.dart` | — |
| FR-1.3 | Account-level summaries | OBJECTIVES.md FR-1.3 | `portfolio_test` — "getSummary returns expected keys" | `lib/src/portfolio.dart` · `lib/src/account.dart` | — |
| FR-1.4 | Aggregate portfolio view across accounts | OBJECTIVES.md FR-1.4 | `account_test` — "getAggregateView sums across accounts", "getAllocationByType returns percentages" | `lib/src/repository.dart` · `lib/src/ui/screens/dashboard_screen.dart` | Portfolio view loads |
| FR-1.5 | Account JSON round-trip | OBJECTIVES.md FR-1.1 | `account_test` — "JSON round-trip" | `lib/src/account.dart` | — |

---

## FR-2 · Holdings

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-2.1 | Add holdings with symbol, shares, cost basis | OBJECTIVES.md FR-2.1 | `portfolio_test` — "buyStock adds to portfolio and records transaction" · `stock_test` — "construction with defaults" | `lib/src/portfolio.dart` · `lib/src/stock.dart` · `lib/src/ui/screens/add_stock_screen.dart` | — |
| FR-2.2 | Update current prices | OBJECTIVES.md FR-2.2 | None — gap (price service planned) | `lib/src/price_service.dart` | — |
| FR-2.3 | Calculate current value | OBJECTIVES.md FR-2.3 | `portfolio_test` — "getSummary returns expected keys" · `stock_test` — "construction with defaults" | `lib/src/stock.dart` · `lib/src/portfolio.dart` | — |
| FR-2.4 | Track gain/loss and percentage | OBJECTIVES.md FR-2.4 | `portfolio_test` — "getSummary returns expected keys" · `analyzer_test` — "identifying high-performing stocks", "identifying underperforming stocks" | `lib/src/portfolio.dart` · `lib/src/analyzer.dart` · `lib/src/ui/screens/analysis_screen.dart` | — |
| FR-2.5 | Support multiple asset types (stocks, bonds, ETFs, funds) | OBJECTIVES.md FR-2.5 | `account_test` — "getAllocationByType returns percentages" | `lib/src/account.dart` · `lib/src/stock.dart` | — |
| FR-2.6 | Sell holdings (remove shares, record transaction) | OBJECTIVES.md FR-2.1 | `portfolio_test` — "sellStock removes shares and records transaction", "sellStock all shares removes from portfolio", "sellStock returns false for insufficient shares", "sellStock returns false for unknown symbol" | `lib/src/portfolio.dart` · `lib/src/transaction.dart` | — |

---

## FR-3 · Asset Allocation

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-3.1 | Define target allocation percentages | OBJECTIVES.md FR-3.1 | `analyzer_test` — "rebalancing suggestions with target allocation" | `lib/src/analyzer.dart` | — |
| FR-3.2 | Calculate current allocation | OBJECTIVES.md FR-3.2 | `account_test` — "getAllocationByType returns percentages" | `lib/src/account.dart` · `lib/src/repository.dart` | — |
| FR-3.3 | Show allocation drift | OBJECTIVES.md FR-3.3 | `analyzer_test` — "rebalancing suggestions with target allocation" | `lib/src/analyzer.dart` · `lib/src/ui/screens/analysis_screen.dart` | — |
| FR-3.4 | Visualise allocation (chart) | OBJECTIVES.md FR-3.4 | None — gap | `lib/src/ui/screens/analysis_screen.dart` | — |

---

## FR-4 · Rebalancing

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-4.1 | Identify over/under-allocated positions | OBJECTIVES.md FR-4.1 | `analyzer_test` — "rebalancing suggestions with target allocation" | `lib/src/analyzer.dart` | — |
| FR-4.2 | Suggest buy/sell amounts | OBJECTIVES.md FR-4.2 | `analyzer_test` — "rebalancing suggestions with target allocation", "rebalancing suggestions for empty portfolio" | `lib/src/analyzer.dart` · `lib/src/ui/screens/analysis_screen.dart` | Rebalancing suggestions shown |
| FR-4.3 | Minimise number of trades | OBJECTIVES.md FR-4.3 | `analyzer_test` — "rebalancing suggestions with target allocation" | `lib/src/analyzer.dart` | — |
| FR-4.4 | Consider cash position | OBJECTIVES.md FR-4.4 | None — gap | `lib/src/analyzer.dart` | — |

---

## FR-5 · Analytics

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-5.1 | Portfolio diversification score | OBJECTIVES.md FR-5.1 | `analyzer_test` — "diversification score for empty portfolio", "diversification score for single stock", "diversification score for moderate holdings" | `lib/src/analyzer.dart` | — |
| FR-5.2 | Total gain/loss | OBJECTIVES.md FR-5.2 | `portfolio_test` — "getSummary returns expected keys" | `lib/src/portfolio.dart` | — |
| FR-5.3 | Best/worst performers | OBJECTIVES.md FR-5.3 | `analyzer_test` — "identifying high-performing stocks", "identifying underperforming stocks" | `lib/src/analyzer.dart` · `lib/src/ui/screens/analysis_screen.dart` | — |
| FR-5.4 | Recommendations based on analysis | OBJECTIVES.md FR-5.4 | `analyzer_test` — "recommendations for empty portfolio", "recommendations for losing portfolio", "recommendations for winning portfolio", "diversification recommendations", "recommendations for high performers" | `lib/src/analyzer.dart` | — |
| FR-5.5 | Dividend tracking | Not in OBJECTIVES — implemented | `dividend_test` · `tax_lot_test` | `lib/src/dividend.dart` · `lib/src/tax_lot.dart` · `lib/src/tax_analyzer.dart` | — |

---

## FR-6 · Portfolio Summary

| ID | Feature | Product Spec | Tests | Implementation | Release Gate |
|----|---------|-------------|-------|----------------|--------------|
| FR-6.1 | Total value across accounts | OBJECTIVES.md FR-6.1 | `account_test` — "getAggregateView sums across accounts" | `lib/src/repository.dart` · `lib/src/ui/screens/dashboard_screen.dart` | — |
| FR-6.2 | Overall gain/loss | OBJECTIVES.md FR-6.2 | `portfolio_test` — "getSummary returns expected keys" | `lib/src/portfolio.dart` · `lib/src/ui/screens/dashboard_screen.dart` | — |
| FR-6.3 | Allocation breakdown | OBJECTIVES.md FR-6.3 | `account_test` — "getAllocationByType returns percentages" | `lib/src/repository.dart` · `lib/src/ui/screens/dashboard_screen.dart` | — |
| FR-6.4 | Number of holdings | OBJECTIVES.md FR-6.4 | `portfolio_test` — "starts empty" | `lib/src/portfolio.dart` | — |

---

## Coverage Summary

| FR Group | Sub-features | Tests | Gaps |
|----------|-------------|-------|------|
| FR-1 Account Management | 5 | Comprehensive | No widget tests for UI |
| FR-2 Holdings | 6 | Core model tests solid | Price update untested (planned feature) |
| FR-3 Asset Allocation | 4 | Partial (analyzer covers logic) | Allocation chart UI untested |
| FR-4 Rebalancing | 4 | Logic covered | Cash position not tested |
| FR-5 Analytics | 5 | Comprehensive (all recommendation branches) | None |
| FR-6 Portfolio Summary | 4 | Partial (model level) | Dashboard screen has no widget tests |

> **Priority gaps**: Add widget tests for `dashboard_screen`, `analysis_screen`, and `add_stock_screen`; add price service mock tests when price API is integrated; add cash position rebalancing test.

## Integration Test Coverage

`integration_test/app_test.dart` covers:
- App loads and displays dashboard
- App renders without crashing
- Holdings section is displayed
- Add Stock button is present
- Add Stock button opens form
- Stock form has symbol and shares fields
- Cancel from Add Stock returns to dashboard
- Analysis screen is reachable
- App handles multiple interactions without crashing
- Scaffold and Navigator are present

## Workflow Documentation

Primary user journeys documented in `docs/WORKFLOWS.md`:
- Workflow 1: Portfolio Setup (accounts, holdings, target allocation)
- Workflow 2: Daily Portfolio Review (update prices)
- Workflow 3: Rebalancing Workflow
- Workflow 4: Performance Analytics
- Workflow 5: Tax Features (dividend, tax lot)
- Workflow 6: Multi-Account Aggregate View
- Screen / Route Map
