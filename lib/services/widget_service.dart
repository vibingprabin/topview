import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/holding.dart';

/// IPO data model for widget
class IpoWidgetData {
  final String companyName;
  final String symbol;
  final String openDate;
  final String closeDate;
  final String status; // 'upcoming', 'open', 'closed'
  final double pricePerUnit;
  final String type; // 'IPO', 'FPO', 'RIGHT'

  IpoWidgetData({
    required this.companyName,
    required this.symbol,
    required this.openDate,
    required this.closeDate,
    required this.status,
    required this.pricePerUnit,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'symbol': symbol,
    'openDate': openDate,
    'closeDate': closeDate,
    'status': status,
    'pricePerUnit': pricePerUnit,
    'type': type,
  };
}

/// Widget Service for Android Home Screen Widget
/// 
/// Manages the data flow between the app and the Android widget.
/// Uses the home_widget package for cross-platform widget support.
/// 
/// Widget displays:
/// - NEPSE Index value and change
/// - Market status (Open/Closed)
/// - Portfolio summary (total value, P/L)
/// - Top 3 holdings
/// - Upcoming IPOs (Large widget only)
class WidgetService {
  static const String _appGroupId = 'topview_widgets';

  // Widget data keys - must match Android widget implementation
  static const String _keyNepseIndex = 'nepse_index';
  static const String _keyIndexChange = 'index_change';
  static const String _keyIndexChangePercent = 'index_change_percent';
  static const String _keyMarketStatus = 'market_status';
  static const String _keyPortfolioValue = 'portfolio_value';
  static const String _keyPortfolioChange = 'portfolio_change';
  static const String _keyPortfolioChangePercent = 'portfolio_change_percent';
  static const String _keyTopHoldings = 'top_holdings';
  static const String _keyUpcomingIpos = 'upcoming_ipos';
  static const String _keyLastUpdate = 'last_update';

  /// Initialize the widget service
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      
      // Register callback for widget interactions
      HomeWidget.registerInteractivityCallback(_handleWidgetAction);
      
      debugPrint('WidgetService: Initialized successfully');
    } catch (e) {
      debugPrint('WidgetService: Error initializing: $e');
    }
  }

  /// Update widget with IPO data
  static Future<void> updateIpoData(List<IpoWidgetData> ipos) async {
    try {
      final iposJson = ipos.take(3).map((ipo) => ipo.toJson()).toList();
      await HomeWidget.saveWidgetData<String>(_keyUpcomingIpos, jsonEncode(iposJson));
      await _triggerWidgetUpdate();
      debugPrint('WidgetService: IPO data updated with ${ipos.length} items');
    } catch (e) {
      debugPrint('WidgetService: Error updating IPO data: $e');
    }
  }

  /// Update widget with latest market data
  static Future<void> updateMarketData({
    required double nepseIndex,
    required double indexChange,
    required double indexChangePercent,
    required bool isMarketOpen,
  }) async {
    try {
      // Store doubles as strings to avoid ClassCastException in Kotlin
      await HomeWidget.saveWidgetData<String>(_keyNepseIndex, nepseIndex.toString());
      await HomeWidget.saveWidgetData<String>(_keyIndexChange, indexChange.toString());
      await HomeWidget.saveWidgetData<String>(_keyIndexChangePercent, indexChangePercent.toString());
      await HomeWidget.saveWidgetData<String>(_keyMarketStatus, isMarketOpen ? 'OPEN' : 'CLOSED');
      await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().toIso8601String());
      
      await _triggerWidgetUpdate();
      debugPrint('WidgetService: Market data updated');
    } catch (e) {
      debugPrint('WidgetService: Error updating market data: $e');
    }
  }

  /// Update widget with portfolio data
  static Future<void> updatePortfolioData({
    required double totalValue,
    required double totalChange,
    required double changePercent,
    required List<Holding> topHoldings,
  }) async {
    try {
      // Store doubles as strings to avoid ClassCastException in Kotlin
      await HomeWidget.saveWidgetData<String>(_keyPortfolioValue, totalValue.toString());
      await HomeWidget.saveWidgetData<String>(_keyPortfolioChange, totalChange.toString());
      await HomeWidget.saveWidgetData<String>(_keyPortfolioChangePercent, changePercent.toString());
      
      // Convert top holdings to JSON
      final holdingsJson = topHoldings.take(3).map((h) => {
        'symbol': h.symbol,
        'quantity': h.quantity,
        'currentValue': h.currentValue,
        'unrealizedPL': h.unrealizedPL,
        'unrealizedPLPercent': h.unrealizedPLPercentage,
      }).toList();
      
      await HomeWidget.saveWidgetData<String>(_keyTopHoldings, jsonEncode(holdingsJson));
      await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().toIso8601String());
      
      await _triggerWidgetUpdate();
      debugPrint('WidgetService: Portfolio data updated');
    } catch (e) {
      debugPrint('WidgetService: Error updating portfolio data: $e');
    }
  }

  /// Update all widget data at once
  static Future<void> updateAllData({
    required double nepseIndex,
    required double indexChange,
    required double indexChangePercent,
    required bool isMarketOpen,
    required double portfolioValue,
    required double portfolioChange,
    required double portfolioChangePercent,
    required List<Holding> topHoldings,
    List<IpoWidgetData>? upcomingIpos,
  }) async {
    try {
      // Market data - store doubles as strings to avoid ClassCastException in Kotlin
      await HomeWidget.saveWidgetData<String>(_keyNepseIndex, nepseIndex.toString());
      await HomeWidget.saveWidgetData<String>(_keyIndexChange, indexChange.toString());
      await HomeWidget.saveWidgetData<String>(_keyIndexChangePercent, indexChangePercent.toString());
      await HomeWidget.saveWidgetData<String>(_keyMarketStatus, isMarketOpen ? 'OPEN' : 'CLOSED');
      
      // Portfolio data - store doubles as strings to avoid ClassCastException in Kotlin
      await HomeWidget.saveWidgetData<String>(_keyPortfolioValue, portfolioValue.toString());
      await HomeWidget.saveWidgetData<String>(_keyPortfolioChange, portfolioChange.toString());
      await HomeWidget.saveWidgetData<String>(_keyPortfolioChangePercent, portfolioChangePercent.toString());
      
      // Top holdings
      final holdingsJson = topHoldings.take(3).map((h) => {
        'symbol': h.symbol,
        'quantity': h.quantity,
        'currentValue': h.currentValue,
        'unrealizedPL': h.unrealizedPL,
        'unrealizedPLPercent': h.unrealizedPLPercentage,
      }).toList();
      
      await HomeWidget.saveWidgetData<String>(_keyTopHoldings, jsonEncode(holdingsJson));
      
      // Upcoming IPOs (for large widget)
      if (upcomingIpos != null && upcomingIpos.isNotEmpty) {
        final iposJson = upcomingIpos.take(3).map((ipo) => ipo.toJson()).toList();
        await HomeWidget.saveWidgetData<String>(_keyUpcomingIpos, jsonEncode(iposJson));
      }
      
      await HomeWidget.saveWidgetData<String>(_keyLastUpdate, DateTime.now().toIso8601String());
      
      await _triggerWidgetUpdate();
      debugPrint('WidgetService: All data updated');
    } catch (e) {
      debugPrint('WidgetService: Error updating all data: $e');
    }
  }

  /// Trigger widget UI update
  static Future<void> _triggerWidgetUpdate() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'TopViewWidgetProvider',
        iOSName: 'TopViewWidget',
      );
    } catch (e) {
      debugPrint('WidgetService: Error triggering widget update: $e');
    }
  }

  /// Handle widget action callbacks (taps, buttons)
  static Future<void> _handleWidgetAction(Uri? uri) async {
    if (uri == null) return;

    final action = uri.host;
    final params = uri.queryParameters;

    debugPrint('WidgetService: Action received: $action, params: $params');

    switch (action) {
      case 'refresh':
        await _handleRefreshRequest();
        break;
      case 'open_app':
        await _handleOpenApp();
        break;
      case 'open_portfolio':
        await _setNavigationTarget('portfolio');
        break;
      case 'open_stock':
        final symbol = params['symbol'];
        if (symbol != null) {
          await _setNavigationTarget('stock:$symbol');
        }
        break;
      default:
        debugPrint('WidgetService: Unknown action: $action');
    }
  }

  /// Handle refresh request from widget
  static Future<void> _handleRefreshRequest() async {
    debugPrint('WidgetService: Refresh requested from widget');
    // This will be handled by the app when it processes pending actions
    await _setNavigationTarget('refresh');
  }

  /// Handle open app request
  static Future<void> _handleOpenApp() async {
    debugPrint('WidgetService: Open app requested from widget');
    await _setNavigationTarget('home');
  }

  /// Set navigation target for when app opens
  static Future<void> _setNavigationTarget(String target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_widget_navigation', target);
  }

  /// Get and clear pending navigation from widget
  static Future<String?> getPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final navigation = prefs.getString('pending_widget_navigation');
    if (navigation != null) {
      await prefs.remove('pending_widget_navigation');
    }
    return navigation;
  }

  /// Check if NEPSE market is currently open
  /// Market hours: Sun-Thu, 11:00 AM - 3:00 PM Nepal Time
  static bool isMarketOpen() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    final hour = now.hour;
    final minute = now.minute;

    // Market is closed on Friday (5) and Saturday (6)
    if (dayOfWeek == 5 || dayOfWeek == 6) {
      return false;
    }

    // Market hours: 11:00 AM - 3:00 PM
    final currentTime = hour * 60 + minute;
    const marketOpen = 11 * 60; // 11:00 AM
    const marketClose = 15 * 60; // 3:00 PM

    return currentTime >= marketOpen && currentTime < marketClose;
  }

  /// Format currency value for widget display
  static String formatCurrency(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} K';
    }
    return value.toStringAsFixed(2);
  }

  /// Format percentage for widget display
  static String formatPercent(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }
}
