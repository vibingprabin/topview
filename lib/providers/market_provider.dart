import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/nepse_api_service.dart';

/// Market Data Provider
/// 
/// Manages NEPSE market data state with:
/// - Caching with expiry (5 min for live data, 1 day for static)
/// - Auto-refresh on interval
/// - Error handling with fallback to cached data
/// - Loading states and error messages
class MarketProvider extends ChangeNotifier {
  final NepseApiService _apiService;
  SharedPreferences? _prefs;
  Timer? _refreshTimer;

  // Cache keys
  static const String _cacheKeyIndices = 'market_indices_cache';
  static const String _cacheKeyQuotes = 'market_quotes_cache';
  static const String _cacheKeySummary = 'market_summary_cache';
  static const String _cacheKeyGainers = 'market_gainers_cache';
  static const String _cacheKeyLosers = 'market_losers_cache';
  static const String _cacheKeyTimestamp = 'market_cache_timestamp';

  // Cache expiry durations
  static const Duration _liveDataExpiry = Duration(minutes: 5);
  static const Duration _staticDataExpiry = Duration(hours: 24);

  // State
  List<MarketIndex> _indices = [];
  List<StockQuote> _quotes = [];
  MarketSummary? _summary;
  List<MarketMover> _topGainers = [];
  List<MarketMover> _topLosers = [];
  MarketStatus _marketStatus = MarketStatus.unknown;
  
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;

  // Getters
  List<MarketIndex> get indices => _indices;
  List<StockQuote> get quotes => _quotes;
  MarketSummary? get summary => _summary;
  List<MarketMover> get topGainers => _topGainers;
  List<MarketMover> get topLosers => _topLosers;
  MarketStatus get marketStatus => _marketStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  bool get hasError => _error != null;
  bool get hasData => _indices.isNotEmpty || _quotes.isNotEmpty;

  // Convenience getters
  MarketIndex? get nepseIndex => _indices.firstWhere(
    (i) => i.name.toLowerCase().contains('nepse'),
    orElse: () => _indices.isNotEmpty ? _indices.first : 
      MarketIndex(name: 'NEPSE', currentValue: 0, previousClose: 0, change: 0, changePercent: 0),
  );

  bool get isMarketOpen => _marketStatus == MarketStatus.open;

  MarketProvider({NepseApiService? apiService})
      : _apiService = apiService ?? NepseApiService();

  /// Initialize provider and load cached data
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load cached data first
    await _loadCachedData();
    
    // Then fetch fresh data
    await refreshAllData();
    
    // Set up auto-refresh every 5 minutes
    _setupAutoRefresh();
  }

  /// Set up automatic data refresh
  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_liveDataExpiry, (_) {
      if (!_isLoading) {
        refreshAllData(showLoading: false);
      }
    });
  }

  /// Load data from cache
  Future<void> _loadCachedData() async {
    if (_prefs == null) return;

    try {
      final timestamp = _prefs!.getInt(_cacheKeyTimestamp);
      if (timestamp != null) {
        _lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // Load indices
      final indicesJson = _prefs!.getString(_cacheKeyIndices);
      if (indicesJson != null) {
        final List<dynamic> data = jsonDecode(indicesJson);
        _indices = data.map((e) => MarketIndex.fromJson(e)).toList();
      }

      // Load quotes
      final quotesJson = _prefs!.getString(_cacheKeyQuotes);
      if (quotesJson != null) {
        final List<dynamic> data = jsonDecode(quotesJson);
        _quotes = data.map((e) => StockQuote.fromJson(e)).toList();
      }

      // Load summary
      final summaryJson = _prefs!.getString(_cacheKeySummary);
      if (summaryJson != null) {
        _summary = MarketSummary.fromJson(jsonDecode(summaryJson));
      }

      // Load gainers
      final gainersJson = _prefs!.getString(_cacheKeyGainers);
      if (gainersJson != null) {
        final List<dynamic> data = jsonDecode(gainersJson);
        _topGainers = data.map((e) => MarketMover.fromJson(e)).toList();
      }

      // Load losers
      final losersJson = _prefs!.getString(_cacheKeyLosers);
      if (losersJson != null) {
        final List<dynamic> data = jsonDecode(losersJson);
        _topLosers = data.map((e) => MarketMover.fromJson(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      developer.log('Error loading cached data: $e', name: 'MarketProvider');
    }
  }

  /// Save data to cache
  Future<void> _saveCache() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);

      if (_indices.isNotEmpty) {
        await _prefs!.setString(
          _cacheKeyIndices, 
          jsonEncode(_indices.map((e) => e.toJson()).toList()),
        );
      }

      if (_quotes.isNotEmpty) {
        await _prefs!.setString(
          _cacheKeyQuotes, 
          jsonEncode(_quotes.map((e) => e.toJson()).toList()),
        );
      }

      if (_summary != null) {
        await _prefs!.setString(_cacheKeySummary, jsonEncode(_summary!.toJson()));
      }

      if (_topGainers.isNotEmpty) {
        await _prefs!.setString(
          _cacheKeyGainers, 
          jsonEncode(_topGainers.map((e) => e.toJson()).toList()),
        );
      }

      if (_topLosers.isNotEmpty) {
        await _prefs!.setString(
          _cacheKeyLosers, 
          jsonEncode(_topLosers.map((e) => e.toJson()).toList()),
        );
      }
    } catch (e) {
      developer.log('Error saving cache: $e', name: 'MarketProvider');
    }
  }

  /// Check if cache is expired
  bool _isCacheExpired(Duration expiry) {
    if (_lastUpdate == null) return true;
    return DateTime.now().difference(_lastUpdate!) > expiry;
  }

  /// Refresh all market data
  Future<void> refreshAllData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Fetch data in parallel
      final results = await Future.wait([
        _apiService.getMarketIndices(),
        _apiService.getMarketSummary(),
        _apiService.getTopGainers(limit: 5),
        _apiService.getTopLosers(limit: 5),
        _apiService.getMarketStatus(),
      ]);

      _indices = results[0] as List<MarketIndex>;
      _summary = results[1] as MarketSummary?;
      _topGainers = results[2] as List<MarketMover>;
      _topLosers = results[3] as List<MarketMover>;
      _marketStatus = results[4] as MarketStatus;

      _lastUpdate = DateTime.now();
      _error = null;

      // Save to cache
      await _saveCache();
    } catch (e) {
      _error = 'Failed to fetch market data: $e';
      developer.log(_error!, name: 'MarketProvider');
      
      // Keep cached data if available
      if (_indices.isEmpty) {
        _error = 'No data available. Please check your connection.';
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Refresh market indices only
  Future<void> refreshIndices() async {
    try {
      _indices = await _apiService.getMarketIndices();
      _lastUpdate = DateTime.now();
      await _saveCache();
      notifyListeners();
    } catch (e) {
      developer.log('Error refreshing indices: $e', name: 'MarketProvider');
    }
  }

  /// Refresh top gainers and losers
  Future<void> refreshMarketMovers() async {
    try {
      final results = await Future.wait([
        _apiService.getTopGainers(limit: 5),
        _apiService.getTopLosers(limit: 5),
      ]);

      _topGainers = results[0] as List<MarketMover>;
      _topLosers = results[1] as List<MarketMover>;
      _lastUpdate = DateTime.now();
      
      await _saveCache();
      notifyListeners();
    } catch (e) {
      developer.log('Error refreshing movers: $e', name: 'MarketProvider');
    }
  }

  /// Get stock quote by symbol
  StockQuote? getQuote(String symbol) {
    return _quotes.firstWhere(
      (q) => q.symbol.toUpperCase() == symbol.toUpperCase(),
      orElse: () => StockQuote(
        symbol: symbol,
        name: symbol,
        ltp: 0,
        previousClose: 0,
        open: 0,
        high: 0,
        low: 0,
        volume: 0,
        change: 0,
        changePercent: 0,
      ),
    );
  }

  /// Search stocks
  Future<List<StockQuote>> searchStocks(String query) async {
    if (query.isEmpty) return [];
    return await _apiService.searchStocks(query);
  }

  /// Clear all data and cache
  Future<void> clearAllData() async {
    _indices = [];
    _quotes = [];
    _summary = null;
    _topGainers = [];
    _topLosers = [];
    _lastUpdate = null;
    _error = null;

    if (_prefs != null) {
      await _prefs!.remove(_cacheKeyIndices);
      await _prefs!.remove(_cacheKeyQuotes);
      await _prefs!.remove(_cacheKeySummary);
      await _prefs!.remove(_cacheKeyGainers);
      await _prefs!.remove(_cacheKeyLosers);
      await _prefs!.remove(_cacheKeyTimestamp);
    }

    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
