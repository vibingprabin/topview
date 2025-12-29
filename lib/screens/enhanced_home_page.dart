import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/portfolio_provider.dart';
import '../providers/market_provider.dart';
import '../services/nepse_api_service.dart';
import '../themes/broker_intel_theme.dart';
import '../widgets/ferrofluid_header.dart';
import 'holdings_page.dart';
import 'enhanced_transactions_page.dart';
import 'input_page.dart';

import '../widgets/market_mover_card.dart';

/// Enhanced Home Screen with Broker Intelligence Design
/// 
/// Features:
/// - Ferrofluid animation header
/// - Live NEPSE market data
/// - Portfolio summary with real-time prices
/// - Top gainers/losers carousel
/// - Modern card-based UI
class EnhancedHomePage extends StatefulWidget {
  const EnhancedHomePage({super.key});

  @override
  State<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends State<EnhancedHomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final biColors = context.biColors;

    return Scaffold(
      backgroundColor: biColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<MarketProvider>().refreshAllData();
            await context.read<PortfolioProvider>().fetchLiveShareData();
          },
          color: BrokerIntelTheme.midIntensity,
          backgroundColor: biColors.background,
          child: CustomScrollView(
            slivers: [
              // Ferrofluid Header with NEPSE Index
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    FerrofluidHeader(
                      height: 200,
                      blobCount: 18,
                      onTap: () {
                        // Show market details on tap
                        _showMarketDetails(context);
                      },
                    ),
                    // Overlay NEPSE Index Card
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildNepseIndexCard(),
                    ),
                  ],
                ),
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Market Status Badge
                      _buildMarketStatusBadge(),

                      const SizedBox(height: 20),

                      // Portfolio Summary Card
                      _buildPortfolioSummaryCard(),

                      const SizedBox(height: 20),

                      // Top Gainers Section
                      _buildTopGainersSection(),

                      const SizedBox(height: 20),

                      // Top Losers Section
                      _buildTopLosersSection(),

                      const SizedBox(height: 20),

                      // Holdings Preview
                      _buildHoldingsPreview(),

                      const SizedBox(height: 20),

                      // Recent Transactions
                      _buildTransactionsPreview(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNepseIndexCard() {
    return Consumer<MarketProvider>(
      builder: (context, market, child) {
        final index = market.nepseIndex;
        final isLoading = market.isLoading;
        final error = market.error;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading && index == null
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(BrokerIntelTheme.midIntensity),
                    ),
                  ),
                )
              : error != null && index == null
                  ? Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: BrokerIntelTheme.dangerRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Market data unavailable',
                            style: TextStyle(
                              fontSize: 13,
                              color: BrokerIntelTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BrokerIntelTheme.midIntensity.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: BrokerIntelTheme.midIntensity,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NEPSE INDEX',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BrokerIntelTheme.textCaption,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                index?.currentValue.toStringAsFixed(2) ?? '--',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: BrokerIntelTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (index?.isPositive ?? false)
                                    ? BrokerIntelTheme.successGreen.withOpacity(0.1)
                                    : BrokerIntelTheme.dangerRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${index?.isPositive ?? false ? '+' : ''}${index?.changePercent.toStringAsFixed(2) ?? '--'}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: (index?.isPositive ?? false)
                                      ? BrokerIntelTheme.successGreen
                                      : BrokerIntelTheme.dangerRed,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${index?.isPositive ?? false ? '+' : ''}${index?.change.toStringAsFixed(2) ?? '--'} pts',
                              style: const TextStyle(
                                fontSize: 11,
                                color: BrokerIntelTheme.textCaption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildMarketStatusBadge() {
    return Consumer<MarketProvider>(
      builder: (context, market, child) {
        final status = market.marketStatus;
        final isOpen = status == MarketStatus.open;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOpen
                ? BrokerIntelTheme.successGreen.withOpacity(0.1)
                : BrokerIntelTheme.neutralGray.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOpen
                      ? BrokerIntelTheme.successGreen
                      : BrokerIntelTheme.neutralGray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOpen ? 'MARKET OPEN' : 'MARKET CLOSED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOpen
                      ? BrokerIntelTheme.successGreen
                      : BrokerIntelTheme.neutralGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSummaryCard() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final totalInvestment = _calculateTotalInvestment(portfolio);
        final totalCurrentValue = _calculateTotalCurrentValue(portfolio);
        final unrealizedPL = totalCurrentValue - totalInvestment;
        final unrealizedPLPercent = totalInvestment > 0
            ? (unrealizedPL / totalInvestment) * 100
            : 0.0;

        return _buildSectionCard(
          title: 'Portfolio Summary',
          child: Column(
            children: [
              // Total Value Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Value',
                    style: TextStyle(
                      fontSize: 13,
                      color: BrokerIntelTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${totalCurrentValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BrokerIntelTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // P/L Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Unrealized P/L',
                    style: TextStyle(
                      fontSize: 13,
                      color: BrokerIntelTheme.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${unrealizedPL.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: unrealizedPL >= 0
                              ? BrokerIntelTheme.successGreen
                              : BrokerIntelTheme.dangerRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: unrealizedPL >= 0
                              ? BrokerIntelTheme.successGreen.withOpacity(0.1)
                              : BrokerIntelTheme.dangerRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${unrealizedPL >= 0 ? '+' : ''}${unrealizedPLPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: unrealizedPL >= 0
                                ? BrokerIntelTheme.successGreen
                                : BrokerIntelTheme.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Secondary Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Holdings', '${portfolio.holdings.length}'),
                  _buildStatItem(
                    'Invested',
                    '₹${totalInvestment.toStringAsFixed(0)}',
                  ),
                  _buildStatItem(
                    'Realized P/L',
                    '₹${portfolio.realizedProfitLoss.toStringAsFixed(0)}',
                    valueColor: portfolio.realizedProfitLoss >= 0
                        ? BrokerIntelTheme.successGreen
                        : BrokerIntelTheme.dangerRed,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: BrokerIntelTheme.textCaption,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? BrokerIntelTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopGainersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Gainers',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: BrokerIntelTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full market page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<MarketProvider>(
          builder: (context, market, child) {
            final gainers = market.topGainers.take(3).toList();

            if (gainers.isEmpty) {
              return _buildEmptyMoversCard(
                isLoading: market.isLoading,
                error: market.error,
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: gainers.length,
                itemExtent: 140,
                itemBuilder: (context, index) {
                  final mover = gainers[index];
                  return MarketMoverCard(
                    symbol: mover.symbol,
                    name: mover.name,
                    changePercent: mover.changePercent,
                    isGainer: true,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopLosersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Losers',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: BrokerIntelTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full market page
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<MarketProvider>(
          builder: (context, market, child) {
            final losers = market.topLosers.take(3).toList();

            if (losers.isEmpty) {
              return _buildEmptyMoversCard(
                isLoading: market.isLoading,
                error: market.error,
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: losers.length,
                itemExtent: 140,
                itemBuilder: (context, index) {
                  final mover = losers[index];
                  return MarketMoverCard(
                    symbol: mover.symbol,
                    name: mover.name,
                    changePercent: mover.changePercent,
                    isGainer: false,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyMoversCard({required bool isLoading, String? error}) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: BrokerIntelTheme.gridLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: BrokerIntelTheme.textCaption,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error != null ? 'Data unavailable' : 'No data',
                    style: const TextStyle(
                      fontSize: 13,
                      color: BrokerIntelTheme.textCaption,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHoldingsPreview() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final holdings = portfolio.holdings.take(3).toList();

        return _buildSectionCard(
          title: 'Holdings',
          action: holdings.length > 3
              ? TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HoldingsPage(),
                      ),
                    );
                  },
                  child: const Text('See All'),
                )
              : null,
          child: holdings.isEmpty
              ? _buildEmptyState(
                  icon: Icons.pie_chart_outline,
                  message: 'No holdings yet',
                  action: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InputPage(),
                        ),
                      );
                    },
                    child: const Text('Add Transaction'),
                  ),
                )
              : Column(
                  children: holdings.asMap().entries.map((entry) {
                    final index = entry.key;
                    final holding = entry.value;
                    final isLast = index == holdings.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: BrokerIntelTheme.midIntensity.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                holding.symbol.substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: BrokerIntelTheme.midIntensity,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            holding.symbol,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${holding.quantity} shares',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BrokerIntelTheme.textCaption,
                            ),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₹${holding.currentValue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                                Text(
                                  '${holding.unrealizedPLPercentage >= 0 ? '+' : ''}${holding.unrealizedPLPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: holding.unrealizedPL >= 0
                                        ? BrokerIntelTheme.successGreen
                                        : BrokerIntelTheme.dangerRed,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isLast) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildTransactionsPreview() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final transactions = portfolio.transactions.take(3).toList();

        return _buildSectionCard(
          title: 'Recent Transactions',
          action: transactions.length > 3
              ? TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnhancedTransactionsPage(),
                      ),
                    );
                  },
                  child: const Text('See All'),
                )
              : null,
          child: transactions.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'No transactions yet',
                )
              : Column(
                  children: transactions.reversed.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final txn = entry.value;
                    final isLast = index == transactions.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: txn.transactionType == 'Purchased'
                                  ? BrokerIntelTheme.dangerRed.withOpacity(0.1)
                                  : BrokerIntelTheme.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              txn.transactionType == 'Purchased'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: txn.transactionType == 'Purchased'
                                  ? BrokerIntelTheme.dangerRed
                                  : BrokerIntelTheme.successGreen,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${txn.symbol} - ${txn.transactionType}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy').format(txn.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: BrokerIntelTheme.textCaption,
                            ),
                          ),
                          trailing: Text(
                            '₹${(txn.quantity * txn.price).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!isLast) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: BrokerIntelTheme.textPrimary,
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: BrokerIntelTheme.textCaption.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: BrokerIntelTheme.textCaption.withOpacity(0.7),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }

  void _showMarketDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrokerIntelTheme.gridLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Market Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<MarketProvider>(
              builder: (context, market, child) {
                final summary = market.summary;
                if (summary == null) {
                  return const Text('No market data available');
                }

                return Column(
                  children: [
                    _buildMarketDetailRow('Total Turnover',
                        '₹${(summary.totalTurnover / 1000000).toStringAsFixed(1)}M'),
                    _buildMarketDetailRow('Total Trades',
                        summary.totalTrades.toString()),
                    _buildMarketDetailRow('Advances', summary.advanceCount.toString()),
                    _buildMarketDetailRow('Declines', summary.declineCount.toString()),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: BrokerIntelTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalInvestment(PortfolioProvider portfolio) {
    return portfolio.holdings.fold(
      0.0,
      (sum, h) => sum + h.investedValue,
    );
  }

  double _calculateTotalCurrentValue(PortfolioProvider portfolio) {
    return portfolio.holdings.fold(
      0.0,
      (sum, h) => sum + h.currentValue,
    );
  }
}
