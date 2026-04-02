import 'package:test/test.dart';
import 'package:investment_manager/src/tax_lot.dart';

void main() {
  group('TaxLot', () {
    test('constructor uppercases symbol', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'aapl',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime(2020, 1, 1),
      );
      expect(lot.symbol, 'AAPL');
    });

    test('remainingShares defaults to shares', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime(2020, 1, 1),
      );
      expect(lot.remainingShares, 10);
    });

    test('costPerShare calculation', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime(2020, 1, 1),
      );
      expect(lot.costPerShare, 150.0);
    });

    test('costPerShare is 0 for zero shares', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 0, costBasis: 0,
        purchaseDate: DateTime(2020, 1, 1),
      );
      expect(lot.costPerShare, 0);
    });

    test('isLongTerm is true for purchases over 365 days ago', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime.now().subtract(const Duration(days: 400)),
      );
      expect(lot.isLongTerm, isTrue);
    });

    test('isLongTerm is false for recent purchases', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(lot.isLongTerm, isFalse);
    });

    test('hasRemainingShares', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime(2020, 1, 1),
      );
      expect(lot.hasRemainingShares, isTrue);
      lot.remainingShares = 0;
      expect(lot.hasRemainingShares, isFalse);
    });

    test('remainingCostBasis', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'AAPL',
        shares: 10, costBasis: 1500,
        purchaseDate: DateTime(2020, 1, 1),
        remainingShares: 5,
      );
      expect(lot.remainingCostBasis, 750.0);
    });

    test('JSON round-trip', () {
      final lot = TaxLot(
        id: 'lot1', transactionId: 'tx1', symbol: 'MSFT',
        shares: 20, costBasis: 6000,
        purchaseDate: DateTime(2024, 6, 15),
        remainingShares: 15,
      );
      final json = lot.toJson();
      final restored = TaxLot.fromJson(json);
      expect(restored.id, 'lot1');
      expect(restored.symbol, 'MSFT');
      expect(restored.shares, 20);
      expect(restored.costBasis, 6000);
      expect(restored.remainingShares, 15);
    });
  });

  group('TaxLotManager', () {
    late TaxLotManager manager;

    TaxLot _makeLot({
      required String id,
      double shares = 10,
      double costBasis = 1500,
      DateTime? purchaseDate,
    }) {
      return TaxLot(
        id: id, transactionId: 'tx_$id', symbol: 'AAPL',
        shares: shares, costBasis: costBasis,
        purchaseDate: purchaseDate ?? DateTime(2020, 1, 1),
      );
    }

    setUp(() {
      manager = TaxLotManager();
    });

    test('addLot and getLots', () {
      manager.addLot(_makeLot(id: 'lot1'));
      expect(manager.getLots('AAPL').length, 1);
      expect(manager.getLots('GOOGL'), isEmpty);
    });

    test('getAvailableLots excludes fully sold lots', () {
      final lot = _makeLot(id: 'lot1');
      lot.remainingShares = 0;
      manager.addLot(lot);
      manager.addLot(_makeLot(id: 'lot2'));
      expect(manager.getAvailableLots('AAPL').length, 1);
    });

    test('getTotalShares sums remaining shares', () {
      manager.addLot(_makeLot(id: 'lot1', shares: 10));
      manager.addLot(_makeLot(id: 'lot2', shares: 5));
      expect(manager.getTotalShares('AAPL'), 15);
    });

    test('getTotalCostBasis sums remaining cost basis', () {
      manager.addLot(_makeLot(id: 'lot1', shares: 10, costBasis: 1500));
      manager.addLot(_makeLot(id: 'lot2', shares: 5, costBasis: 1000));
      expect(manager.getTotalCostBasis('AAPL'), 2500);
    });

    test('symbols returns tracked symbols', () {
      manager.addLot(_makeLot(id: 'lot1'));
      manager.addLot(TaxLot(
        id: 'lot2', transactionId: 'tx2', symbol: 'GOOGL',
        shares: 5, costBasis: 1000, purchaseDate: DateTime(2020, 1, 1),
      ));
      expect(manager.symbols, containsAll(['AAPL', 'GOOGL']));
    });

    group('calculateCostBasis', () {
      test('FIFO uses oldest lots first', () {
        manager.addLot(_makeLot(
          id: 'old', shares: 10, costBasis: 1000,
          purchaseDate: DateTime(2020, 1, 1),
        ));
        manager.addLot(_makeLot(
          id: 'new', shares: 10, costBasis: 2000,
          purchaseDate: DateTime(2025, 1, 1),
        ));
        final result = manager.calculateCostBasis(
          symbol: 'AAPL', sharesToSell: 5,
          method: CostBasisMethod.fifo,
        );
        expect(result.lotsUsed.length, 1);
        expect(result.lotsUsed.first.lot.id, 'old');
        expect(result.totalCostBasis, 500.0);
      });

      test('LIFO uses newest lots first', () {
        manager.addLot(_makeLot(
          id: 'old', shares: 10, costBasis: 1000,
          purchaseDate: DateTime(2020, 1, 1),
        ));
        manager.addLot(_makeLot(
          id: 'new', shares: 10, costBasis: 2000,
          purchaseDate: DateTime(2025, 1, 1),
        ));
        final result = manager.calculateCostBasis(
          symbol: 'AAPL', sharesToSell: 5,
          method: CostBasisMethod.lifo,
        );
        expect(result.lotsUsed.first.lot.id, 'new');
        expect(result.totalCostBasis, 1000.0);
      });

      test('HIFO uses highest cost lots first', () {
        manager.addLot(_makeLot(
          id: 'cheap', shares: 10, costBasis: 1000,
          purchaseDate: DateTime(2020, 1, 1),
        ));
        manager.addLot(_makeLot(
          id: 'expensive', shares: 10, costBasis: 3000,
          purchaseDate: DateTime(2022, 1, 1),
        ));
        final result = manager.calculateCostBasis(
          symbol: 'AAPL', sharesToSell: 5,
          method: CostBasisMethod.hifo,
        );
        expect(result.lotsUsed.first.lot.id, 'expensive');
        expect(result.totalCostBasis, 1500.0);
      });

      test('spans multiple lots when needed', () {
        manager.addLot(_makeLot(
          id: 'lot1', shares: 5, costBasis: 500,
          purchaseDate: DateTime(2020, 1, 1),
        ));
        manager.addLot(_makeLot(
          id: 'lot2', shares: 10, costBasis: 1500,
          purchaseDate: DateTime(2021, 1, 1),
        ));
        final result = manager.calculateCostBasis(
          symbol: 'AAPL', sharesToSell: 8,
          method: CostBasisMethod.fifo,
        );
        expect(result.lotsUsed.length, 2);
        expect(result.lotsUsed[0].sharesUsed, 5);
        expect(result.lotsUsed[1].sharesUsed, 3);
      });

      test('throws ArgumentError for insufficient shares', () {
        manager.addLot(_makeLot(id: 'lot1', shares: 5));
        expect(
          () => manager.calculateCostBasis(
            symbol: 'AAPL', sharesToSell: 10,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    test('executeSale mutates remainingShares', () {
      manager.addLot(_makeLot(id: 'lot1', shares: 10, costBasis: 1500));
      manager.executeSale(symbol: 'AAPL', sharesToSell: 3);
      final lots = manager.getLots('AAPL');
      expect(lots.first.remainingShares, 7);
    });

    test('getUnrealizedGains computes per-lot gains', () {
      manager.addLot(_makeLot(id: 'lot1', shares: 10, costBasis: 1000));
      final gains = manager.getUnrealizedGains('AAPL', 150.0);
      expect(gains.length, 1);
      expect(gains.first.currentValue, 1500.0);
      expect(gains.first.costBasis, 1000.0);
      expect(gains.first.gainLoss, 500.0);
    });

    test('JSON round-trip', () {
      manager.addLot(_makeLot(id: 'lot1', shares: 10, costBasis: 1500));
      manager.addLot(TaxLot(
        id: 'lot2', transactionId: 'tx2', symbol: 'GOOGL',
        shares: 5, costBasis: 1000, purchaseDate: DateTime(2020, 1, 1),
      ));
      final json = manager.toJson();
      final restored = TaxLotManager.fromJson(json);
      expect(restored.getLots('AAPL').length, 1);
      expect(restored.getLots('GOOGL').length, 1);
    });
  });

  group('CostBasisResult', () {
    test('averageCostPerShare', () {
      final result = CostBasisResult(
        totalCostBasis: 1500,
        lotsUsed: [],
        shortTermBasis: 500,
        longTermBasis: 1000,
        shortTermShares: 5,
        longTermShares: 10,
      );
      expect(result.averageCostPerShare, 100.0);
    });

    test('averageCostPerShare is 0 for zero shares', () {
      final result = CostBasisResult(
        totalCostBasis: 0,
        lotsUsed: [],
        shortTermBasis: 0,
        longTermBasis: 0,
        shortTermShares: 0,
        longTermShares: 0,
      );
      expect(result.averageCostPerShare, 0);
    });
  });
}
