import 'package:flutter/material.dart';
import 'ferrofluid_theme.dart';
import '../broker_intel_theme.dart';

/// Value-aware shimmer effect - DISABLED for performance
/// Use subtle color tinting instead of animated shimmer
class ValueShimmer extends StatelessWidget {
  final Widget child;
  final double value;
  final bool enabled;
  final Duration duration;
  final double? width;
  final double? height;

  const ValueShimmer({
    super.key,
    required this.child,
    this.value = 0,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 2500),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Disabled for performance - animated shimmer caused lag
    return child;
  }
}

/// Metallic sheen effect - DISABLED for performance
/// Continuous animation loops caused significant lag
class MetallicSheen extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final Color sheenColor;
  final double intensity;

  const MetallicSheen({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 3000),
    this.sheenColor = const Color(0x20FFFFFF),
    this.intensity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    // Disabled for performance
    return child;
  }
}

/// Subtle profit/loss glow - kept but with reduced intensity
class ProfitLossGlow extends StatelessWidget {
  final Widget child;
  final double value;
  final double intensity;
  final bool enabled;

  const ProfitLossGlow({
    super.key,
    required this.child,
    required this.value,
    this.intensity = 0.2,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || value == 0) {
      return child;
    }

    final glowColor = value > 0
        ? BrokerIntelTheme.successGreen
        : BrokerIntelTheme.dangerRed;

    // Subtle glow effect - very light to avoid performance issues
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
