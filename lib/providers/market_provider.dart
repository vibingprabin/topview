import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/market_data_api_service.dart';
import '../services/nepse_api_service.dart';
import '../services/widget_service.dart' show WidgetService, IpoWidgetData;

/// Market Data Provider
/// 
/// Manages NEPSE market data state with:
  /// - Integration with Primary Market Data API (primary)
/// - Caching with expiry (5 min for live data, 1 day for static)
/// - Auto-refresh on interval
/// - Error handling with fallback to cached data
/// - Loading states and error messages
class MarketProvider extends ChangeNotifier {
  final MarketDataApiService _marketApiService;
  SharedPreferences? _prefs;
  Timer? _refreshTimer;

  // Cache keys
  static const String _cacheKeyHomeData = 'market_home_data_cache';
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
  Map<String, dynamic>? _homePageData;
  
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
  Map<String, dynamic>? get homePageData => _homePageData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  bool get hasError => _error != null;
  bool get hasData => _indices.isNotEmpty || _quotes.isNotEmpty || _homePageData != null;

  // Convenience getters
  MarketIndex? get nepseIndex {
    if (_indices.isEmpty) {
      // Try to extract from home page data
      if (_homePageData != null) {
        final indicesData = _homePageData!['indices'] as List<dynamic>?;
        if (indicesData != null && indicesData.isNotEmpty) {
          final nepseData = indicesData.firstWhere(
            (i) => i['symbol']?.toString().toUpperCase() == 'NEPSE',
            orElse: () => indicesData.first,
          );
          return MarketIndex(
            name: nepseData['name'] ?? 'NEPSE',
            currentValue: (nepseData['currentValue'] ?? 0).toDouble(),
            previousClose: (nepseData['previousClose'] ?? 0).toDouble(),
            change: (nepseData['change'] ?? 0).toDouble(),
            changePercent: (nepseData['percentChange'] ?? 0).toDouble(),
          );
        }
      }
      return null;
    }
    return _indices.firstWhere(
      (i) => i.name.toLowerCase().contains('nepse'),
      orElse: () => _indices.first,
    );
  }

  bool get isMarketOpen => _marketStatus == MarketStatus.open;

  MarketProvider({MarketDataApiService? apiService})
      : _marketApiService = apiService ?? MarketDataApiService();

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

      // Load home page data cache
      final homeDataJson = _prefs!.getString(_cacheKeyHomeData);
      if (homeDataJson != null) {
        _homePageData = jsonDecode(homeDataJson) as Map<String, dynamic>;
        _parseHomePageData(_homePageData!);
      }

      // Load individual caches as fallback
      if (_indices.isEmpty) {
        final indicesJson = _prefs!.getString(_cacheKeyIndices);
        if (indicesJson != null) {
          final List<dynamic> data = jsonDecode(indicesJson);
          _indices = data.map((e) => MarketIndex.fromJson(e)).toList();
        }
      }

      if (_topGainers.isEmpty) {
        final gainersJson = _prefs!.getString(_cacheKeyGainers);
        if (gainersJson != null) {
          final List<dynamic> data = jsonDecode(gainersJson);
          _topGainers = data.map((e) => MarketMover.fromJson(e)).toList();
        }
      }

      if (_topLosers.isEmpty) {
        final losersJson = _prefs!.getString(_cacheKeyLosers);
        if (losersJson != null) {
          final List<dynamic> data = jsonDecode(losersJson);
          _topLosers = data.map((e) => MarketMover.fromJson(e)).toList();
        }
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

      if (_homePageData != null) {
        await _prefs!.setString(_cacheKeyHomeData, jsonEncode(_homePageData));
      }

      if (_indices.isNotEmpty) {
        await _prefs!.setString(
          _cacheKeyIndices, 
          jsonEncode(_indices.map((e) => e.toJson()).toList()),
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

  /// Refresh all market data using the new API
  Future<void> refreshAllData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Fetch home page data (comprehensive endpoint)
      final homeData = await _marketApiService.getHomePageData();
      
      if (homeData != null) {
        _homePageData = homeData;
        _parseHomePageData(homeData);
        _lastUpdate = DateTime.now();
        _error = null;
        await _saveCache();
        
        // Update home screen widget with market data
        await _updateWidgetMarketData();
        
        // Fetch and update IPO data for widget
        await _updateWidgetIpoData();
      } else {
        // Fallback: try market status endpoint
        final marketStatus = await _marketApiService.getMarketStatus();
        if (marketStatus != null) {
          _parseMarketStatus(marketStatus);
        }
        
        // If still no data and we have cached data, keep it
        if (_homePageData == null && !hasData) {
          _error = 'Unable to fetch market data. Please try again.';
        }
      }
    } catch (e) {
      _error = 'Failed to fetch market data: $e';
      developer.log(_error!, name: 'MarketProvider');
      
      // Keep cached data if available
      if (!hasData) {
        _error = 'No data available. Please check your connection.';
      }
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Parse home page data response
  void _parseHomePageData(Map<String, dynamic> data) {
    try {
      // Parse market status
      final marketStatusData = data['marketStatus'] as Map<String, dynamic>?;
      if (marketStatusData != null) {
        final status = marketStatusData['status']?.toString().toUpperCase() ?? '';
        _marketStatus = _parseMarketStatusString(status);
      }

      // Parse indices
      final indicesData = data['indices'] as List<dynamic>?;
      if (indicesData != null) {
        _indices = indicesData.map((item) => MarketIndex(
          name: item['name'] ?? item['symbol'] ?? 'Unknown',
          currentValue: (item['currentValue'] ?? 0).toDouble(),
          previousClose: (item['previousClose'] ?? 0).toDouble(),
          change: (item['change'] ?? 0).toDouble(),
          changePercent: (item['percentChange'] ?? 0).toDouble(),
        )).toList();
      }

      // Parse sub-indices
      final subIndicesData = data['subIndices'] as List<dynamic>?;
      if (subIndicesData != null) {
        _indices.addAll(subIndicesData.map((item) => MarketIndex(
          name: item['name'] ?? item['symbol'] ?? 'Unknown',
          currentValue: (item['currentValue'] ?? 0).toDouble(),
          previousClose: (item['previousClose'] ?? 0).toDouble(),
          change: (item['change'] ?? 0).toDouble(),
          changePercent: (item['percentChange'] ?? 0).toDouble(),
        )));
      }

      // Parse market summary
      final summaryData = data['marketSummary'] as List<dynamic>?;
      if (summaryData != null) {
        double turnover = 0, trades = 0, volume = 0;
        for (final item in summaryData) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          final value = (item['value'] ?? 0).toDouble();
          
          if (name.contains('turnover')) turnover = value;
          else if (name.contains('trades')) trades = value;
          else if (name.contains('volume')) volume = value;
        }
        
        // Parse stock summary for advances/declines
        final stockSummary = data['stockSummary'] as Map<String, dynamic>?;
        _summary = MarketSummary(
          totalTurnover: turnover,
          totalTrades: trades.toInt(),
          totalVolume: volume.toInt(),
          advanceCount: stockSummary?['advanced'] ?? 0,
          declineCount: stockSummary?['declined'] ?? 0,
          unchangedCount: stockSummary?['unchanged'] ?? 0,
        );
      }

      // Parse top gainers from indices data or dedicated endpoint
      final topGainersData = data['topGainers'] as List<dynamic>?;
      if (topGainersData != null) {
        _topGainers = topGainersData.take(5).map((item) => MarketMover(
          symbol: item['symbol'] ?? '',
          name: item['name'] ?? item['symbol'] ?? '',
          ltp: (item['ltp'] ?? item['close'] ?? 0).toDouble(),
          change: (item['change'] ?? 0).toDouble(),
          changePercent: (item['percentChange'] ?? item['changePercent'] ?? 0).toDouble(),
          volume: (item['volume'] ?? 0).toInt(),
        )).toList();
      }

      // Parse top losers
      final topLosersData = data['topLosers'] as List<dynamic>?;
      if (topLosersData != null) {
        _topLosers = topLosersData.take(5).map((item) => MarketMover(
          symbol: item['symbol'] ?? '',
          name: item['name'] ?? item['symbol'] ?? '',
          ltp: (item['ltp'] ?? item['close'] ?? 0).toDouble(),
          change: (item['change'] ?? 0).toDouble(),
          changePercent: (item['percentChange'] ?? item['changePercent'] ?? 0).toDouble(),
          volume: (item['volume'] ?? 0).toInt(),
        )).toList();
      }
    } catch (e) {
      developer.log('Error parsing home page data: $e', name: 'MarketProvider');
    }
  }

  /// Parse market status response
  void _parseMarketStatus(Map<String, dynamic> data) {
    final status = data['status']?.toString().toUpperCase() ?? '';
    _marketStatus = _parseMarketStatusString(status);
  }

  /// Convert status string to enum
  MarketStatus _parseMarketStatusString(String status) {
    switch (status) {
      case 'OPEN':
      case 'ACTIVE':
        return MarketStatus.open;
      case 'CLOSED':
      case 'CLOSE':
        return MarketStatus.closed;
      case 'PREOPEN':
      case 'PRE-OPEN':
        return MarketStatus.preOpen;
      case 'POSTCLOSE':
      case 'POST-CLOSE':
        return MarketStatus.postClose;
      default:
        return MarketStatus.unknown;
    }
  }

  /// Refresh stock prices
  Future<void> refreshStockPrices({int page = 1, int limit = 50}) async {
    try {
      final data = await _marketApiService.getStockPricesPage(
        page: page,
        limit: limit,
      );
      
      if (data != null) {
        final stocks = data['data'] as List<dynamic>?;
        if (stocks != null) {
          _quotes = stocks.map((item) => StockQuote(
            symbol: item['symbol'] ?? '',
            name: item['securityName'] ?? item['name'] ?? '',
            ltp: (item['lastTradedPrice'] ?? item['close'] ?? 0).toDouble(),
            previousClose: (item['previousDayClosePrice'] ?? 0).toDouble(),
            open: (item['openPrice'] ?? 0).toDouble(),
            high: (item['highPrice'] ?? 0).toDouble(),
            low: (item['lowPrice'] ?? 0).toDouble(),
            volume: (item['totalTradeQuantity'] ?? 0).toInt(),
            change: (item['difference'] ?? 0).toDouble(),
            changePercent: (item['percentageChange'] ?? 0).toDouble(),
          )).toList();
          
          notifyListeners();
        }
      }
    } catch (e) {
      developer.log('Error refreshing stock prices: $e', name: 'MarketProvider');
    }
  }

  /// Get stock quote by symbol
  StockQuote? getQuote(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    try {
      return _quotes.firstWhere(
        (q) => q.symbol.toUpperCase() == upperSymbol,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get live price for a symbol
  double? getLivePrice(String symbol) {
    final quote = getQuote(symbol);
    return quote?.ltp;
  }

  /// Clear all data and cache
  Future<void> clearAllData() async {
    _indices = [];
    _quotes = [];
    _summary = null;
    _topGainers = [];
    _topLosers = [];
    _homePageData = null;
    _lastUpdate = null;
    _error = null;

    if (_prefs != null) {
      await _prefs!.remove(_cacheKeyHomeData);
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

  /// Update the Android home screen widget with market data
  Future<void> _updateWidgetMarketData() async {
    try {
      final index = nepseIndex;
      if (index == null) return;
      
      await WidgetService.updateMarketData(
        nepseIndex: index.currentValue,
        indexChange: index.change,
        indexChangePercent: index.changePercent,
        isMarketOpen: _marketStatus == MarketStatus.open,
      );
      
      developer.log('MarketProvider: Widget market data updated - NEPSE: ${index.currentValue}', name: 'MarketProvider');
    } catch (e) {
      developer.log('MarketProvider: Error updating widget market data: $e', name: 'MarketProvider');
    }
  }

  /// Update the Android home screen widget with IPO data
  Future<void> _updateWidgetIpoData() async {
    try {
      final offerings = await _marketApiService.getPublicOfferings(size: 10);
      
      if (offerings.isEmpty) {
        developer.log('MarketProvider: No IPO data available', name: 'MarketProvider');
        return;
      }
      
      // Filter out closed IPOs and take top 3
      // API returns status values: "Open", "ComingSoon", "Closed"
      final ipos = offerings
          .where((o) => o['status']?.toString().toLowerCase() != 'closed')
          .take(3)
          .map((o) {
            // Parse dates - API returns ISO format like "2026-02-01T00:00:00"
            String formatDate(String? dateStr) {
              if (dateStr == null || dateStr.isEmpty) return '';
              try {
                final date = DateTime.parse(dateStr);
                return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              } catch (_) {
                return dateStr;
              }
            }
            
            return IpoWidgetData(
              companyName: o['name']?.toString() ?? '',
              symbol: o['symbol']?.toString() ?? '',
              openDate: formatDate(o['openingDate']?.toString()),
              closeDate: formatDate(o['closingDate']?.toString()),
              status: o['status']?.toString().toLowerCase() ?? 'upcoming',
              pricePerUnit: (o['price'] ?? 0).toDouble(),
              type: o['type']?.toString().toUpperCase() ?? 'IPO',
            );
          })
          .toList();
      
      if (ipos.isNotEmpty) {
        await WidgetService.updateIpoData(ipos);
        developer.log('MarketProvider: Widget IPO data updated with ${ipos.length} items', name: 'MarketProvider');
      }
    } catch (e) {
      developer.log('MarketProvider: Error updating widget IPO data: $e', name: 'MarketProvider');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _marketApiService.dispose();
    super.dispose();
  }
}
