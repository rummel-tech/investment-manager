/// Investment account management.
library account;

import 'portfolio.dart';
import 'transaction.dart';
import 'stock.dart';

/// Types of investment accounts.
enum AccountType {
  /// Standard taxable brokerage account
  brokerage,

  /// Tax-advantaged retirement account (IRA, 401k, etc.)
  retirement,

  /// Personal tracking account (no tax implications)
  personal,
}

/// Represents an investment account containing a portfolio and transactions.
class Account {
  /// Unique account identifier
  final String id;

  /// Account name
  final String name;

  /// Type of account
  final AccountType type;

  /// Date account was created
  final DateTime createdAt;

  /// Portfolio of holdings
  final Portfolio portfolio;

  /// Transaction history for this account
  final TransactionHistory transactions;

  /// Initialize an investment account.
  ///
  /// Args:
  ///   id: Unique account identifier
  ///   name: Account name
  ///   type: Type of account
  ///   createdAt: Date account was created (defaults to now)
  ///   portfolio: Portfolio of holdings (creates new if not provided)
  ///   transactions: Transaction history (creates new if not provided)
  Account({
    required this.id,
    required this.name,
    required this.type,
    DateTime? createdAt,
    Portfolio? portfolio,
    TransactionHistory? transactions,
  })  : createdAt = createdAt ?? DateTime.now(),
        portfolio = portfolio ?? Portfolio(name: name),
        transactions = transactions ?? TransactionHistory();

  /// Get total current value of the account.
  double get totalValue => portfolio.totalValue;

  /// Get total cost basis of the account.
  double get totalCost => portfolio.totalCost;

  /// Get total gain/loss in dollars.
  double get totalGainLoss => portfolio.totalGainLoss;

  /// Get total gain/loss as a percentage.
  double get totalGainLossPercent => portfolio.totalGainLossPercent;

  /// Check if this is a tax-advantaged account.
  bool get isTaxAdvantaged => type == AccountType.retirement;

  /// Get all holdings in the account.
  List<Stock> get holdings => portfolio.holdings;

  /// Get all unique symbols in the account.
  List<String> get symbols => holdings.map((s) => s.symbol).toList();

  /// Record a buy transaction and update portfolio.
  ///
  /// Args:
  ///   transactionId: Unique transaction ID
  ///   symbol: Stock ticker symbol
  ///   shares: Number of shares purchased
  ///   pricePerShare: Price per share
  ///   fees: Transaction fees (defaults to 0)
  ///   date: Transaction date (defaults to now)
  ///   notes: Optional notes
  void buyStock({
    required String transactionId,
    required String symbol,
    required double shares,
    required double pricePerShare,
    double fees = 0.0,
    DateTime? date,
    String? notes,
  }) {
    final transaction = Transaction(
      id: transactionId,
      accountId: id,
      symbol: symbol,
      type: TransactionType.buy,
      shares: shares,
      pricePerShare: pricePerShare,
      fees: fees,
      date: date,
      notes: notes,
    );
    transactions.addTransaction(transaction);

    final stock = Stock(
      symbol: symbol,
      shares: shares,
      purchasePrice: pricePerShare,
      purchaseDate: date,
    );
    portfolio.addStock(stock);
  }

  /// Record a sell transaction and update portfolio.
  ///
  /// Args:
  ///   transactionId: Unique transaction ID
  ///   symbol: Stock ticker symbol
  ///   shares: Number of shares sold
  ///   pricePerShare: Price per share
  ///   fees: Transaction fees (defaults to 0)
  ///   date: Transaction date (defaults to now)
  ///   notes: Optional notes
  ///
  /// Returns:
  ///   true if sale was recorded, false if insufficient shares
  bool sellStock({
    required String transactionId,
    required String symbol,
    required double shares,
    required double pricePerShare,
    double fees = 0.0,
    DateTime? date,
    String? notes,
  }) {
    final existingStock = portfolio.getStock(symbol);
    if (existingStock == null || existingStock.shares < shares) {
      return false;
    }

    final transaction = Transaction(
      id: transactionId,
      accountId: id,
      symbol: symbol,
      type: TransactionType.sell,
      shares: shares,
      pricePerShare: pricePerShare,
      fees: fees,
      date: date,
      notes: notes,
    );
    transactions.addTransaction(transaction);

    // Update portfolio
    if (existingStock.shares == shares) {
      portfolio.removeStock(symbol);
    } else {
      existingStock.shares -= shares;
    }

    return true;
  }

  /// Update the current price of a stock.
  bool updateStockPrice(String symbol, double newPrice) {
    return portfolio.updateStockPrice(symbol, newPrice);
  }

  /// Get account summary.
  Map<String, dynamic> getSummary() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGainLoss': totalGainLoss,
      'totalGainLossPercent': totalGainLossPercent,
      'numHoldings': holdings.length,
      'numTransactions': transactions.all.length,
      'isTaxAdvantaged': isTaxAdvantaged,
    };
  }

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'portfolio': portfolio.toJson(),
      'transactions': transactions.toJson(),
    };
  }

  /// Create an Account from JSON map.
  ///
  /// Args:
  ///   json: Map containing account data
  ///
  /// Returns:
  ///   Account instance
  static Account fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AccountType.brokerage,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      portfolio: json['portfolio'] != null
          ? Portfolio.fromJson(json['portfolio'] as Map<String, dynamic>)
          : null,
      transactions: json['transactions'] != null
          ? TransactionHistory.fromJson(json['transactions'] as List<dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return '$name ($type): \$${totalValue.toStringAsFixed(2)}';
  }
}

/// Manages multiple investment accounts.
class AccountManager {
  /// Internal map of accounts by ID
  final Map<String, Account> _accounts = {};

  /// Add an account.
  void addAccount(Account account) {
    _accounts[account.id] = account;
  }

  /// Remove an account by ID.
  ///
  /// Returns:
  ///   Removed account or null if not found
  Account? removeAccount(String id) {
    return _accounts.remove(id);
  }

  /// Get an account by ID.
  Account? getAccount(String id) {
    return _accounts[id];
  }

  /// Get all accounts.
  List<Account> get all => _accounts.values.toList();

  /// Get accounts by type.
  List<Account> getByType(AccountType type) {
    return _accounts.values.where((a) => a.type == type).toList();
  }

  /// Get aggregate view across all accounts.
  Map<String, dynamic> getAggregateView() {
    double totalValue = 0;
    double totalCost = 0;
    int totalHoldings = 0;
    final allSymbols = <String>{};

    for (final account in _accounts.values) {
      totalValue += account.totalValue;
      totalCost += account.totalCost;
      totalHoldings += account.holdings.length;
      allSymbols.addAll(account.symbols);
    }

    final totalGainLoss = totalValue - totalCost;
    final totalGainLossPercent = totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0.0;

    return {
      'numAccounts': _accounts.length,
      'totalValue': totalValue,
      'totalCost': totalCost,
      'totalGainLoss': totalGainLoss,
      'totalGainLossPercent': totalGainLossPercent,
      'totalHoldings': totalHoldings,
      'uniqueSymbols': allSymbols.length,
      'symbols': allSymbols.toList(),
    };
  }

  /// Get allocation by account.
  Map<String, double> getAllocationByAccount() {
    final totalValue = _accounts.values.fold<double>(0.0, (sum, a) => sum + a.totalValue);
    if (totalValue == 0) return {};

    return Map.fromEntries(
      _accounts.values.map((a) => MapEntry(a.id, (a.totalValue / totalValue) * 100)),
    );
  }

  /// Get allocation by account type.
  Map<AccountType, double> getAllocationByType() {
    final totalValue = _accounts.values.fold<double>(0.0, (sum, a) => sum + a.totalValue);
    if (totalValue == 0) return {};

    final byType = <AccountType, double>{};
    for (final account in _accounts.values) {
      byType[account.type] = (byType[account.type] ?? 0) + account.totalValue;
    }

    return Map.fromEntries(
      byType.entries.map((e) => MapEntry(e.key, (e.value / totalValue) * 100)),
    );
  }

  /// Convert to JSON list for serialization.
  List<Map<String, dynamic>> toJson() {
    return _accounts.values.map((a) => a.toJson()).toList();
  }

  /// Create an AccountManager from JSON list.
  ///
  /// Args:
  ///   jsonList: List of account JSON maps
  ///
  /// Returns:
  ///   AccountManager instance
  static AccountManager fromJson(List<dynamic> jsonList) {
    final manager = AccountManager();
    for (final json in jsonList) {
      manager.addAccount(Account.fromJson(json as Map<String, dynamic>));
    }
    return manager;
  }
}
