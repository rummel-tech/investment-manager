# Investment Manager — Primary Workflows

Documents the main user-facing journeys through the Investment Manager app.

---

## Navigation Structure

App opens directly to **DashboardScreen**. Navigation flows to:
- **AddStockScreen** — add a new holding
- **AnalysisScreen** — allocation, rebalancing, diversification

---

## 1. Portfolio Setup (First Use)

### Step 1: Create an Account
**Entry:** DashboardScreen → account selector → **Add Account**

1. Enter account name (e.g. "Vanguard Brokerage", "Roth IRA")
2. Select account type: brokerage, retirement (traditional IRA, Roth IRA), 401k, other
3. Save → account appears in the account list

### Step 2: Add Holdings
**Entry:** DashboardScreen → account → **Add Stock** (+ button)

1. Enter ticker symbol (e.g. "VTI")
2. Enter number of shares
3. Enter cost basis per share
4. Select asset type: US Stock, International, Bond, Real Estate, Cash, Alternative
5. Save → holding appears in portfolio

### Step 3: Set Target Allocation
**Entry:** AnalysisScreen → **Set Targets**

1. Assign target percentages per asset type (must sum to 100%)
2. Save → allocation drift calculated immediately

---

## 2. Daily Portfolio Review

### Step 1: Open Dashboard
- **DashboardScreen** displays:
  - Total portfolio value across all accounts
  - Overall gain/loss ($ and %)
  - Holdings list with current value, gain/loss per position
  - Best and worst performers highlighted

### Step 2: Update Prices
**Entry:** Dashboard → price field on any holding → **Update Price**

1. Enter current market price
2. Save → portfolio value and gain/loss recalculate instantly

> Note: Automatic price API integration is planned (Alpha Vantage / Yahoo Finance).

---

## 3. Rebalancing Workflow

### Step 1: Open Analysis
**Entry:** DashboardScreen → **Analysis** button or bottom tab

- **AnalysisScreen** shows:
  - Current allocation (bar or pie chart) vs. target allocation
  - Drift per asset type (over/under %)
  - Diversification score (0–100)
  - Rebalancing suggestions

### Step 2: Review Suggestions
- Suggestions list shows: "Buy $X of [asset type]" or "Sell $X of [asset type]"
- Sorted to minimise number of trades
- Cash position considered if set

### Step 3: Execute Manually
- User executes trades in their brokerage (app is read-only / advisory only)
- Update holdings in the app after trades clear

---

## 4. Performance Analytics

**Entry:** AnalysisScreen → **Analytics** section

| Metric | Description |
|--------|-------------|
| Diversification score | 0–100 based on number and spread of holdings |
| Best performer | Holding with highest % gain |
| Worst performer | Holding with highest % loss |
| Recommendations | Text guidance (diversify, hold, review losers, etc.) |

---

## 5. Tax Features (Dividend & Tax Lot)

- Log dividend payments per holding
- Tax lot tracking: FIFO or specific lot for cost basis
- Tax-loss harvesting recommendations (planned)

---

## 6. Multi-Account Aggregate View

- DashboardScreen aggregates all accounts by default
- Filter to a single account via account selector
- Allocation chart reflects selected scope

---

## 7. Screen / Route Map

| Screen | Purpose |
|--------|---------|
| DashboardScreen | Portfolio overview — total value, holdings, gain/loss |
| AddStockScreen | Add a new holding to the selected account |
| AnalysisScreen | Allocation, rebalancing suggestions, diversification, recommendations |

---

## 8. Typical Workflow

```
DashboardScreen
    → Review total value and gain/loss
    → Update prices for key holdings
    → Tap Analysis
        → See allocation drift (e.g. bonds 5% under target)
        → Read rebalancing suggestion: "Buy $2,000 BND"
        → Execute trade in brokerage
    → Return to Dashboard
        → Add shares purchased → portfolio recalculates
```
