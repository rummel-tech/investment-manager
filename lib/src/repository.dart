/// Data persistence using JSON files.
library repository;

import 'dart:convert';
import 'dart:io';

import 'account.dart';
import 'transaction.dart';
import 'dividend.dart';
import 'tax_lot.dart';

/// Abstract repository interface for data persistence.
abstract class Repository<T> {
  /// Get an entity by ID.
  Future<T?> get(String id);

  /// Get all entities.
  Future<List<T>> getAll();

  /// Save an entity.
  Future<void> save(T entity);

  /// Delete an entity by ID.
  Future<void> delete(String id);

  /// Save multiple entities.
  Future<void> saveAll(List<T> entities);

  /// Delete all entities.
  Future<void> deleteAll();
}

/// JSON file-based repository implementation.
class JsonFileRepository<T> implements Repository<T> {
  /// Path to the JSON file.
  final String filePath;

  /// Function to convert JSON map to entity.
  final T Function(Map<String, dynamic>) fromJson;

  /// Function to convert entity to JSON map.
  final Map<String, dynamic> Function(T) toJson;

  /// Function to get entity ID.
  final String Function(T) getId;

  /// Internal cache of entities.
  Map<String, T>? _cache;

  /// Initialize a JSON file repository.
  ///
  /// Args:
  ///   filePath: Path to the JSON file
  ///   fromJson: Function to deserialize from JSON
  ///   toJson: Function to serialize to JSON
  ///   getId: Function to get entity ID
  JsonFileRepository({
    required this.filePath,
    required this.fromJson,
    required this.toJson,
    required this.getId,
  });

  /// Ensure cache is loaded.
  Future<Map<String, T>> _ensureCache() async {
    if (_cache == null) {
      _cache = {};
      final file = File(filePath);
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final jsonList = jsonDecode(content) as List<dynamic>;
          for (final json in jsonList) {
            final entity = fromJson(json as Map<String, dynamic>);
            _cache![getId(entity)] = entity;
          }
        } catch (e) {
          // File exists but is empty or invalid, start fresh
          _cache = {};
        }
      }
    }
    return _cache!;
  }

  /// Persist cache to file.
  Future<void> _persistCache() async {
    final cache = await _ensureCache();
    final file = File(filePath);

    // Ensure directory exists
    await file.parent.create(recursive: true);

    final jsonList = cache.values.map((e) => toJson(e)).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );
  }

  @override
  Future<T?> get(String id) async {
    final cache = await _ensureCache();
    return cache[id];
  }

  @override
  Future<List<T>> getAll() async {
    final cache = await _ensureCache();
    return cache.values.toList();
  }

  @override
  Future<void> save(T entity) async {
    final cache = await _ensureCache();
    cache[getId(entity)] = entity;
    await _persistCache();
  }

  @override
  Future<void> delete(String id) async {
    final cache = await _ensureCache();
    cache.remove(id);
    await _persistCache();
  }

  @override
  Future<void> saveAll(List<T> entities) async {
    final cache = await _ensureCache();
    for (final entity in entities) {
      cache[getId(entity)] = entity;
    }
    await _persistCache();
  }

  @override
  Future<void> deleteAll() async {
    _cache = {};
    await _persistCache();
  }

  /// Clear the in-memory cache (forces reload from file).
  void clearCache() {
    _cache = null;
  }
}

/// Repository for Account entities.
class AccountRepository extends JsonFileRepository<Account> {
  AccountRepository({required super.filePath})
      : super(
          fromJson: Account.fromJson,
          toJson: (account) => account.toJson(),
          getId: (account) => account.id,
        );

  /// Get accounts by type.
  Future<List<Account>> getByType(AccountType type) async {
    final all = await getAll();
    return all.where((a) => a.type == type).toList();
  }

  /// Get total value across all accounts.
  Future<double> getTotalValue() async {
    final all = await getAll();
    return all.fold<double>(0.0, (sum, a) => sum + a.totalValue);
  }
}

/// Repository for Transaction entities.
class TransactionRepository extends JsonFileRepository<Transaction> {
  TransactionRepository({required super.filePath})
      : super(
          fromJson: Transaction.fromJson,
          toJson: (transaction) => transaction.toJson(),
          getId: (transaction) => transaction.id,
        );

  /// Get transactions for an account.
  Future<List<Transaction>> getByAccount(String accountId) async {
    final all = await getAll();
    return all.where((t) => t.accountId == accountId).toList();
  }

  /// Get transactions for a symbol.
  Future<List<Transaction>> getBySymbol(String symbol) async {
    final all = await getAll();
    final upperSymbol = symbol.toUpperCase();
    return all.where((t) => t.symbol == upperSymbol).toList();
  }

  /// Get transactions within a date range.
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final all = await getAll();
    return all
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  /// Get transactions by type.
  Future<List<Transaction>> getByType(TransactionType type) async {
    final all = await getAll();
    return all.where((t) => t.type == type).toList();
  }
}

/// Repository for Dividend entities.
class DividendRepository extends JsonFileRepository<Dividend> {
  DividendRepository({required super.filePath})
      : super(
          fromJson: Dividend.fromJson,
          toJson: (dividend) => dividend.toJson(),
          getId: (dividend) => dividend.id,
        );

  /// Get dividends for a symbol.
  Future<List<Dividend>> getBySymbol(String symbol) async {
    final all = await getAll();
    final upperSymbol = symbol.toUpperCase();
    return all.where((d) => d.symbol == upperSymbol).toList();
  }

  /// Get dividends for an account.
  Future<List<Dividend>> getByAccount(String accountId) async {
    final all = await getAll();
    return all.where((d) => d.accountId == accountId).toList();
  }

  /// Get dividends for a year.
  Future<List<Dividend>> getByYear(int year) async {
    final all = await getAll();
    return all.where((d) => d.year == year).toList();
  }

  /// Get total dividends received.
  Future<double> getTotalDividends() async {
    final all = await getAll();
    return all.fold<double>(0.0, (sum, d) => sum + d.amount);
  }
}

/// Repository for TaxLot entities.
class TaxLotRepository extends JsonFileRepository<TaxLot> {
  TaxLotRepository({required super.filePath})
      : super(
          fromJson: TaxLot.fromJson,
          toJson: (lot) => lot.toJson(),
          getId: (lot) => lot.id,
        );

  /// Get lots for a symbol.
  Future<List<TaxLot>> getBySymbol(String symbol) async {
    final all = await getAll();
    final upperSymbol = symbol.toUpperCase();
    return all.where((l) => l.symbol == upperSymbol).toList();
  }

  /// Get lots with remaining shares.
  Future<List<TaxLot>> getAvailableLots(String symbol) async {
    final lots = await getBySymbol(symbol);
    return lots.where((l) => l.hasRemainingShares).toList();
  }

  /// Get lots by transaction ID.
  Future<List<TaxLot>> getByTransaction(String transactionId) async {
    final all = await getAll();
    return all.where((l) => l.transactionId == transactionId).toList();
  }
}

/// Manages all repositories for the investment manager.
class DataStore {
  /// Account repository
  final AccountRepository accounts;

  /// Transaction repository
  final TransactionRepository transactions;

  /// Dividend repository
  final DividendRepository dividends;

  /// Tax lot repository
  final TaxLotRepository taxLots;

  /// Base directory for all data files.
  final String baseDir;

  /// Initialize a data store.
  ///
  /// Args:
  ///   baseDir: Base directory for all data files
  DataStore({required this.baseDir})
      : accounts = AccountRepository(filePath: '$baseDir/accounts.json'),
        transactions = TransactionRepository(filePath: '$baseDir/transactions.json'),
        dividends = DividendRepository(filePath: '$baseDir/dividends.json'),
        taxLots = TaxLotRepository(filePath: '$baseDir/tax_lots.json');

  /// Create a data store with default directory.
  factory DataStore.defaultStore() {
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return DataStore(baseDir: '$homeDir/.investment_manager');
  }

  /// Clear all caches (forces reload from files).
  void clearAllCaches() {
    accounts.clearCache();
    transactions.clearCache();
    dividends.clearCache();
    taxLots.clearCache();
  }

  /// Delete all data.
  Future<void> deleteAllData() async {
    await accounts.deleteAll();
    await transactions.deleteAll();
    await dividends.deleteAll();
    await taxLots.deleteAll();
  }

  /// Export all data to a single JSON map.
  Future<Map<String, dynamic>> exportAll() async {
    return {
      'accounts': (await accounts.getAll()).map((a) => a.toJson()).toList(),
      'transactions': (await transactions.getAll()).map((t) => t.toJson()).toList(),
      'dividends': (await dividends.getAll()).map((d) => d.toJson()).toList(),
      'taxLots': (await taxLots.getAll()).map((l) => l.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import all data from a JSON map.
  Future<void> importAll(Map<String, dynamic> data) async {
    if (data['accounts'] != null) {
      await accounts.deleteAll();
      for (final json in data['accounts'] as List<dynamic>) {
        await accounts.save(Account.fromJson(json as Map<String, dynamic>));
      }
    }

    if (data['transactions'] != null) {
      await transactions.deleteAll();
      for (final json in data['transactions'] as List<dynamic>) {
        await transactions.save(Transaction.fromJson(json as Map<String, dynamic>));
      }
    }

    if (data['dividends'] != null) {
      await dividends.deleteAll();
      for (final json in data['dividends'] as List<dynamic>) {
        await dividends.save(Dividend.fromJson(json as Map<String, dynamic>));
      }
    }

    if (data['taxLots'] != null) {
      await taxLots.deleteAll();
      for (final json in data['taxLots'] as List<dynamic>) {
        await taxLots.save(TaxLot.fromJson(json as Map<String, dynamic>));
      }
    }
  }
}
