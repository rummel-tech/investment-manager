/// Dividend tracking and analysis.
library dividend;

/// Represents a dividend payment received.
class Dividend {
  /// Unique dividend identifier
  final String id;

  /// Account this dividend belongs to
  final String accountId;

  /// Stock ticker symbol
  final String symbol;

  /// Total dividend amount received
  final double amount;

  /// Number of shares held at time of dividend
  final double sharesHeld;

  /// Payment date (when cash was received)
  final DateTime payDate;

  /// Ex-dividend date
  final DateTime exDate;

  /// Whether the dividend was reinvested
  final bool reinvested;

  /// Transaction ID of reinvestment (if applicable)
  final String? reinvestTransactionId;

  /// Initialize a dividend record.
  ///
  /// Args:
  ///   id: Unique dividend identifier
  ///   accountId: Account this dividend belongs to
  ///   symbol: Stock ticker symbol
  ///   amount: Total dividend amount received
  ///   sharesHeld: Number of shares held at time of dividend
  ///   payDate: Payment date
  ///   exDate: Ex-dividend date
  ///   reinvested: Whether the dividend was reinvested
  ///   reinvestTransactionId: Transaction ID of reinvestment
  Dividend({
    required this.id,
    required this.accountId,
    required String symbol,
    required this.amount,
    required this.sharesHeld,
    required this.payDate,
    required this.exDate,
    this.reinvested = false,
    this.reinvestTransactionId,
  }) : symbol = symbol.toUpperCase();

  /// Get dividend per share.
  double get perShareAmount => sharesHeld > 0 ? amount / sharesHeld : 0;

  /// Get the year of the dividend payment.
  int get year => payDate.year;

  /// Get the quarter of the dividend payment.
  int get quarter => ((payDate.month - 1) ~/ 3) + 1;

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'symbol': symbol,
      'amount': amount,
      'sharesHeld': sharesHeld,
      'payDate': payDate.toIso8601String(),
      'exDate': exDate.toIso8601String(),
      'reinvested': reinvested,
      'reinvestTransactionId': reinvestTransactionId,
    };
  }

  /// Create a Dividend from JSON map.
  static Dividend fromJson(Map<String, dynamic> json) {
    return Dividend(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      symbol: json['symbol'] as String,
      amount: (json['amount'] as num).toDouble(),
      sharesHeld: (json['sharesHeld'] as num).toDouble(),
      payDate: DateTime.parse(json['payDate'] as String),
      exDate: DateTime.parse(json['exDate'] as String),
      reinvested: json['reinvested'] as bool? ?? false,
      reinvestTransactionId: json['reinvestTransactionId'] as String?,
    );
  }

  @override
  String toString() {
    return '$symbol: \$${amount.toStringAsFixed(2)} on ${payDate.toIso8601String().split('T')[0]}';
  }
}

/// Summary of dividends for a symbol.
class DividendSummary {
  /// Stock ticker symbol
  final String symbol;

  /// Total dividends received
  final double totalReceived;

  /// Total dividends reinvested
  final double totalReinvested;

  /// Total dividends taken as cash
  final double totalCash;

  /// Number of dividend payments
  final int paymentCount;

  /// Average per payment
  final double averagePerPayment;

  /// Most recent payment date
  final DateTime? lastPaymentDate;

  /// Estimated annual dividend (based on recent payments)
  final double? estimatedAnnual;

  DividendSummary({
    required this.symbol,
    required this.totalReceived,
    required this.totalReinvested,
    required this.totalCash,
    required this.paymentCount,
    required this.averagePerPayment,
    this.lastPaymentDate,
    this.estimatedAnnual,
  });

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'totalReceived': totalReceived,
      'totalReinvested': totalReinvested,
      'totalCash': totalCash,
      'paymentCount': paymentCount,
      'averagePerPayment': averagePerPayment,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'estimatedAnnual': estimatedAnnual,
    };
  }
}

/// Tracks and analyzes dividend payments.
class DividendTracker {
  /// Internal list of dividends
  final List<Dividend> _dividends = [];

  /// Add a dividend record.
  void addDividend(Dividend dividend) {
    _dividends.add(dividend);
    _dividends.sort((a, b) => b.payDate.compareTo(a.payDate));
  }

  /// Remove a dividend by ID.
  Dividend? removeDividend(String id) {
    final index = _dividends.indexWhere((d) => d.id == id);
    if (index != -1) {
      return _dividends.removeAt(index);
    }
    return null;
  }

  /// Get all dividends.
  List<Dividend> get all => List.unmodifiable(_dividends);

  /// Get total dividends received for a symbol.
  double getTotalDividends(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    return _dividends
        .where((d) => d.symbol == upperSymbol)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  /// Get dividends for a specific symbol.
  List<Dividend> getBySymbol(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    return _dividends.where((d) => d.symbol == upperSymbol).toList();
  }

  /// Get dividends within a date range.
  List<Dividend> getByDateRange(DateTime start, DateTime end) {
    return _dividends
        .where((d) => d.payDate.isAfter(start) && d.payDate.isBefore(end))
        .toList();
  }

  /// Get dividends for a specific year.
  List<Dividend> getByYear(int year) {
    return _dividends.where((d) => d.year == year).toList();
  }

  /// Get dividends for a specific account.
  List<Dividend> getByAccount(String accountId) {
    return _dividends.where((d) => d.accountId == accountId).toList();
  }

  /// Calculate yield on cost for a symbol.
  ///
  /// Args:
  ///   symbol: Stock ticker symbol
  ///   totalCost: Total cost basis for the position
  ///
  /// Returns:
  ///   Yield on cost as a percentage (annualized)
  double getYieldOnCost(String symbol, double totalCost) {
    if (totalCost <= 0) return 0;

    // Get last 12 months of dividends
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final recentDividends = getBySymbol(symbol)
        .where((d) => d.payDate.isAfter(oneYearAgo))
        .fold<double>(0.0, (sum, d) => sum + d.amount);

    return (recentDividends / totalCost) * 100;
  }

  /// Get annual dividend income.
  ///
  /// Args:
  ///   year: Year to calculate (defaults to current year)
  ///
  /// Returns:
  ///   Total dividend income for the year
  double getAnnualIncome({int? year}) {
    final targetYear = year ?? DateTime.now().year;
    return getByYear(targetYear).fold<double>(0.0, (sum, d) => sum + d.amount);
  }

  /// Get total dividends ever received.
  double get totalDividends => _dividends.fold<double>(0.0, (sum, d) => sum + d.amount);

  /// Get total dividends reinvested.
  double get totalReinvested => _dividends
      .where((d) => d.reinvested)
      .fold<double>(0.0, (sum, d) => sum + d.amount);

  /// Get total dividends taken as cash.
  double get totalCash => totalDividends - totalReinvested;

  /// Get dividend summary by symbol.
  Map<String, DividendSummary> getSummaryBySymbol() {
    final bySymbol = <String, List<Dividend>>{};
    for (final dividend in _dividends) {
      bySymbol.putIfAbsent(dividend.symbol, () => []);
      bySymbol[dividend.symbol]!.add(dividend);
    }

    return bySymbol.map((symbol, dividends) {
      final totalReceived = dividends.fold<double>(0.0, (sum, d) => sum + d.amount);
      final totalReinvested = dividends
          .where((d) => d.reinvested)
          .fold<double>(0.0, (sum, d) => sum + d.amount);
      final lastPayment = dividends.isNotEmpty ? dividends.first.payDate : null;

      // Estimate annual based on recent payments
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      final recentDividends = dividends
          .where((d) => d.payDate.isAfter(oneYearAgo))
          .fold<double>(0.0, (sum, d) => sum + d.amount);

      return MapEntry(
        symbol,
        DividendSummary(
          symbol: symbol,
          totalReceived: totalReceived,
          totalReinvested: totalReinvested,
          totalCash: totalReceived - totalReinvested,
          paymentCount: dividends.length,
          averagePerPayment: dividends.isNotEmpty ? totalReceived / dividends.length : 0,
          lastPaymentDate: lastPayment,
          estimatedAnnual: recentDividends,
        ),
      );
    });
  }

  /// Get monthly dividend income for a year.
  Map<int, double> getMonthlyIncome({int? year}) {
    final targetYear = year ?? DateTime.now().year;
    final monthly = <int, double>{};

    for (var month = 1; month <= 12; month++) {
      monthly[month] = 0;
    }

    for (final dividend in getByYear(targetYear)) {
      monthly[dividend.payDate.month] =
          (monthly[dividend.payDate.month] ?? 0) + dividend.amount;
    }

    return monthly;
  }

  /// Get quarterly dividend income for a year.
  Map<int, double> getQuarterlyIncome({int? year}) {
    final targetYear = year ?? DateTime.now().year;
    final quarterly = <int, double>{1: 0, 2: 0, 3: 0, 4: 0};

    for (final dividend in getByYear(targetYear)) {
      quarterly[dividend.quarter] =
          (quarterly[dividend.quarter] ?? 0) + dividend.amount;
    }

    return quarterly;
  }

  /// Convert to JSON list for serialization.
  List<Map<String, dynamic>> toJson() {
    return _dividends.map((d) => d.toJson()).toList();
  }

  /// Create a DividendTracker from JSON list.
  static DividendTracker fromJson(List<dynamic> jsonList) {
    final tracker = DividendTracker();
    for (final json in jsonList) {
      tracker.addDividend(Dividend.fromJson(json as Map<String, dynamic>));
    }
    return tracker;
  }
}
