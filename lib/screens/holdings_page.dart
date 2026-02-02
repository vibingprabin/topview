import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/services/stop_loss_dao.dart';
import 'package:topview/models/holding.dart';
import 'package:topview/themes/broker_intel_theme.dart';
import 'package:topview/themes/ferrofluid/ferrofluid.dart';

class HoldingsPage extends StatelessWidget {
  const HoldingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final biColors = context.biColors;
    
    return Scaffold(
      backgroundColor: biColors.background,
      appBar: FerrofluidAppBar(
        title: 'Holdings',
        enableMesh: true,
        actions: [
          Consumer<PortfolioProvider>(
            builder: (context, provider, child) {
              if (provider.isShareDataLoading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  provider.fetchLiveShareData(forceRefresh: true);
                },
                tooltip: 'Refresh Market Data',
              );
            }
          ),
        ],
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.holdings.isEmpty && !provider.isShareDataLoading) {
            return const Center(
              child: Text('No holdings found. Add transactions or check client ID.'),
            );
          }
          if (provider.isShareDataLoading && provider.holdings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          String? subtitleText;
          if (provider.shareDataDate != null) {
            subtitleText = 'Market Data As Of: ${provider.shareDataDate}';
            if (provider.shareDataError != null) {
              subtitleText += ' (Error: ${provider.shareDataError})';
            }
          } else if (provider.shareDataError != null) {
            subtitleText = 'Market Data Error: ${provider.shareDataError}';
          }

          return Column(
            children: [
              if (subtitleText != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    subtitleText,
                    style: TextStyle(fontSize: 12, color: provider.shareDataError != null ? Colors.orange : Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.holdings.length,
                  itemBuilder: (context, index) {
                    final holding = provider.holdings[index];
                    // Values are now directly from the Holding object, calculated with LTP
                    final ltp = holding.ltp ?? holding.averageBuyPrice; // Fallback to avg if LTP is null
                    final percentChangeText = holding.percentChange ?? 'N/A';
                    final unrealizedPL = holding.unrealizedPL;
                    final unrealizedPLPercentage = holding.unrealizedPLPercentage;
                    
                    Color plColor = unrealizedPL > 0.001 
                        ? BrokerIntelTheme.successGreen 
                        : (unrealizedPL < -0.001 ? BrokerIntelTheme.dangerRed : BrokerIntelTheme.neutralGray);
                    IconData trendIcon = Icons.remove;
                    if (percentChangeText.contains('-')) trendIcon = Icons.arrow_downward;
                    else if (double.tryParse(percentChangeText.replaceAll('%', '')) != null && 
                             double.parse(percentChangeText.replaceAll('%', '')) > 0) trendIcon = Icons.arrow_upward;

                    return FerrofluidCard(
                      value: unrealizedPL,
                      enableShimmer: true,
                      enableGlow: true,
                      enableNoise: true,
                      onTap: () => _showStopLossDialog(context, holding, provider),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holding.symbol,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: biColors.textPrimary,
                                    ),
                                  ),
                                  if (holding.isStopLossTriggered)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: BrokerIntelTheme.dangerRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: BrokerIntelTheme.dangerRed, width: 1),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_amber, size: 14, color: BrokerIntelTheme.dangerRed),
                                          SizedBox(width: 4),
                                          Text(
                                            'Stop-Loss Triggered',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: BrokerIntelTheme.dangerRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${holding.quantity} shares',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: biColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          FerrofluidDivider(animated: true, margin: const EdgeInsets.symmetric(vertical: 12)),
                          _buildDetailsRow(context, 'Avg. Buy Price', '₹${holding.averageBuyPrice.toStringAsFixed(2)}'),
                          _buildDetailsRow(
                            context,
                            'LTP', 
                            '₹${ltp.toStringAsFixed(2)}', 
                            trailingWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(trendIcon, size: 16, color: plColor),
                                const SizedBox(width: 4),
                                Text(
                                  percentChangeText,
                                  style: TextStyle(color: plColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ),
                          _buildDetailsRow(context, 'Invested Value', '₹${holding.investedValue.toStringAsFixed(2)}'),
                          _buildDetailsRow(context, 'Current Value', '₹${holding.currentValue.toStringAsFixed(2)}', textColor: plColor),
                          _buildDetailsRow(
                            context,
                            'Unrealized P/L', 
                            '₹${unrealizedPL.toStringAsFixed(2)} (${unrealizedPLPercentage.toStringAsFixed(2)}%)',
                            textColor: plColor,
                          ),
                          if (holding.stopLossEnabled && holding.stopLossPrice != null)
                            _buildDetailsRow(
                              context,
                              'Stop-Loss',
                              '₹${holding.stopLossPrice!.toStringAsFixed(2)}',
                              textColor: BrokerIntelTheme.warningOrange,
                              trailingWidget: Icon(Icons.notifications_active, size: 16, color: BrokerIntelTheme.warningOrange),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (holding.stopLossEnabled && holding.stopLossPrice != null)
                                TextButton.icon(
                                  onPressed: () => _showStopLossDialog(context, holding, provider),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit Stop-Loss'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: BrokerIntelTheme.warningOrange,
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () => _showStopLossDialog(context, holding, provider),
                                  icon: const Icon(Icons.add_alert, size: 16),
                                  label: const Text('Set Stop-Loss'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: BrokerIntelTheme.midIntensity,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDetailsRow(BuildContext context, String label, String value, {Color? textColor, Widget? trailingWidget}) {
    final biColors = context.biColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: biColors.textSecondary)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor ?? biColors.textPrimary,
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ]
            ],
          ),
        ],
      ),
    );
  }

  void _showStopLossDialog(BuildContext context, Holding holding, PortfolioProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: holding.stopLossPrice?.toStringAsFixed(2) ?? '',
    );
    bool enabled = holding.stopLossEnabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Stop-Loss Alert for ${holding.symbol}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current LTP: ₹${(holding.ltp ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Stop-Loss Price',
                  prefixText: '₹',
                  helperText: 'You will be notified when price falls below this',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Stop-Loss Alert'),
                value: enabled,
                onChanged: (value) {
                  setState(() {
                    enabled = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            if (holding.stopLossEnabled)
              TextButton(
                onPressed: () async {
                  // Close dialog immediately for better UX
                  Navigator.of(context).pop();
                  
                  try {
                    await StopLossDAO.delete(holding.symbol);
                    await provider.loadTransactions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stop-loss removed')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error removing stop-loss: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final priceText = controller.text.trim();
                if (priceText.isEmpty && enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a stop-loss price')),
                  );
                  return;
                }

                final price = double.tryParse(priceText);
                if (price == null && enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid price')),
                  );
                  return;
                }

                // Close dialog immediately for better UX
                Navigator.of(context).pop();

                try {
                  final settings = StopLossSettings(
                    symbol: holding.symbol,
                    stopLossPrice: price ?? 0,
                    enabled: enabled,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await StopLossDAO.upsert(settings);
                  await provider.loadTransactions();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          enabled
                              ? 'Stop-loss set at ₹${price!.toStringAsFixed(2)}'
                              : 'Stop-loss disabled',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving stop-loss: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
