import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topview/models/portfolio_analysis.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/themes/broker_intel_theme.dart';
import 'package:topview/themes/ferrofluid/ferrofluid.dart';

/// Portfolio Analyser Page
/// 
/// Provides comprehensive portfolio analytics including:
/// - Overall portfolio summary (total investment, current value, P/L)
/// - Individual trade analysis with holding period
/// - Best and worst performing stocks
/// - Trade timeline
class PortfolioAnalyserPage extends StatefulWidget {
  const PortfolioAnalyserPage({super.key});

  @override
  State<PortfolioAnalyserPage> createState() => _PortfolioAnalyserPageState();
}

class _PortfolioAnalyserPageState extends State<PortfolioAnalyserPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biColors = context.biColors;

    return Scaffold(
      backgroundColor: biColors.background,
      appBar: AppBar(
        title: const Text('Portfolio Analyser'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Summary'),
            Tab(icon: Icon(Icons.trending_up), text: 'Holdings'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
        ),
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.holdings.isEmpty && provider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: biColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No portfolio data available',
                    style: TextStyle(fontSize: 18, color: biColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add transactions to see analytics',
                    style: TextStyle(fontSize: 14, color: biColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(context, provider),
              _buildHoldingsAnalysisTab(context, provider),
              _buildTimelineTab(context, provider),
            ],
          );
        },
      ),
    );
  }

  /// Summary tab with overall portfolio metrics
  Widget _buildSummaryTab(BuildContext context, PortfolioProvider provider) {
    final biColors = context.biColors;
    final holdings = provider.holdings;
    final transactions = provider.transactions;
    final analysis = provider.portfolioAnalysis;

    // Calculate summary metrics
    double totalInvested = holdings.fold(0.0, (sum, h) => sum + h.investedValue);
    double currentValue = holdings.fold(0.0, (sum, h) => sum + h.currentValue);
    double unrealizedPL = analysis?.totalUnrealizedPnL ?? (currentValue - totalInvested);
    double unrealizedPLPercent = totalInvested > 0 ? (unrealizedPL / totalInvested) * 100 : 0;
    double realizedPL = analysis?.totalRealizedPnL ?? provider.realizedProfitLoss;

    // Find best and worst performers from stockPnL analysis
    final stockPnLs = analysis?.stockPnL ?? [];
    List<StockPnL> sortedStockPnLs = List.from(stockPnLs)
      ..sort((a, b) => b.totalPnL.compareTo(a.totalPnL));
    
    StockPnL? bestPerformer = sortedStockPnLs.isNotEmpty ? sortedStockPnLs.first : null;
    StockPnL? worstPerformer = sortedStockPnLs.isNotEmpty ? sortedStockPnLs.last : null;

    // Count buy/sell transactions
    int buyCount = transactions.where((t) => t.transactionType == 'Purchased').length;
    int sellCount = transactions.where((t) => t.transactionType == 'Sold').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Portfolio Value Card
          _buildMetricCard(
            context,
            title: 'Portfolio Overview',
            icon: Icons.account_balance_wallet,
            children: [
              _buildMetricRow('Total Invested', 'Rs. ${_formatNumber(totalInvested)}', biColors.textPrimary),
              _buildMetricRow('Current Value', 'Rs. ${_formatNumber(currentValue)}', biColors.textPrimary),
              const Divider(),
              _buildMetricRow(
                'Unrealized P/L (FIFO)',
                '${unrealizedPL >= 0 ? '+' : ''}Rs. ${_formatNumber(unrealizedPL)} (${unrealizedPLPercent.toStringAsFixed(2)}%)',
                unrealizedPL >= 0 ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed,
              ),
              _buildMetricRow(
                'Realized P/L (FIFO)',
                '${realizedPL >= 0 ? '+' : ''}Rs. ${_formatNumber(realizedPL)}',
                realizedPL >= 0 ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed,
              ),
              const Divider(),
              _buildMetricRow(
                'Total P/L',
                '${(unrealizedPL + realizedPL) >= 0 ? '+' : ''}Rs. ${_formatNumber(unrealizedPL + realizedPL)}',
                (unrealizedPL + realizedPL) >= 0 ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Monthly Realized P/L Chart
          if (analysis != null && analysis.monthlyPnL.isNotEmpty) ...[
            _buildMetricCard(
              context,
              title: 'Monthly Realized P/L',
              icon: Icons.calendar_month,
              children: [
                const SizedBox(height: 8),
                _buildMonthlyPnLChart(context, analysis.monthlyPnL),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Portfolio Statistics
          _buildMetricCard(
            context,
            title: 'Portfolio Statistics',
            icon: Icons.bar_chart,
            children: [
              _buildMetricRow('Total Holdings', '${holdings.length} stocks', biColors.textPrimary),
              _buildMetricRow('Total Transactions', '${transactions.length}', biColors.textPrimary),
              _buildMetricRow('Buy Transactions', '$buyCount', BrokerIntelTheme.successGreen),
              _buildMetricRow('Sell Transactions', '$sellCount', BrokerIntelTheme.dangerRed),
            ],
          ),

          const SizedBox(height: 16),

          // Best & Worst Performers
          if (bestPerformer != null)
            _buildMetricCard(
              context,
              title: 'Performance Highlights (Total P/L)',
              icon: Icons.emoji_events,
              children: [
                _buildPerformerRow(
                  'Best Performer',
                  bestPerformer.symbol,
                  bestPerformer.totalPnLPercentage,
                  bestPerformer.totalPnL,
                  isPositive: bestPerformer.totalPnL >= 0,
                ),
                if (worstPerformer != null && worstPerformer != bestPerformer) ...[
                  const SizedBox(height: 8),
                  _buildPerformerRow(
                    'Worst Performer',
                    worstPerformer.symbol,
                    worstPerformer.totalPnLPercentage,
                    worstPerformer.totalPnL,
                    isPositive: worstPerformer.totalPnL >= 0,
                  ),
                ],
              ],
            ),

          const SizedBox(height: 16),

          // Market Status
          _buildMetricCard(
            context,
            title: 'Market Info',
            icon: Icons.info_outline,
            children: [
              _buildMetricRow('Market Status', provider.marketStatusText, biColors.textPrimary),
              if (provider.shareDataDate != null)
                _buildMetricRow('Data Date', provider.shareDataDate!, biColors.textSecondary),
              _buildMetricRow('Auto-Refresh', provider.autoRefreshEnabled ? 'Enabled' : 'Disabled', biColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPnLChart(BuildContext context, List<MonthlyPnL> monthlyPnL) {
    final biColors = context.biColors;
    // Sort by month ascending for the chart
    final sortedPnL = List<MonthlyPnL>.from(monthlyPnL)
      ..sort((a, b) => a.month.compareTo(b.month));
    
    // Get max absolute value for scaling
    double maxVal = 0;
    for (var p in sortedPnL) {
      if (p.realizedPnL.abs() > maxVal) maxVal = p.realizedPnL.abs();
    }
    if (maxVal == 0) maxVal = 1;

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedPnL.map((p) {
          final isPositive = p.realizedPnL >= 0;
          final heightFactor = (p.realizedPnL.abs() / maxVal).clamp(0.05, 1.0);
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: '${p.month}: Rs. ${_formatNumber(p.realizedPnL)}',
                    child: Container(
                      height: 100 * heightFactor,
                      decoration: BoxDecoration(
                        color: isPositive ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.month.split('-')[1], // Just show the month number
                    style: TextStyle(fontSize: 10, color: biColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Holdings analysis tab with individual stock details
  Widget _buildHoldingsAnalysisTab(BuildContext context, PortfolioProvider provider) {
    final biColors = context.biColors;
    final holdings = provider.holdings;
    final transactions = provider.transactions;
    final analysis = provider.portfolioAnalysis;

    // Use analysis stockPnL if available, otherwise fallback to holdings
    if (analysis != null && analysis.stockPnL.isNotEmpty) {
      final stockPnLs = List<StockPnL>.from(analysis.stockPnL)
        ..sort((a, b) => b.totalPnL.compareTo(a.totalPnL));

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stockPnLs.length,
        itemBuilder: (context, index) {
          final pnl = stockPnLs[index];
          final isActive = pnl.currentQuantity > 0;
          final isProfit = pnl.totalPnL >= 0;
          final plColor = isProfit ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed;

          // Find first buy date
          final symbolTxns = transactions
              .where((t) => t.symbol == pnl.symbol && t.transactionType == 'Purchased')
              .toList();
          DateTime? firstBuyDate;
          if (symbolTxns.isNotEmpty) {
            symbolTxns.sort((a, b) => a.date.compareTo(b.date));
            firstBuyDate = symbolTxns.first.date;
          }
          int holdingDays = firstBuyDate != null 
              ? DateTime.now().difference(firstBuyDate).inDays 
              : 0;

          return FerrofluidCard(
            value: pnl.totalPnL,
            enableShimmer: isActive,
            enableGlow: isActive && isProfit,
            margin: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: isActive ? 1.0 : 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: plColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: plColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pnl.symbol,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: biColors.textPrimary,
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: biColors.textSecondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: biColors.textSecondary.withOpacity(0.3)),
                              ),
                              child: Text(
                                'CLOSED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: biColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: biColors.grid,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? '$holdingDays days' : 'Realized Only',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: biColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailColumn(
                          'Holdings',
                          isActive ? '${pnl.currentQuantity} shares' : '0 (Sold)',
                          biColors,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailColumn(
                          'Realized P/L',
                          'Rs. ${_formatNumber(pnl.realizedPnL)}',
                          biColors,
                          valueColor: pnl.realizedPnL >= 0 ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed,
                        ),
                      ),
                      if (isActive)
                        Expanded(
                          child: _buildDetailColumn(
                            'Unrealized P/L',
                            'Rs. ${_formatNumber(pnl.unrealizedPnL)}',
                            biColors,
                            valueColor: pnl.unrealizedPnL >= 0 ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed,
                          ),
                        )
                      else
                        Expanded(
                          child: _buildDetailColumn(
                            'Status',
                            'Fully Exited',
                            biColors,
                            valueColor: biColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isActive ? 'Total P/L (FIFO)' : 'Net Realized Profit',
                        style: TextStyle(fontSize: 12, color: biColors.textSecondary),
                      ),
                      Text(
                        '${isProfit ? '+' : ''}Rs. ${_formatNumber(pnl.totalPnL)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: plColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Fallback to existing holdings view if analysis is not yet ready
    List<Holding> sortedHoldings = List.from(holdings)
      ..sort((a, b) => b.unrealizedPLPercentage.compareTo(a.unrealizedPLPercentage));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedHoldings.length,
      itemBuilder: (context, index) {
        final holding = sortedHoldings[index];
        
        // Calculate holding days from transactions
        final symbolTxns = transactions
            .where((t) => t.symbol == holding.symbol && t.transactionType == 'Purchased')
            .toList();
        
        DateTime? firstBuyDate;
        if (symbolTxns.isNotEmpty) {
          symbolTxns.sort((a, b) => a.date.compareTo(b.date));
          firstBuyDate = symbolTxns.first.date;
        }
        
        int holdingDays = firstBuyDate != null 
            ? DateTime.now().difference(firstBuyDate).inDays 
            : 0;

        final isProfit = holding.unrealizedPL >= 0;
        final plColor = isProfit ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed;

        return FerrofluidCard(
          value: holding.unrealizedPL,
          enableShimmer: true,
          enableGlow: true,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: plColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: plColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        holding.symbol,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: biColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: biColors.grid,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$holdingDays days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: biColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      'Quantity',
                      '${holding.quantity} shares',
                      biColors,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'Avg. Cost',
                      'Rs. ${holding.averageBuyPrice.toStringAsFixed(2)}',
                      biColors,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'LTP',
                      holding.ltp != null 
                          ? 'Rs. ${holding.ltp!.toStringAsFixed(2)}'
                          : 'N/A',
                      biColors,
                      valueColor: holding.ltp == null ? biColors.textSecondary : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn(
                      'Invested',
                      'Rs. ${_formatNumber(holding.investedValue)}',
                      biColors,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'Current',
                      'Rs. ${_formatNumber(holding.currentValue)}',
                      biColors,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'P/L',
                      '${isProfit ? '+' : ''}Rs. ${_formatNumber(holding.unrealizedPL)}',
                      biColors,
                      valueColor: plColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // P/L percentage bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (holding.unrealizedPLPercentage.abs() / 100).clamp(0.0, 1.0),
                  backgroundColor: biColors.grid,
                  valueColor: AlwaysStoppedAnimation(plColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isProfit ? '+' : ''}${holding.unrealizedPLPercentage.toStringAsFixed(2)}% ${isProfit ? 'gain' : 'loss'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: plColor,
                ),
              ),
              
              if (firstBuyDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'First purchase: ${_formatDate(firstBuyDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: biColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Timeline tab showing trade history
  Widget _buildTimelineTab(BuildContext context, PortfolioProvider provider) {
    final biColors = context.biColors;
    final transactions = List<Transaction>.from(provider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions yet',
          style: TextStyle(color: biColors.textSecondary),
        ),
      );
    }

    // Group transactions by month
    Map<String, List<Transaction>> groupedTxns = {};
    for (var txn in transactions) {
      final monthKey = '${txn.date.year}-${txn.date.month.toString().padLeft(2, '0')}';
      groupedTxns.putIfAbsent(monthKey, () => []).add(txn);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTxns.length,
      itemBuilder: (context, index) {
        final monthKey = groupedTxns.keys.elementAt(index);
        final monthTxns = groupedTxns[monthKey]!;
        final monthDate = DateTime.parse('$monthKey-01');
        
        // Calculate month statistics
        double monthBuyValue = monthTxns
            .where((t) => t.transactionType == 'Purchased')
            .fold(0.0, (sum, t) => sum + (t.quantity * t.price));
        double monthSellValue = monthTxns
            .where((t) => t.transactionType == 'Sold')
            .fold(0.0, (sum, t) => sum + (t.quantity * t.price));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: biColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatMonth(monthDate),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: biColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      if (monthBuyValue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: BrokerIntelTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Buy: Rs. ${_formatNumber(monthBuyValue)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: BrokerIntelTheme.successGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (monthSellValue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BrokerIntelTheme.dangerRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sell: Rs. ${_formatNumber(monthSellValue)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: BrokerIntelTheme.dangerRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Transactions for this month
            ...monthTxns.map((txn) {
              final isBuy = txn.transactionType == 'Purchased';
              final txnColor = isBuy ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed;
              final txnValue = txn.quantity * txn.price;

              return Container(
                margin: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dot and line
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: txnColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 50,
                          color: biColors.border,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    
                    // Transaction details
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: biColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: txnColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isBuy ? Icons.add_circle : Icons.remove_circle,
                                      color: txnColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      txn.symbol,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: biColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatDate(txn.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: biColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${txn.quantity} shares @ Rs. ${txn.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: biColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Total: Rs. ${_formatNumber(txnValue)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: txnColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // Helper widgets
  Widget _buildMetricCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final biColors = context.biColors;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: biColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BrokerIntelTheme.midIntensity, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: biColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    final biColors = context.biColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: biColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(String label, String symbol, double plPercent, double plAmount, {required bool isPositive}) {
    final biColors = context.biColors;
    final color = plPercent >= 0 ? BrokerIntelTheme.successGreen : BrokerIntelTheme.dangerRed;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: biColors.textSecondary,
              ),
            ),
            Text(
              symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: biColors.textPrimary,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${plPercent >= 0 ? '+' : ''}${plPercent.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${plAmount >= 0 ? '+' : ''}Rs. ${_formatNumber(plAmount)}',
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value, BrokerIntelThemeColors biColors, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: biColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? biColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Helper functions
  String _formatNumber(double value) {
    if (value.abs() >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value.abs() >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} K';
    }
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
