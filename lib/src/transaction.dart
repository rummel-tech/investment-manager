/// Transaction tracking for investment accounts.
library transaction;

/// Types of transactions supported.
enum TransactionType {
  /// Purchase of shares
  buy,

  /// Sale of shares
  sell,

  /// Dividend payment received
  dividend,

  /// Dividend automatically reinvested
  dividendReinvest,

  /// Stock split adjustment
  split,

  /// Transfer between accounts
  transfer,
}

/// Represents a single investment transaction.
class Transaction {
  /// Unique transaction identifier
  final String id;

  /// Account this transaction belongs to
  final String accountId;

  /// Stock ticker symbol
  final String symbol;

  /// Type of transaction
  final TransactionType type;

  /// Number of shares involved
  final double shares;

  /// Price per share at transaction time
  final double pricePerShare;

  /// Transaction fees/commissions
  final double fees;

  /// Date and time of transaction
  final DateTime date;

  /// Optional notes or description
  final String? notes;

  /// Initialize a transaction.
  ///
  /// Args:
  ///   id: Unique transaction identifier
  ///   accountId: Account this transaction belongs to
  ///   symbol: Stock ticker symbol
  ///   type: Type of transaction
  ///   shares: Number of shares involved
  ///   pricePerShare: Price per share at transaction time
  ///   fees: Transaction fees/commissions (defaults to 0)
  ///   date: Date and time of transaction (defaults to now)
  ///   notes: Optional notes or description
  Transaction({
    required this.id,
    required this.accountId,
    required String symbol,
    required this.type,
    required this.shares,
    required this.pricePerShare,
    this.fees = 0.0,
    DateTime? date,
    this.notes,
  })  : symbol = symbol.toUpperCase(),
        date = date ?? DateTime.now();

  /// Calculate total transaction amount (shares * price).
  double get totalAmount => shares * pricePerShare;

  /// Calculate net amount after fees.
  ///
  /// For buys: totalAmount + fees (money spent)
  /// For sells: totalAmount - fees (money received)
  double get netAmount {
    if (type == TransactionType.sell) {
      return totalAmount - fees;
    }
    return totalAmount + fees;
  }

  /// Check if this is a purchase transaction.
  bool get isPurchase =>
      type == TransactionType.buy || type == TransactionType.dividendReinvest;

  /// Check if this is a sale transaction.
  bool get isSale => type == TransactionType.sell;

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'symbol': symbol,
      'type': type.name,
      'shares': shares,
      'pricePerShare': pricePerShare,
      'fees': fees,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create a Transaction from JSON map.
  ///
  /// Args:
  ///   json: Map containing transaction data
  ///
  /// Returns:
  ///   Transaction instance
  static Transaction fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      symbol: json['symbol'] as String,
      type: TransactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TransactionType.buy,
      ),
      shares: (json['shares'] as num).toDouble(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      fees: (json['fees'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() {
    return '${type.name.toUpperCase()} $shares $symbol @ \$${pricePerShare.toStringAsFixed(2)}';
  }
}

/// Manages a collection of transactions.
class TransactionHistory {
  /// Internal list of transactions
  final List<Transaction> _transactions = [];

  /// Add a transaction to the history.
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Remove a transaction by ID.
  ///
  /// Returns:
  ///   Removed transaction or null if not found
  Transaction? removeTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      return _transactions.removeAt(index);
    }
    return null;
  }

  /// Get all transactions.
  List<Transaction> get all => List.unmodifiable(_transactions);

  /// Get transactions for a specific symbol.
  List<Transaction> getBySymbol(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    return _transactions.where((t) => t.symbol == upperSymbol).toList();
  }

  /// Get transactions within a date range.
  List<Transaction> getByDateRange(DateTime start, DateTime end) {
    return _transactions
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  /// Get transactions of a specific type.
  List<Transaction> getByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  /// Get transactions for a specific account.
  List<Transaction> getByAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList();
  }

  /// Get all buy transactions (includes dividend reinvestment).
  List<Transaction> get purchases {
    return _transactions.where((t) => t.isPurchase).toList();
  }

  /// Get all sell transactions.
  List<Transaction> get sales {
    return _transactions.where((t) => t.isSale).toList();
  }

  /// Calculate total fees paid.
  double get totalFees {
    return _transactions.fold(0.0, (sum, t) => sum + t.fees);
  }

  /// Convert to JSON list for serialization.
  List<Map<String, dynamic>> toJson() {
    return _transactions.map((t) => t.toJson()).toList();
  }

  /// Create a TransactionHistory from JSON list.
  ///
  /// Args:
  ///   jsonList: List of transaction JSON maps
  ///
  /// Returns:
  ///   TransactionHistory instance
  static TransactionHistory fromJson(List<dynamic> jsonList) {
    final history = TransactionHistory();
    for (final json in jsonList) {
      history.addTransaction(Transaction.fromJson(json as Map<String, dynamic>));
    }
    return history;
  }
}
