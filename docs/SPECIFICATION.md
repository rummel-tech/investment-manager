---
module: investment-manager
version: 1.0.0
status: draft
last_updated: 2026-01-20
---

# Investment Manager Specification

## Overview

The Investment Manager module provides portfolio management and investment analysis capabilities. It enables users to track stock holdings, analyze portfolio performance, get rebalancing suggestions, calculate diversification scores, and receive actionable investment recommendations. The module is implemented as a pure Dart library designed for integration into larger applications.

## Authentication

This module uses the shared AWS Amplify authentication system. See [Authentication Architecture](../../../../docs/architecture/AUTHENTICATION.md) for complete details.

### Authentication Modes

| Mode | Description |
|------|-------------|
| Artemis-Integrated | User authenticates via Artemis, gains access to all permitted modules |
| Standalone | User authenticates directly in Investment Manager app |

### Module Access

- **Module ID**: `investment-manager`
- **Artemis Users**: Full access when `artemis_access: true`
- **Standalone Users**: Access when `investment-manager` in `module_access` list

### Login Screen

Uses shared `auth_ui` package with identical UI to all other modules:
- Email/password authentication
- Google Sign-In
- Apple Sign-In
- Email verification flow
- Password reset flow

### API Authentication

All API endpoints require JWT Bearer token from AWS Cognito:
```http
Authorization: Bearer <access_token>
```

## Design System

This module uses the shared Artemis Design System. See [Design System](../../../../docs/architecture/DESIGN_SYSTEM.md) for complete specifications.

### Design Principles

All UI components follow the shared design system to ensure visual consistency across the Artemis ecosystem:

- **Colors**: Rummel Blue primary (`#1E88E5`), Teal secondary (`#26A69A`)
- **Typography**: Material 3 type scale with system fonts
- **Spacing**: Consistent 4dp base unit scale (xs: 4dp, sm: 8dp, md: 16dp, lg: 24dp)
- **Components**: Shared button, card, input, and navigation styles

### Module-Specific Colors

| Element | Color | Token | Usage |
|---------|-------|-------|-------|
| Gains | `#388E3C` | `success` | Positive returns, profit indicators |
| Losses | `#D32F2F` | `error` | Negative returns, loss indicators |
| Neutral | `#26A69A` | `secondary500` | Break-even, no change |
| Allocation | `#1E88E5` | `primary500` | Portfolio allocation charts |

### Performance Display Colors

| Performance | Color | Condition |
|-------------|-------|-----------|
| Strong Gain | `#2E7D32` | > +10% |
| Gain | `#388E3C` | +0.01% to +10% |
| Neutral | `#757575` | 0% |
| Loss | `#D32F2F` | -0.01% to -10% |
| Strong Loss | `#B71C1C` | < -10% |

### Key Components

| Component | Specification |
|-----------|---------------|
| PortfolioSummary | Card with total value, gain/loss with semantic color |
| StockCard | Card with symbol, shares, price, gain/loss percentage |
| AllocationChart | Pie chart using primary color scale |
| PerformanceBar | Horizontal bar with gain (green) / loss (red) fill |
| DiversificationGauge | Semi-circular gauge with score and recommendation |
| RecommendationCard | Card with icon, action text, reasoning |

### Diversification Score Colors

| Score Range | Color | Meaning |
|-------------|-------|---------|
| 0-30 | `#D32F2F` | Poor diversification |
| 31-60 | `#F57C00` | Low diversification |
| 61-80 | `#1E88E5` | Moderate diversification |
| 81-100 | `#388E3C` | Good diversification |

### Screen Layouts

All screens follow responsive breakpoints from the shared design system:
- Mobile (< 600dp): Single column with portfolio at top, holdings list
- Tablet (600-839dp): Two-column with portfolio summary and holdings
- Desktop (>= 840dp): Dashboard with charts, holdings table, and analysis panel

## Data Models

### Stock

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| symbol | String | Required, uppercase | Stock ticker symbol (e.g., AAPL) |
| shares | double | Required, > 0 | Number of shares owned |
| purchasePrice | double | Required, > 0 | Price per share at purchase |
| currentPrice | double | Default: purchasePrice | Current market price |
| purchaseDate | DateTime | Default: now | Date of purchase |

**Computed Properties:**
- `totalCost`: shares × purchasePrice
- `currentValue`: shares × currentPrice
- `gainLoss`: currentValue - totalCost
- `gainLossPercent`: (gainLoss / totalCost) × 100

**Methods:**
- `updatePrice(double newPrice)`: Updates currentPrice

**JSON Serialization:**
```json
{
  "symbol": "AAPL",
  "shares": 50.0,
  "purchasePrice": 150.00,
  "currentPrice": 175.00,
  "purchaseDate": "2025-06-15T00:00:00.000Z"
}
```

**Example Calculations:**
```
totalCost = 50 × 150 = $7,500
currentValue = 50 × 175 = $8,750
gainLoss = 8,750 - 7,500 = $1,250
gainLossPercent = (1,250 / 7,500) × 100 = 16.67%
```

### Portfolio

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| name | String | Default: "My Portfolio" | Portfolio name |
| _holdings | Map<String, Stock> | Internal | Stock holdings by symbol |

**Computed Properties:**
- `holdings`: List of all Stock objects
- `totalValue`: Sum of all stock currentValues
- `totalCost`: Sum of all stock totalCosts
- `totalGainLoss`: totalValue - totalCost
- `totalGainLossPercent`: (totalGainLoss / totalCost) × 100

**Methods:**
- `addStock(Stock stock)`: Add or merge stock holding
- `removeStock(String symbol)`: Remove stock, returns removed Stock?
- `getStock(String symbol)`: Get stock by symbol
- `updateStockPrice(String symbol, double price)`: Update price
- `getSummary()`: Returns summary map

**Merge Behavior:**
When adding a stock with existing symbol, the system:
1. Calculates new total shares
2. Calculates weighted average purchase price
3. Updates current price to new stock's price

**JSON Summary:**
```json
{
  "name": "My Portfolio",
  "num_holdings": 5,
  "total_value": 50000.00,
  "total_cost": 45000.00,
  "total_gain_loss": 5000.00,
  "total_gain_loss_percent": 11.11
}
```

### StockPerformance

| Field | Type | Description |
|-------|------|-------------|
| symbol | String | Stock ticker |
| gainLossPercent | double | Performance percentage |

### DiversificationResult

| Field | Type | Description |
|-------|------|-------------|
| score | double | Diversification score (0-90) |
| recommendation | String | Advice text |

**Score Ranges:**
| Holdings | Score | Recommendation |
|----------|-------|----------------|
| 0 | 0 | No holdings. Cannot assess diversification. |
| 1 | 20 | Poor diversification. Consider adding more stocks. |
| 2-3 | 40 | Low diversification. Consider adding more stocks. |
| 4-7 | 70 | Moderate diversification. Good balance. |
| 8-15 | 90 | Good diversification. |
| 16+ | 85 | High diversification. May be difficult to manage. |

## InvestmentAnalyzer

Static analysis class providing portfolio insights.

### Methods

#### analyzePortfolio(Portfolio)

**Description:** Comprehensive portfolio analysis

**Returns:**
```json
{
  "status": "analyzed",
  "summary": { /* portfolio summary */ },
  "winners": 3,
  "losers": 2,
  "best_performer": {
    "symbol": "AAPL",
    "gain_loss_percent": 25.5
  },
  "worst_performer": {
    "symbol": "XYZ",
    "gain_loss_percent": -8.2
  }
}
```

#### getRebalancingSuggestions(Portfolio, [Map<String, double>? targetAllocation])

**Description:** Suggests rebalancing actions based on current vs target allocation

**Parameters:**
- `portfolio`: Portfolio to analyze
- `targetAllocation`: Optional map of {symbol: target_percent}

**Returns:** List of suggestions with action (increase/reduce), current and target allocation, difference

**Threshold:** Deviations > 5% trigger suggestions

**Example Response:**
```json
[
  {
    "symbol": "AAPL",
    "action": "reduce",
    "current_allocation": 35.0,
    "target_allocation": 25.0,
    "difference": 10.0
  },
  {
    "symbol": "GOOGL",
    "action": "increase",
    "current_allocation": 15.0,
    "target_allocation": 25.0,
    "difference": 10.0
  }
]
```

#### identifyHighPerformers(Portfolio, {double threshold = 20.0})

**Description:** Find stocks exceeding performance threshold

**Parameters:**
- `portfolio`: Portfolio to analyze
- `threshold`: Minimum gain percentage (default: 20%)

**Returns:** List of Stock objects with gainLossPercent >= threshold

#### identifyUnderperformers(Portfolio, {double threshold = -10.0})

**Description:** Find stocks below performance threshold

**Parameters:**
- `portfolio`: Portfolio to analyze
- `threshold`: Maximum loss percentage (default: -10%)

**Returns:** List of Stock objects with gainLossPercent <= threshold

#### getDiversificationScore(Portfolio)

**Description:** Calculate diversification score

**Returns:** DiversificationResult with score and recommendation

#### generateRecommendations(Portfolio)

**Description:** Generate actionable investment recommendations

**Logic:**
1. Check overall portfolio performance
2. Check diversification score
3. Identify high performers (>30% gain)
4. Identify underperformers (>15% loss)

**Returns:** List of recommendation strings

**Example:**
```dart
[
  "Portfolio is performing well. Consider taking some profits.",
  "Consider taking profits on high performers: AAPL, NVDA",
  "Review underperforming stocks for potential exit: XYZ"
]
```

## Use Cases

### UC-001: Add Stock to Portfolio

**Actor:** User

**Preconditions:**
- Portfolio exists

**Flow:**
1. User provides stock symbol, shares, purchase price
2. System normalizes symbol to uppercase
3. If symbol exists, system merges with existing holding
4. If new symbol, system adds to portfolio
5. System returns success

**Postconditions:**
- Stock is in portfolio
- Holdings count updated if new stock

**Acceptance Criteria:**
- [ ] Symbol stored in uppercase
- [ ] Shares and price validated > 0
- [ ] Existing holdings merged correctly
- [ ] Total cost calculated accurately

### UC-002: Update Stock Price

**Actor:** User / System (automated)

**Preconditions:**
- Stock exists in portfolio

**Flow:**
1. User/system provides symbol and new price
2. System finds stock by symbol
3. System updates currentPrice
4. Computed properties automatically recalculate

**Postconditions:**
- Stock reflects new price
- Portfolio totals updated

**Acceptance Criteria:**
- [ ] Price update reflected immediately
- [ ] gainLoss recalculated
- [ ] Portfolio totalValue updated

### UC-003: Analyze Portfolio Performance

**Actor:** User

**Preconditions:**
- Portfolio has holdings

**Flow:**
1. User requests portfolio analysis
2. System retrieves all holdings
3. System calculates winners/losers counts
4. System identifies best/worst performers
5. System returns analysis summary

**Postconditions:**
- Analysis returned without modifying data

**Acceptance Criteria:**
- [ ] Winners/losers correctly counted
- [ ] Best performer has highest gain%
- [ ] Worst performer has lowest gain%
- [ ] Summary includes totals

### UC-004: Get Rebalancing Suggestions

**Actor:** User

**Preconditions:**
- Portfolio has holdings
- User has target allocation (optional)

**Flow:**
1. User requests rebalancing suggestions
2. User optionally provides target allocation
3. System calculates current allocation per stock
4. System compares to target (or shows current)
5. System identifies significant deviations
6. System returns suggestions

**Postconditions:**
- Suggestions returned

**Acceptance Criteria:**
- [ ] Current allocation calculated correctly
- [ ] Deviations > 5% flagged
- [ ] Action (increase/reduce) specified
- [ ] Without target, shows current allocation only

### UC-005: View Diversification Score

**Actor:** User

**Preconditions:**
- Portfolio exists

**Flow:**
1. User requests diversification score
2. System counts holdings
3. System calculates score based on count
4. System generates recommendation
5. System returns result

**Postconditions:**
- Score and recommendation returned

**Acceptance Criteria:**
- [ ] Score reflects holding count
- [ ] Appropriate recommendation text
- [ ] Edge cases handled (empty, 1 stock)

### UC-006: Identify High/Low Performers

**Actor:** User

**Preconditions:**
- Portfolio has holdings

**Flow:**
1. User requests performer identification
2. User specifies threshold (or uses default)
3. System filters stocks by performance
4. System returns matching stocks

**Postconditions:**
- Filtered stock list returned

**Acceptance Criteria:**
- [ ] High performers >= threshold
- [ ] Low performers <= threshold
- [ ] Empty list if no matches

## UI Workflows

### Screen: Portfolio Dashboard (Planned)

**Purpose:** Overview of portfolio value and performance

**Entry Points:**
- Main app navigation
- Dashboard widget

**Components:**
- PortfolioSummary: Total value, gain/loss, percentage
- PerformanceChart: Value over time (line chart)
- HoldingsList: All stocks with current values
- TopMovers: Best and worst performers
- QuickActions: Add stock, refresh prices

**Actions:**
| Action | Trigger | Result |
|--------|---------|--------|
| Add Stock | FAB tap | Open add stock form |
| View Stock | Stock tap | Navigate to stock detail |
| Refresh Prices | Button | Update all prices |

**Navigation:**
- Stock tap → Stock Detail
- Add → Stock Form

### Screen: Stock Detail (Planned)

**Purpose:** Detailed view of single holding

**Entry Points:**
- Portfolio dashboard stock tap

**Components:**
- StockHeader: Symbol, company name, current price
- PerformanceCard: Gain/loss, percentage, trend
- HoldingInfo: Shares, purchase price, cost basis
- PriceHistory: Historical price chart
- TransactionList: Buy/sell history
- ActionButtons: Buy more, sell, remove

**Actions:**
| Action | Trigger | Result |
|--------|---------|--------|
| Buy More | Button | Open buy form |
| Sell | Button | Open sell form |
| Remove | Menu | Remove from portfolio |
| Update Price | Pull refresh | Fetch latest price |

**Navigation:**
- Back → Portfolio Dashboard
- Buy/Sell → Transaction Form

### Screen: Add Stock Form (Planned)

**Purpose:** Add new stock to portfolio

**Entry Points:**
- Portfolio dashboard FAB
- Quick action

**Components:**
- SymbolSearch: Search/select stock symbol
- SharesInput: Number of shares
- PriceInput: Purchase price per share
- DatePicker: Purchase date
- TotalCost: Calculated display
- SaveButton: Confirm addition

**Actions:**
| Action | Trigger | Result |
|--------|---------|--------|
| Search | Type in symbol | Show suggestions |
| Calculate | Price/shares change | Update total |
| Save | Button tap | Add stock, return |

**Navigation:**
- Save → Portfolio Dashboard (with new stock)
- Cancel → Portfolio Dashboard

### Screen: Analysis Dashboard (Planned)

**Purpose:** Portfolio analysis and recommendations

**Entry Points:**
- Portfolio dashboard analysis button
- Main navigation

**Components:**
- DiversificationCard: Score with gauge visualization
- AllocationChart: Pie chart of holdings
- RebalancingSuggestions: List of actions
- PerformanceTable: All stocks with metrics
- RecommendationsList: Actionable advice

**Actions:**
| Action | Trigger | Result |
|--------|---------|--------|
| Set Target | Button | Open allocation editor |
| View Stock | Row tap | Navigate to stock detail |
| Export | Menu | Export analysis report |

**Navigation:**
- Stock tap → Stock Detail
- Set Target → Allocation Editor

## API Specification

### Future REST API Design

The module currently provides a Dart library. The following REST API is planned for future implementation.

### GET /investments/api/v1/portfolios

**Description:** List user's portfolios

**Authentication:** Required (JWT Bearer)

**Response 200:**
```json
{
  "data": [
    {
      "id": "portfolio-uuid",
      "name": "My Portfolio",
      "total_value": 50000.00,
      "total_gain_loss_percent": 11.11,
      "holdings_count": 5
    }
  ]
}
```

### GET /investments/api/v1/portfolios/{portfolioId}

**Description:** Get portfolio details with holdings

**Authentication:** Required (JWT Bearer)

**Response 200:**
```json
{
  "data": {
    "id": "portfolio-uuid",
    "name": "My Portfolio",
    "holdings": [
      {
        "symbol": "AAPL",
        "shares": 50.0,
        "purchase_price": 150.00,
        "current_price": 175.00,
        "total_cost": 7500.00,
        "current_value": 8750.00,
        "gain_loss": 1250.00,
        "gain_loss_percent": 16.67
      }
    ],
    "summary": {
      "total_value": 50000.00,
      "total_cost": 45000.00,
      "total_gain_loss": 5000.00,
      "total_gain_loss_percent": 11.11
    }
  }
}
```

### POST /investments/api/v1/portfolios/{portfolioId}/stocks

**Description:** Add stock to portfolio

**Authentication:** Required (JWT Bearer)

**Request Body:**
```json
{
  "symbol": "string - required",
  "shares": "number - required, > 0",
  "purchase_price": "number - required, > 0",
  "purchase_date": "string - optional, ISO date"
}
```

**Response 201:**
```json
{
  "data": {
    "symbol": "AAPL",
    "shares": 50.0,
    "purchase_price": 150.00,
    "current_price": 150.00,
    "total_cost": 7500.00
  }
}
```

### PATCH /investments/api/v1/portfolios/{portfolioId}/stocks/{symbol}

**Description:** Update stock (price, add shares)

**Authentication:** Required (JWT Bearer)

**Request Body:**
```json
{
  "current_price": "number - optional",
  "add_shares": "number - optional",
  "add_price": "number - required if add_shares"
}
```

### DELETE /investments/api/v1/portfolios/{portfolioId}/stocks/{symbol}

**Description:** Remove stock from portfolio

**Authentication:** Required (JWT Bearer)

**Response 204:** No content

### GET /investments/api/v1/portfolios/{portfolioId}/analysis

**Description:** Get portfolio analysis

**Authentication:** Required (JWT Bearer)

**Response 200:**
```json
{
  "data": {
    "summary": { /* portfolio summary */ },
    "winners": 3,
    "losers": 2,
    "best_performer": {"symbol": "AAPL", "gain_loss_percent": 25.5},
    "worst_performer": {"symbol": "XYZ", "gain_loss_percent": -8.2},
    "diversification": {"score": 70, "recommendation": "Moderate diversification."},
    "recommendations": [
      "Consider taking profits on high performers: AAPL"
    ]
  }
}
```

### GET /investments/api/v1/portfolios/{portfolioId}/rebalancing

**Description:** Get rebalancing suggestions

**Authentication:** Required (JWT Bearer)

**Query Parameters:**
| Name | Type | Description |
|------|------|-------------|
| target | string | JSON-encoded target allocation |

**Response 200:**
```json
{
  "data": {
    "suggestions": [
      {
        "symbol": "AAPL",
        "action": "reduce",
        "current_allocation": 35.0,
        "target_allocation": 25.0,
        "difference": 10.0
      }
    ]
  }
}
```

### POST /investments/api/v1/prices/refresh

**Description:** Refresh current prices for all stocks

**Authentication:** Required (JWT Bearer)

**Request Body:**
```json
{
  "portfolio_id": "string - required"
}
```

**Response 200:**
```json
{
  "data": {
    "updated": 5,
    "prices": {
      "AAPL": 175.50,
      "GOOGL": 140.25
    }
  }
}
```

## Implementation Status

### Data Models

| Model | Status | Notes |
|-------|--------|-------|
| Stock | ✅ Implemented | Full model with computed properties |
| Portfolio | ✅ Implemented | Collection management, merge logic |
| StockPerformance | ✅ Implemented | Analysis result type |
| DiversificationResult | ✅ Implemented | Score and recommendation |

### Analysis Functions

| Function | Status | Notes |
|----------|--------|-------|
| analyzePortfolio() | ✅ Implemented | Winners/losers, best/worst |
| getRebalancingSuggestions() | ✅ Implemented | With optional target |
| identifyHighPerformers() | ✅ Implemented | Configurable threshold |
| identifyUnderperformers() | ✅ Implemented | Configurable threshold |
| getDiversificationScore() | ✅ Implemented | Count-based scoring |
| generateRecommendations() | ✅ Implemented | Multi-factor analysis |

### API Endpoints

| Endpoint | Status | Notes |
|----------|--------|-------|
| GET /portfolios | ⬜ Planned | REST API not yet implemented |
| GET /portfolios/{id} | ⬜ Planned | Currently library-only |
| POST /portfolios/{id}/stocks | ⬜ Planned | |
| PATCH /stocks/{symbol} | ⬜ Planned | |
| DELETE /stocks/{symbol} | ⬜ Planned | |
| GET /analysis | ⬜ Planned | |
| GET /rebalancing | ⬜ Planned | |
| POST /prices/refresh | ⬜ Planned | |

### UI Screens

| Screen | Status | Notes |
|--------|--------|-------|
| Login | ⬜ Planned | Uses shared auth_ui package |
| Register | ⬜ Planned | Uses shared auth_ui package |
| Portfolio Dashboard | ⬜ Planned | No Flutter UI implemented |
| Stock Detail | ⬜ Planned | |
| Add Stock Form | ⬜ Planned | |
| Analysis Dashboard | ⬜ Planned | |
| Allocation Editor | ⬜ Planned | |

### Authentication

| Component | Status | Notes |
|-----------|--------|-------|
| AWS Amplify Integration | ⬜ Planned | Shared Cognito User Pool |
| Shared auth_ui Package | ⬜ Planned | Login/register screens |
| Token Validation | ⬜ Planned | Backend JWT verification |
| Module Access Control | ⬜ Planned | Cognito custom attributes |

### Testing

| Component | Status | Notes |
|-----------|--------|-------|
| Stock Tests | ✅ Implemented | Property calculations |
| Portfolio Tests | ✅ Implemented | Add/remove/merge |
| Analyzer Tests | ✅ Implemented | All analysis functions |

**Legend:** ✅ Implemented | 🚧 Partial | ⬜ Planned

## Technical Notes

### Dependencies
- Dart SDK: >=3.0.0 <4.0.0
- No external production dependencies (pure Dart)
- Dev: test, lints

### Storage
- Current: In-memory (Portfolio object)
- Planned: PostgreSQL with user_id scoping

### Key Implementation Details
- Symbols automatically normalized to uppercase
- Stock merge calculates weighted average purchase price
- Diversification score caps at 90 (8-15 holdings optimal)
- Rebalancing threshold is 5% deviation
- High performer threshold default: 20%
- Underperformer threshold default: -10%
- Analysis is pure computation, no side effects

### External Integrations (Planned)
- Price data: Alpha Vantage, Yahoo Finance, or similar
- Real-time quotes: WebSocket for live updates
- Historical data: For performance charts
