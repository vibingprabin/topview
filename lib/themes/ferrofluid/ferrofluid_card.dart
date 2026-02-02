import 'package:flutter/material.dart';
import '../broker_intel_theme.dart';
import 'ferrofluid_theme.dart';
import 'shimmer_effects.dart';

/// Obsidian-inspired card with glass-like dark aesthetic
/// Clean, performant design with subtle effects
class FerrofluidCard extends StatelessWidget {
  final Widget child;
  final double? value;
  final bool enableShimmer;
  final bool enableGlow;
  final bool enableGradientBorder;
  final bool enableNoise;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const FerrofluidCard({
    super.key,
    required this.child,
    this.value,
    this.enableShimmer = false, // Disabled by default for performance
    this.enableGlow = true,
    this.enableGradientBorder = false,
    this.enableNoise = false, // Disabled by default for performance
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);
    final cardValue = value ?? 0;

    // Determine accent color based on P/L value
    Color? accentColor;
    if (cardValue > 0) {
      accentColor = BrokerIntelTheme.successGreen;
    } else if (cardValue < 0) {
      accentColor = BrokerIntelTheme.dangerRed;
    }

    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: radius,
        // Obsidian-like dark glass gradient
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E2E), // Deep obsidian
                  const Color(0xFF252536), // Slightly lighter
                  const Color(0xFF1A1A28), // Back to deep
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                  Colors.white,
                ],
              ),
        // Sharp border with subtle accent
        border: Border.all(
          color: isDark
              ? (accentColor?.withOpacity(0.3) ?? const Color(0xFF2D2D40))
              : (accentColor?.withOpacity(0.2) ?? BrokerIntelTheme.borderLight),
          width: 1,
        ),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (enableGlow && accentColor != null)
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: -4,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: (accentColor ?? BrokerIntelTheme.midIntensity).withOpacity(0.1),
          highlightColor: (accentColor ?? BrokerIntelTheme.midIntensity).withOpacity(0.05),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}

/// Simple list tile with obsidian styling
class FerrofluidListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final double? value;
  final VoidCallback? onTap;
  final bool enableShimmer;
  final bool dense;

  const FerrofluidListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.value,
    this.onTap,
    this.enableShimmer = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: dense ? 8 : 12,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple static divider - no animation for performance
class FerrofluidDivider extends StatelessWidget {
  final bool animated; // Kept for API compatibility, but ignored
  final double height;
  final EdgeInsetsGeometry? margin;

  const FerrofluidDivider({
    super.key,
    this.animated = false, // Animation disabled for performance
    this.height = 1,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            isDark 
                ? const Color(0xFF3D3D50).withOpacity(0.5)
                : BrokerIntelTheme.borderLight.withOpacity(0.5),
            isDark 
                ? BrokerIntelTheme.midIntensity.withOpacity(0.3)
                : BrokerIntelTheme.midIntensity.withOpacity(0.2),
            isDark 
                ? const Color(0xFF3D3D50).withOpacity(0.5)
                : BrokerIntelTheme.borderLight.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
