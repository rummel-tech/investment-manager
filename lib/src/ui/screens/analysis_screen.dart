import 'package:flutter/material.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import '../../portfolio.dart';
import '../../analyzer.dart';

class AnalysisScreen extends StatelessWidget {
  final Portfolio portfolio;

  const AnalysisScreen({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final analysis = InvestmentAnalyzer.analyzePortfolio(portfolio);
    final diversification =
        InvestmentAnalyzer.getDiversificationScore(portfolio);
    final recommendations =
        InvestmentAnalyzer.generateRecommendations(portfolio);
    final highPerformers = InvestmentAnalyzer.identifyHighPerformers(portfolio);
    final underperformers =
        InvestmentAnalyzer.identifyUnderperformers(portfolio);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(RummelBlueSpacing.base),
        children: [
          _OverviewCard(analysis: analysis),
          const SizedBox(height: RummelBlueSpacing.base),
          _DiversificationCard(result: diversification),
          const SizedBox(height: RummelBlueSpacing.base),
          if (highPerformers.isNotEmpty) ...[
            _PerformersCard(
              title: 'High Performers',
              stocks: highPerformers,
              icon: Icons.trending_up,
              color: RummelBlueColors.success500,
            ),
            const SizedBox(height: RummelBlueSpacing.base),
          ],
          if (underperformers.isNotEmpty) ...[
            _PerformersCard(
              title: 'Underperformers',
              stocks: underperformers,
              icon: Icons.trending_down,
              color: RummelBlueColors.error500,
            ),
            const SizedBox(height: RummelBlueSpacing.base),
          ],
          _AllocationCard(portfolio: portfolio),
          const SizedBox(height: RummelBlueSpacing.base),
          if (recommendations.isNotEmpty) ...[
            Text('Recommendations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            ...recommendations.map((r) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline,
                        color: RummelBlueColors.warning500),
                    title: Text(r, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const _OverviewCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    if (analysis['status'] == 'empty') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(RummelBlueSpacing.cardPaddingDefault),
          child: Text(analysis['message'] as String),
        ),
      );
    }

    final best = analysis['best_performer'] as Map<String, dynamic>;
    final worst = analysis['worst_performer'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RummelBlueSpacing.cardPaddingDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            _row(context, 'Winners', '${analysis['winners']}'),
            _row(context, 'Losers', '${analysis['losers']}'),
            const Divider(),
            _row(
              context,
              'Best Performer',
              '${best['symbol']} (${(best['gain_loss_percent'] as double).toStringAsFixed(1)}%)',
              valueColor: RummelBlueColors.success500,
            ),
            _row(
              context,
              'Worst Performer',
              '${worst['symbol']} (${(worst['gain_loss_percent'] as double).toStringAsFixed(1)}%)',
              valueColor: RummelBlueColors.error500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  )),
        ],
      ),
    );
  }
}

class _DiversificationCard extends StatelessWidget {
  final DiversificationResult result;

  const _DiversificationCard({required this.result});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (result.score >= 70) {
      barColor = RummelBlueColors.success500;
    } else if (result.score >= 40) {
      barColor = RummelBlueColors.warning500;
    } else {
      barColor = RummelBlueColors.error500;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RummelBlueSpacing.cardPaddingDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Diversification',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('${result.score.toStringAsFixed(0)}/100',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: barColor)),
              ],
            ),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: result.score / 100,
                minHeight: 8,
                backgroundColor: RummelBlueColors.neutral200,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            Text(result.recommendation,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: RummelBlueColors.neutral600)),
          ],
        ),
      ),
    );
  }
}

class _PerformersCard extends StatelessWidget {
  final String title;
  final List stocks;
  final IconData icon;
  final Color color;

  const _PerformersCard({
    required this.title,
    required this.stocks,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RummelBlueSpacing.cardPaddingDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: RummelBlueSpacing.gapNormal),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            ...stocks.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.symbol,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${s.gainLossPercent >= 0 ? '+' : ''}${s.gainLossPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final Portfolio portfolio;

  const _AllocationCard({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final holdings = portfolio.holdings;
    final totalValue = portfolio.totalValue;
    if (holdings.isEmpty || totalValue == 0) return const SizedBox.shrink();

    final sorted = List.of(holdings)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RummelBlueSpacing.cardPaddingDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allocation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: RummelBlueSpacing.gapNormal),
            ...sorted.map((s) {
              final pct = s.currentValue / totalValue;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.symbol,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${(pct * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: RummelBlueColors.neutral200,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
