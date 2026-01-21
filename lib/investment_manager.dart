/// Artemis Investment Manager Module
///
/// This module provides tools for managing investments, tracking stock holdings,
/// and providing guidance to maximize returns.
///
/// Features:
/// - Stock and portfolio management
/// - Multiple account support (brokerage, retirement, personal)
/// - Transaction tracking with full history
/// - Tax lot tracking with FIFO/LIFO cost basis methods
/// - Tax-loss harvesting analysis
/// - Dividend tracking and yield calculations
/// - Real-time price updates via Alpha Vantage or Yahoo Finance
/// - JSON file persistence
library investment_manager;

// Core models
export 'src/stock.dart';
export 'src/portfolio.dart';
export 'src/account.dart';
export 'src/transaction.dart';

// Tax features
export 'src/tax_lot.dart';
export 'src/tax_analyzer.dart';

// Dividend tracking
export 'src/dividend.dart';

// Analysis
export 'src/analyzer.dart';

// Price services
export 'src/price_service.dart';

// Data persistence
export 'src/repository.dart';
