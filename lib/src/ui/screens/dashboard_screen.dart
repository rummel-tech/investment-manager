import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import '../../portfolio.dart';
import '../../stock.dart';
import '../../analyzer.dart';
import 'add_stock_screen.dart';
import 'analysis_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Portfolio _portfolio = Portfolio(name: 'My Portfolio');

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final holdings = _portfolio.holdings;
    final hasHoldings = holdings.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Manager'),
        actions: [
          if (hasHoldings)
            IconButton(
              icon: const Icon(Icons.insights),
              tooltip: 'Analysis',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalysisScreen(portfolio: _portfolio),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(RummelBlueSpacing.base),
        children: [
          _PortfolioSummaryCard(portfolio: _portfolio),
          const SizedBox(height: RummelBlueSpacing.base),
          if (hasHoldings) ...[
            Text('Holdings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            ...holdings.map((stock) => _StockTile(
                  stock: stock,
                  portfolioValue: _portfolio.totalValue,
                  onDelete: () {
                    _portfolio.removeStock(stock.symbol);
                    _refresh();
                  },
                  onUpdatePrice: () => _showUpdatePriceDialog(stock),
                )),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(RummelBlueSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.show_chart,
                        size: 64, color: RummelBlueColors.neutral400),
                    const SizedBox(height: RummelBlueSpacing.base),
                    Text(
                      'Add your first stock to get started',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: RummelBlueColors.neutral600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final stock = await Navigator.push<Stock>(
            context,
            MaterialPageRoute(builder: (_) => const AddStockScreen()),
          );
          if (stock != null) {
            _portfolio.addStock(stock);
            _refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
    );
  }

  void _showUpdatePriceDialog(Stock stock) {
    final controller =
        TextEditingController(text: stock.currentPrice.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${stock.symbol} Price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Price',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                stock.updatePrice(price);
                Navigator.pop(ctx);
                _refresh();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  final Portfolio portfolio;

  const _PortfolioSummaryCard({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final gainLoss = portfolio.totalGainLoss;
    final gainLossPct = portfolio.totalGainLossPercent;
    final isPositive = gainLoss >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RummelBlueSpacing.cardPaddingDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(portfolio.name,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            Text(
              '\$${portfolio.totalValue.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: RummelBlueSpacing.gapTight),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: isPositive
                      ? RummelBlueColors.success500
                      : RummelBlueColors.error500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}\$${gainLoss.toStringAsFixed(2)} (${gainLossPct.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPositive
                            ? RummelBlueColors.success500
                            : RummelBlueColors.error500,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(context, 'Cost Basis',
                    '\$${portfolio.totalCost.toStringAsFixed(2)}'),
                _miniStat(context, 'Holdings',
                    '${portfolio.holdings.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: RummelBlueColors.neutral600)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StockTile extends StatelessWidget {
  final Stock stock;
  final double portfolioValue;
  final VoidCallback onDelete;
  final VoidCallback onUpdatePrice;

  const _StockTile({
    required this.stock,
    required this.portfolioValue,
    required this.onDelete,
    required this.onUpdatePrice,
  });

  @override
  Widget build(BuildContext context) {
    final gainLoss = stock.gainLoss;
    final isPositive = gainLoss >= 0;
    final allocation = portfolioValue > 0
        ? (stock.currentValue / portfolioValue * 100)
        : 0.0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive
              ? RummelBlueColors.success50
              : RummelBlueColors.error50,
          child: Text(
            stock.symbol.length > 3
                ? stock.symbol.substring(0, 3)
                : stock.symbol,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? RummelBlueColors.success500
                  : RummelBlueColors.error500,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(stock.symbol,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('\$${stock.currentPrice.toStringAsFixed(2)}'),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                '${stock.shares.toStringAsFixed(2)} shares  •  ${allocation.toStringAsFixed(1)}%'),
            Text(
              '${isPositive ? '+' : ''}\$${gainLoss.toStringAsFixed(2)} (${stock.gainLossPercent.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: isPositive
                    ? RummelBlueColors.success500
                    : RummelBlueColors.error500,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'price') onUpdatePrice();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'price', child: Text('Update Price')),
            const PopupMenuItem(value: 'delete', child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}
