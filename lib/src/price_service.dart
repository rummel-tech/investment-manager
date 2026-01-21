/// Price data services for fetching real-time and historical stock prices.
library price_service;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'portfolio.dart';

/// Represents a price quote for a stock.
class PriceQuote {
  /// Stock ticker symbol
  final String symbol;

  /// Current price
  final double price;

  /// Price change from previous close
  final double? change;

  /// Price change percentage
  final double? changePercent;

  /// Timestamp of the quote
  final DateTime timestamp;

  /// Source of the price data
  final String source;

  /// Previous close price
  final double? previousClose;

  /// Day's high price
  final double? high;

  /// Day's low price
  final double? low;

  /// Trading volume
  final int? volume;

  PriceQuote({
    required this.symbol,
    required this.price,
    this.change,
    this.changePercent,
    required this.timestamp,
    required this.source,
    this.previousClose,
    this.high,
    this.low,
    this.volume,
  });

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'previousClose': previousClose,
      'high': high,
      'low': low,
      'volume': volume,
    };
  }

  @override
  String toString() {
    final changeStr = change != null
        ? ' (${change! >= 0 ? '+' : ''}\$${change!.toStringAsFixed(2)})'
        : '';
    return '$symbol: \$${price.toStringAsFixed(2)}$changeStr';
  }
}

/// Represents historical price data for a single day.
class HistoricalPrice {
  /// Stock ticker symbol
  final String symbol;

  /// Date of the price data
  final DateTime date;

  /// Opening price
  final double open;

  /// Day's high price
  final double high;

  /// Day's low price
  final double low;

  /// Closing price
  final double close;

  /// Adjusted closing price (for dividends/splits)
  final double? adjustedClose;

  /// Trading volume
  final int volume;

  HistoricalPrice({
    required this.symbol,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.adjustedClose,
    required this.volume,
  });

  /// Convert to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'date': date.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'adjustedClose': adjustedClose,
      'volume': volume,
    };
  }
}

/// Exception thrown when a price service operation fails.
class PriceServiceException implements Exception {
  /// Error message
  final String message;

  /// Original error (if any)
  final Object? cause;

  PriceServiceException(this.message, [this.cause]);

  @override
  String toString() => 'PriceServiceException: $message';
}

/// Abstract interface for price data services.
abstract class PriceService {
  /// Get current price quote for a symbol.
  Future<PriceQuote> getQuote(String symbol);

  /// Get price quotes for multiple symbols.
  Future<List<PriceQuote>> getBatchQuotes(List<String> symbols);

  /// Get historical prices for a symbol.
  Future<List<HistoricalPrice>> getHistoricalPrices({
    required String symbol,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Update all stock prices in a portfolio.
  Future<void> updatePortfolioPrices(Portfolio portfolio);
}

/// Mock price service for testing.
class MockPriceService implements PriceService {
  /// Predefined prices for testing
  final Map<String, double> _mockPrices;

  /// Create a mock price service.
  ///
  /// Args:
  ///   mockPrices: Map of symbol to price (optional)
  MockPriceService({Map<String, double>? mockPrices})
      : _mockPrices = mockPrices ?? _defaultMockPrices;

  static const _defaultMockPrices = {
    'AAPL': 175.50,
    'GOOGL': 140.25,
    'MSFT': 378.90,
    'AMZN': 178.15,
    'TSLA': 248.50,
    'META': 505.75,
    'NVDA': 875.30,
    'SPY': 475.80,
    'VOO': 437.20,
    'QQQ': 405.60,
    'VTI': 245.40,
  };

  /// Set a mock price for a symbol.
  void setPrice(String symbol, double price) {
    _mockPrices[symbol.toUpperCase()] = price;
  }

  @override
  Future<PriceQuote> getQuote(String symbol) async {
    final upperSymbol = symbol.toUpperCase();
    final price = _mockPrices[upperSymbol];

    if (price == null) {
      throw PriceServiceException('Symbol not found: $symbol');
    }

    // Simulate some market movement
    final change = (price * 0.01 * (DateTime.now().second % 10 - 5) / 5);

    return PriceQuote(
      symbol: upperSymbol,
      price: price,
      change: change,
      changePercent: (change / price) * 100,
      timestamp: DateTime.now(),
      source: 'mock',
      previousClose: price - change,
    );
  }

  @override
  Future<List<PriceQuote>> getBatchQuotes(List<String> symbols) async {
    final quotes = <PriceQuote>[];
    for (final symbol in symbols) {
      try {
        quotes.add(await getQuote(symbol));
      } catch (e) {
        // Skip symbols not found
      }
    }
    return quotes;
  }

  @override
  Future<List<HistoricalPrice>> getHistoricalPrices({
    required String symbol,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final upperSymbol = symbol.toUpperCase();
    final basePrice = _mockPrices[upperSymbol] ?? 100.0;
    final prices = <HistoricalPrice>[];

    var currentDate = startDate;
    var price = basePrice * 0.95; // Start slightly lower

    while (currentDate.isBefore(endDate)) {
      // Skip weekends
      if (currentDate.weekday != DateTime.saturday &&
          currentDate.weekday != DateTime.sunday) {
        // Simulate daily price movement
        final dailyChange = (price * 0.02 * (currentDate.day % 10 - 5) / 10);
        price += dailyChange;

        final high = price * 1.01;
        final low = price * 0.99;

        prices.add(HistoricalPrice(
          symbol: upperSymbol,
          date: currentDate,
          open: price - dailyChange / 2,
          high: high,
          low: low,
          close: price,
          volume: 1000000 + (currentDate.day * 100000),
        ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return prices;
  }

  @override
  Future<void> updatePortfolioPrices(Portfolio portfolio) async {
    for (final stock in portfolio.holdings) {
      try {
        final quote = await getQuote(stock.symbol);
        portfolio.updateStockPrice(stock.symbol, quote.price);
      } catch (e) {
        // Skip symbols not found in mock data
      }
    }
  }
}

/// Alpha Vantage API implementation.
class AlphaVantageService implements PriceService {
  /// API key for Alpha Vantage
  final String apiKey;

  /// Base URL for API
  static const _baseUrl = 'https://www.alphavantage.co/query';

  /// HTTP client
  final http.Client _client;

  /// Rate limiting: track last request time
  DateTime? _lastRequestTime;

  /// Minimum delay between requests (free tier: 5/minute)
  static const _minRequestDelay = Duration(milliseconds: 12100);

  /// Create an Alpha Vantage service.
  ///
  /// Args:
  ///   apiKey: Your Alpha Vantage API key
  ///   client: HTTP client (optional, for testing)
  AlphaVantageService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Wait for rate limiting.
  Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestDelay) {
        await Future.delayed(_minRequestDelay - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  @override
  Future<PriceQuote> getQuote(String symbol) async {
    await _waitForRateLimit();

    final uri = Uri.parse('$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw PriceServiceException(
        'API request failed with status ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('Error Message')) {
      throw PriceServiceException(data['Error Message'] as String);
    }

    if (data.containsKey('Note')) {
      throw PriceServiceException('Rate limit exceeded: ${data['Note']}');
    }

    final quote = data['Global Quote'] as Map<String, dynamic>?;
    if (quote == null || quote.isEmpty) {
      throw PriceServiceException('No data returned for symbol: $symbol');
    }

    final price = double.parse(quote['05. price'] as String);
    final change = double.parse(quote['09. change'] as String);
    final changePercent = double.parse(
      (quote['10. change percent'] as String).replaceAll('%', ''),
    );

    return PriceQuote(
      symbol: symbol.toUpperCase(),
      price: price,
      change: change,
      changePercent: changePercent,
      timestamp: DateTime.now(),
      source: 'alphavantage',
      previousClose: double.parse(quote['08. previous close'] as String),
      high: double.parse(quote['03. high'] as String),
      low: double.parse(quote['04. low'] as String),
      volume: int.parse(quote['06. volume'] as String),
    );
  }

  @override
  Future<List<PriceQuote>> getBatchQuotes(List<String> symbols) async {
    // Alpha Vantage doesn't have a batch endpoint on free tier
    // Process sequentially with rate limiting
    final quotes = <PriceQuote>[];
    for (final symbol in symbols) {
      try {
        quotes.add(await getQuote(symbol));
      } catch (e) {
        // Continue with other symbols on error
      }
    }
    return quotes;
  }

  @override
  Future<List<HistoricalPrice>> getHistoricalPrices({
    required String symbol,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _waitForRateLimit();

    final uri = Uri.parse(
      '$_baseUrl?function=TIME_SERIES_DAILY&symbol=$symbol&outputsize=full&apikey=$apiKey',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw PriceServiceException(
        'API request failed with status ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('Error Message')) {
      throw PriceServiceException(data['Error Message'] as String);
    }

    final timeSeries = data['Time Series (Daily)'] as Map<String, dynamic>?;
    if (timeSeries == null) {
      throw PriceServiceException('No historical data returned for: $symbol');
    }

    final prices = <HistoricalPrice>[];
    for (final entry in timeSeries.entries) {
      final date = DateTime.parse(entry.key);
      if (date.isAfter(startDate) && date.isBefore(endDate)) {
        final dayData = entry.value as Map<String, dynamic>;
        prices.add(HistoricalPrice(
          symbol: symbol.toUpperCase(),
          date: date,
          open: double.parse(dayData['1. open'] as String),
          high: double.parse(dayData['2. high'] as String),
          low: double.parse(dayData['3. low'] as String),
          close: double.parse(dayData['4. close'] as String),
          volume: int.parse(dayData['5. volume'] as String),
        ));
      }
    }

    // Sort by date ascending
    prices.sort((a, b) => a.date.compareTo(b.date));
    return prices;
  }

  @override
  Future<void> updatePortfolioPrices(Portfolio portfolio) async {
    for (final stock in portfolio.holdings) {
      try {
        final quote = await getQuote(stock.symbol);
        portfolio.updateStockPrice(stock.symbol, quote.price);
      } catch (e) {
        // Continue with other stocks on error
      }
    }
  }

  /// Dispose of resources.
  void dispose() {
    _client.close();
  }
}

/// Yahoo Finance API implementation (unofficial).
class YahooFinanceService implements PriceService {
  /// Base URL for API
  static const _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';

  /// HTTP client
  final http.Client _client;

  /// Create a Yahoo Finance service.
  ///
  /// Args:
  ///   client: HTTP client (optional, for testing)
  YahooFinanceService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<PriceQuote> getQuote(String symbol) async {
    final uri = Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d');
    final response = await _client.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
    });

    if (response.statusCode != 200) {
      throw PriceServiceException(
        'API request failed with status ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final chart = data['chart'] as Map<String, dynamic>?;
    final result = (chart?['result'] as List<dynamic>?)?.firstOrNull as Map<String, dynamic>?;

    if (result == null) {
      throw PriceServiceException('No data returned for symbol: $symbol');
    }

    final meta = result['meta'] as Map<String, dynamic>;
    final price = (meta['regularMarketPrice'] as num).toDouble();
    final previousClose = (meta['previousClose'] as num?)?.toDouble();
    final change = previousClose != null ? price - previousClose : null;

    return PriceQuote(
      symbol: symbol.toUpperCase(),
      price: price,
      change: change,
      changePercent: previousClose != null && previousClose > 0
          ? ((price - previousClose) / previousClose) * 100
          : null,
      timestamp: DateTime.now(),
      source: 'yahoo',
      previousClose: previousClose,
      high: (meta['regularMarketDayHigh'] as num?)?.toDouble(),
      low: (meta['regularMarketDayLow'] as num?)?.toDouble(),
      volume: (meta['regularMarketVolume'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<PriceQuote>> getBatchQuotes(List<String> symbols) async {
    // Process in parallel
    final futures = symbols.map((s) => getQuote(s).catchError((_) => null));
    final results = await Future.wait(futures);
    return results.whereType<PriceQuote>().toList();
  }

  @override
  Future<List<HistoricalPrice>> getHistoricalPrices({
    required String symbol,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final period1 = startDate.millisecondsSinceEpoch ~/ 1000;
    final period2 = endDate.millisecondsSinceEpoch ~/ 1000;

    final uri = Uri.parse(
      '$_baseUrl/$symbol?period1=$period1&period2=$period2&interval=1d',
    );
    final response = await _client.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
    });

    if (response.statusCode != 200) {
      throw PriceServiceException(
        'API request failed with status ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final chart = data['chart'] as Map<String, dynamic>?;
    final result = (chart?['result'] as List<dynamic>?)?.firstOrNull as Map<String, dynamic>?;

    if (result == null) {
      throw PriceServiceException('No data returned for symbol: $symbol');
    }

    final timestamps = (result['timestamp'] as List<dynamic>?)?.cast<int>() ?? [];
    final indicators = result['indicators'] as Map<String, dynamic>?;
    final quote = (indicators?['quote'] as List<dynamic>?)?.firstOrNull as Map<String, dynamic>?;

    if (quote == null) {
      return [];
    }

    final opens = (quote['open'] as List<dynamic>?)?.cast<num?>() ?? [];
    final highs = (quote['high'] as List<dynamic>?)?.cast<num?>() ?? [];
    final lows = (quote['low'] as List<dynamic>?)?.cast<num?>() ?? [];
    final closes = (quote['close'] as List<dynamic>?)?.cast<num?>() ?? [];
    final volumes = (quote['volume'] as List<dynamic>?)?.cast<num?>() ?? [];

    final prices = <HistoricalPrice>[];
    for (var i = 0; i < timestamps.length; i++) {
      if (opens[i] != null && closes[i] != null) {
        prices.add(HistoricalPrice(
          symbol: symbol.toUpperCase(),
          date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
          open: opens[i]!.toDouble(),
          high: highs[i]?.toDouble() ?? opens[i]!.toDouble(),
          low: lows[i]?.toDouble() ?? opens[i]!.toDouble(),
          close: closes[i]!.toDouble(),
          volume: volumes[i]?.toInt() ?? 0,
        ));
      }
    }

    return prices;
  }

  @override
  Future<void> updatePortfolioPrices(Portfolio portfolio) async {
    final symbols = portfolio.holdings.map((s) => s.symbol).toList();
    final quotes = await getBatchQuotes(symbols);

    for (final quote in quotes) {
      portfolio.updateStockPrice(quote.symbol, quote.price);
    }
  }

  /// Dispose of resources.
  void dispose() {
    _client.close();
  }
}

/// Factory for creating price services.
class PriceServiceFactory {
  /// Available price service providers.
  static const providers = ['mock', 'alphavantage', 'yahoo'];

  /// Create a price service.
  ///
  /// Args:
  ///   provider: Service provider name
  ///   apiKey: API key (required for alphavantage)
  ///
  /// Returns:
  ///   PriceService instance
  static PriceService create(String provider, {String? apiKey}) {
    switch (provider.toLowerCase()) {
      case 'alphavantage':
        if (apiKey == null) {
          throw ArgumentError('API key required for Alpha Vantage');
        }
        return AlphaVantageService(apiKey: apiKey);
      case 'yahoo':
        return YahooFinanceService();
      case 'mock':
      default:
        return MockPriceService();
    }
  }
}
