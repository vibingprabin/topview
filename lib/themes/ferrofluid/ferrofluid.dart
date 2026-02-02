/// Ferrofluid Theme System
/// 
/// A comprehensive ferrofluid-inspired design system with subtle textures
/// and animations for the TopView NEPSE Portfolio Tracker.
/// 
/// Features:
/// - Animated mesh gradient backgrounds
/// - Value-aware shimmer effects (green for profit, red for loss)
/// - Subtle grain/noise textures
/// - Metallic sheen animations
/// - Profit/loss glow effects
/// 
/// Usage:
/// ```dart
/// import 'package:topview/themes/ferrofluid/ferrofluid.dart';
/// 
/// // Value-aware card
/// FerrofluidCard(
///   value: holding.unrealizedPL,
///   enableShimmer: true,
///   enableGlow: true,
///   child: HoldingContent(),
/// )
/// 
/// // Mesh header
/// FerrofluidMeshHeader(
///   height: 180,
///   value: portfolioTotalPL,
///   child: PortfolioSummary(),
/// )
/// ```

export 'ferrofluid_theme.dart';
export 'noise_overlay.dart';
export 'shimmer_effects.dart';
export 'ferrofluid_card.dart';
export 'ferrofluid_scaffold.dart';
