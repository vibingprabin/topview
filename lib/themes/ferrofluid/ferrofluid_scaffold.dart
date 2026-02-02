import 'package:flutter/material.dart';
import '../broker_intel_theme.dart';
import 'ferrofluid_theme.dart';

/// Obsidian-inspired header with subtle gradient animation
/// Optimized for performance - uses simple gradient instead of mesh
class FerrofluidMeshHeader extends StatelessWidget {
  final double height;
  final Widget? child;
  final List<Color>? colors;
  final double? value;
  final bool enableNoise;

  const FerrofluidMeshHeader({
    super.key,
    this.height = 180,
    this.child,
    this.colors,
    this.value,
    this.enableNoise = false, // Disabled by default
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine gradient colors based on value (P/L)
    List<Color> gradientColors;
    if (value != null && value! > 0) {
      // Profit - subtle green tint
      gradientColors = isDark
          ? [
              const Color(0xFF0D1F17), // Very dark green-black
              const Color(0xFF1A2B23), // Dark green tint
              const Color(0xFF0F1A14), // Back to dark
            ]
          : [
              const Color(0xFFE8F5E9),
              const Color(0xFFF1F8E9),
              const Color(0xFFE8F5E9),
            ];
    } else if (value != null && value! < 0) {
      // Loss - subtle red tint
      gradientColors = isDark
          ? [
              const Color(0xFF1F0D0D), // Very dark red-black
              const Color(0xFF2B1A1A), // Dark red tint
              const Color(0xFF1A0F0F), // Back to dark
            ]
          : [
              const Color(0xFFFCE4EC),
              const Color(0xFFFFF3E0),
              const Color(0xFFFCE4EC),
            ];
    } else {
      // Neutral - obsidian gradient
      gradientColors = colors ?? (isDark
          ? [
              const Color(0xFF0F0F1A), // Deep obsidian
              const Color(0xFF1A1A2E), // Slightly purple
              const Color(0xFF16162A), // Deep blue-black
              const Color(0xFF0F0F1A), // Back to obsidian
            ]
          : [
              const Color(0xFFF5F5F7),
              const Color(0xFFECEFF1),
              const Color(0xFFF5F5F7),
            ]);
    }

    Widget headerWidget = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
    );

    if (child != null) {
      headerWidget = Stack(
        children: [
          headerWidget,
          Positioned.fill(
            child: child!,
          ),
        ],
      );
    }

    return headerWidget;
  }
}

/// Solid section with obsidian gradient
class FerrofluidSolidSection extends StatelessWidget {
  final Widget child;
  final double? value;
  final bool enableMesh;
  final bool enableNoise;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const FerrofluidSolidSection({
    super.key,
    required this.child,
    this.value,
    this.enableMesh = false, // Disabled for performance
    this.enableNoise = false,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16162A),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFFFFFFF),
                ],
        ),
      ),
      child: child,
    );
  }
}

/// Simple scaffold with obsidian theme
class FerrofluidScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool enableBackgroundMesh;
  final List<Color>? backgroundColors;
  final double backgroundOpacity;

  const FerrofluidScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.enableBackgroundMesh = false,
    this.backgroundColors,
    this.backgroundOpacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0F0F1A) // Deep obsidian
        : BrokerIntelTheme.bgWhite;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Simple app bar with obsidian gradient
class FerrofluidAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool enableMesh;
  final double? value;
  final double elevation;
  final bool centerTitle;

  const FerrofluidAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.enableMesh = false, // Disabled for performance
    this.value,
    this.elevation = 0,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16162A),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFFFFFFF),
                ],
        ),
      ),
      child: AppBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        actions: actions,
        leading: leading,
        elevation: 0,
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : BrokerIntelTheme.textPrimary,
      ),
    );
  }
}
