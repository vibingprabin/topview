import 'package:flutter/material.dart';
import '../../themes/broker_intel_theme.dart';

class MarketMoverCard extends StatelessWidget {
  final String symbol;
  final String name;
  final double changePercent;
  final bool isGainer;
  final VoidCallback? onTap;

  const MarketMoverCard({
    super.key,
    required this.symbol,
    required this.name,
    required this.changePercent,
    required this.isGainer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isGainer
              ? BrokerIntelTheme.successGreen.withOpacity(0.05)
              : BrokerIntelTheme.dangerRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGainer
                ? BrokerIntelTheme.successGreen.withOpacity(0.2)
                : BrokerIntelTheme.dangerRed.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BrokerIntelTheme.textPrimary,
                  ),
                ),
                Text(
                  name.length > 12 ? '${name.substring(0, 12)}...' : name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: BrokerIntelTheme.textCaption,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  isGainer ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isGainer
                      ? BrokerIntelTheme.successGreen
                      : BrokerIntelTheme.dangerRed,
                ),
                const SizedBox(width: 4),
                Text(
                  '${changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isGainer
                        ? BrokerIntelTheme.successGreen
                        : BrokerIntelTheme.dangerRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
