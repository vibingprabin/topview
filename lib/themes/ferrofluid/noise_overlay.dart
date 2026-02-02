import 'package:flutter/material.dart';

/// Lightweight noise overlay - simplified for performance
/// In most cases, this just returns the child directly to avoid lag
class NoiseOverlay extends StatelessWidget {
  final double opacity;
  final Widget child;
  final bool animated;

  const NoiseOverlay({
    super.key,
    this.opacity = 0.08,
    required this.child,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    // Disabled for performance - just return child
    // The noise effect caused significant lag on mobile devices
    return child;
  }
}

/// Lightweight grain texture - disabled for performance
class GrainTexture extends StatelessWidget {
  final Widget child;
  final double intensity;
  final Color? tintColor;

  const GrainTexture({
    super.key,
    required this.child,
    this.intensity = 0.1,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    // Disabled for performance
    return child;
  }
}
