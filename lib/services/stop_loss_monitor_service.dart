import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holding.dart';
import 'notification_service.dart';

/// Stop-Loss Monitor Service
/// 
/// Monitors holdings for stop-loss triggers and sends notifications
/// - Runs periodic checks every 5 minutes
/// - Tracks triggered stop-losses to avoid duplicate notifications
/// - Persists notification state across app restarts
class StopLossMonitorService {
  static final StopLossMonitorService _instance = StopLossMonitorService._internal();
  factory StopLossMonitorService() => _instance;
  StopLossMonitorService._internal();

  final NotificationService _notificationService = NotificationService();
  Timer? _monitorTimer;
  bool _isMonitoring = false;
  
  // Tracking triggered stop-losses to avoid duplicate notifications
  final Set<String> _triggeredSymbols = {};
  static const String _prefsKey = 'triggered_stop_losses';

  /// Start monitoring for stop-loss triggers
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    await _notificationService.initialize();
    await _loadTriggeredStopLosses();

    _isMonitoring = true;
    debugPrint('✅ Stop-loss monitoring started');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    debugPrint('⏹️ Stop-loss monitoring stopped');
  }

  /// Check holdings for stop-loss triggers
  Future<void> checkHoldings(List<Holding> holdings) async {
    if (!_isMonitoring) return;

    for (final holding in holdings) {
      if (holding.stopLossEnabled && 
          holding.stopLossPrice != null && 
          holding.ltp != null) {
        
        // Check if stop-loss has been triggered
        if (holding.isStopLossTriggered) {
          // Only notify if we haven't already notified for this symbol
          if (!_triggeredSymbols.contains(holding.symbol)) {
            await _notifyStopLossTriggered(holding);
            _triggeredSymbols.add(holding.symbol);
            await _saveTriggeredStopLosses();
            
            debugPrint('🚨 Stop-loss triggered for ${holding.symbol}');
          }
        } else {
          // If price has recovered above stop-loss, remove from triggered set
          // This allows re-triggering if price drops again
          if (_triggeredSymbols.contains(holding.symbol)) {
            _triggeredSymbols.remove(holding.symbol);
            await _saveTriggeredStopLosses();
            
            debugPrint('✅ ${holding.symbol} recovered above stop-loss');
          }
        }
      }
    }
  }

  /// Send stop-loss notification
  Future<void> _notifyStopLossTriggered(Holding holding) async {
    await _notificationService.showStopLossAlert(
      symbol: holding.symbol,
      currentPrice: holding.ltp!,
      stopLossPrice: holding.stopLossPrice!,
      quantity: holding.quantity.toDouble(),
    );
  }

  /// Load triggered stop-losses from storage
  Future<void> _loadTriggeredStopLosses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final triggered = prefs.getStringList(_prefsKey) ?? [];
      _triggeredSymbols.addAll(triggered);
      
      debugPrint('📊 Loaded ${_triggeredSymbols.length} triggered stop-losses');
    } catch (e) {
      debugPrint('❌ Error loading triggered stop-losses: $e');
    }
  }

  /// Save triggered stop-losses to storage
  Future<void> _saveTriggeredStopLosses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _triggeredSymbols.toList());
    } catch (e) {
      debugPrint('❌ Error saving triggered stop-losses: $e');
    }
  }

  /// Reset triggered status for a specific symbol
  /// Useful when user updates stop-loss or wants to re-enable notifications
  Future<void> resetTriggeredStatus(String symbol) async {
    _triggeredSymbols.remove(symbol);
    await _saveTriggeredStopLosses();
    debugPrint('🔄 Reset triggered status for $symbol');
  }

  /// Clear all triggered stop-losses
  Future<void> clearAllTriggered() async {
    _triggeredSymbols.clear();
    await _saveTriggeredStopLosses();
    debugPrint('🧹 Cleared all triggered stop-losses');
  }

  /// Get list of symbols with triggered stop-losses
  List<String> get triggeredSymbols => _triggeredSymbols.toList();

  /// Check if a specific symbol has triggered stop-loss
  bool hasTriggered(String symbol) => _triggeredSymbols.contains(symbol);

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
