import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// NEPSE Market Data Models

/// Market Index Data (NEPSE, Sensitive, etc.)
class MarketIndex {
  final String name;
  final double currentValue;
  final double previousClose;
  final double change;
  final double changePercent;
  final DateTime? timestamp;

  MarketIndex({
    required this.name,
    required this.currentValue,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    this.timestamp,
  });

  bool get isPositive => change >= 0;
  bool get isNegative => change < 0;

  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    return MarketIndex(
      name: json['name'] ?? 'Unknown',
      currentValue: (json['current'] ?? json['value'] ?? 0).toDouble(),
      previousClose: (json['previous'] ?? json['previousClose'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? json['percent_change'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'current': currentValue,
    'previous': previousClose,
    'change': change,
    'changePercent': changePercent,
    'timestamp': timestamp?.toIso8601String(),
  };
}

/// Stock Quote Data
class StockQuote {
  final String symbol;
  final String name;
  final double ltp; // Last traded price
  final double previousClose;
  final double open;
  final double high;
  final double low;
  final int volume;
  final double change;
  final double changePercent;
  final String? sector;
  final DateTime? lastUpdated;

  StockQuote({
    required this.symbol,
    required this.name,
    required this.ltp,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.change,
    required this.changePercent,
    this.sector,
    this.lastUpdated,
  });

  bool get isPositive => change >= 0;
  bool get isNegative => change < 0;

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      symbol: json['symbol'] ?? json['scrip'] ?? '',
      name: json['name'] ?? json['company'] ?? '',
      ltp: (json['ltp'] ?? json['last_price'] ?? json['close'] ?? 0).toDouble(),
      previousClose: (json['previous_close'] ?? json['prevClose'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      volume: (json['volume'] ?? json['trade_qty'] ?? 0).toInt(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['percent_change'] ?? json['change_percent'] ?? 0).toDouble(),
      sector: json['sector'],
      lastUpdated: json['last_updated'] != null 
          ? DateTime.tryParse(json['last_updated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'ltp': ltp,
    'previous_close': previousClose,
    'open': open,
    'high': high,
    'low': low,
    'volume': volume,
    'change': change,
    'percent_change': changePercent,
    'sector': sector,
    'last_updated': lastUpdated?.toIso8601String(),
  };
}

/// Market Summary Data
class MarketSummary {
  final double totalTurnover;
  final int totalTrades;
  final int totalVolume;
  final int advanceCount;
  final int declineCount;
  final int unchangedCount;
  final DateTime? timestamp;

  MarketSummary({
    required this.totalTurnover,
    required this.totalTrades,
    required this.totalVolume,
    required this.advanceCount,
    required this.declineCount,
    required this.unchangedCount,
    this.timestamp,
  });

  factory MarketSummary.fromJson(Map<String, dynamic> json) {
    return MarketSummary(
      totalTurnover: (json['turnover'] ?? json['total_turnover'] ?? 0).toDouble(),
      totalTrades: (json['trades'] ?? json['total_trades'] ?? 0).toInt(),
      totalVolume: (json['volume'] ?? json['total_volume'] ?? 0).toInt(),
      advanceCount: (json['advances'] ?? json['advance'] ?? 0).toInt(),
      declineCount: (json['declines'] ?? json['decline'] ?? 0).toInt(),
      unchangedCount: (json['unchanged'] ?? 0).toInt(),
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'turnover': totalTurnover,
    'trades': totalTrades,
    'volume': totalVolume,
    'advances': advanceCount,
    'declines': declineCount,
    'unchanged': unchangedCount,
    'timestamp': timestamp?.toIso8601String(),
  };
}

/// Market Mover (Top Gainer/Loser)
class MarketMover {
  final String symbol;
  final String name;
  final double ltp;
  final double change;
  final double changePercent;
  final int volume;

  MarketMover({
    required this.symbol,
    required this.name,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.volume,
  });

  bool get isGainer => change >= 0;
  bool get isLoser => change < 0;

  factory MarketMover.fromJson(Map<String, dynamic> json) {
    return MarketMover(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      ltp: (json['ltp'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['percent_change'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'ltp': ltp,
    'change': change,
    'percent_change': changePercent,
    'volume': volume,
  };
}

/// Market Status
enum MarketStatus { open, closed, preOpen, postClose, unknown }

/// NEPSE API Service
/// 
/// Handles communication with NEPSE market data API.
/// Base URL is configured via environment variables.
class NepseApiService {
  final http.Client _client;
  late final String _baseUrl;

  NepseApiService({http.Client? client})
      : _client = client ?? http.Client() {
    _baseUrl = EnvConfig.marketApiBaseUrl;
  }

  /// Get market indices (NEPSE, Sensitive, Float, etc.)
  Future<List<MarketIndex>> getMarketIndices() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/indices'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> indices = data['indices'] ?? data['data'] ?? [];
        return indices.map((e) => MarketIndex.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Error fetching market indices: $e', name: 'NepseApiService');
    }
    return [];
  }

  /// Get NEPSE index specifically
  Future<MarketIndex?> getNepseIndex() async {
    final indices = await getMarketIndices();
    return indices.firstWhere(
      (i) => i.name.toLowerCase().contains('nepse'),
      orElse: () => indices.first,
    );
  }

  /// Get all stock quotes
  Future<List<StockQuote>> getAllQuotes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/quotes'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> quotes = data['quotes'] ?? data['data'] ?? [];
        return quotes.map((e) => StockQuote.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Error fetching quotes: $e', name: 'NepseApiService');
    }
    return [];
  }

  /// Get specific stock quote
  Future<StockQuote?> getQuote(String symbol) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/quote/$symbol'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StockQuote.fromJson(data);
      }
    } catch (e) {
      developer.log('Error fetching quote for $symbol: $e', name: 'NepseApiService');
    }
    return null;
  }

  /// Get market summary
  Future<MarketSummary?> getMarketSummary() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/summary'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MarketSummary.fromJson(data);
      }
    } catch (e) {
      developer.log('Error fetching market summary: $e', name: 'NepseApiService');
    }
    return null;
  }

  /// Get top gainers
  Future<List<MarketMover>> getTopGainers({int limit = 5}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/gainers?limit=$limit'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> gainers = data['gainers'] ?? data['data'] ?? [];
        return gainers.map((e) => MarketMover.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Error fetching top gainers: $e', name: 'NepseApiService');
    }
    return [];
  }

  /// Get top losers
  Future<List<MarketMover>> getTopLosers({int limit = 5}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/losers?limit=$limit'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> losers = data['losers'] ?? data['data'] ?? [];
        return losers.map((e) => MarketMover.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Error fetching top losers: $e', name: 'NepseApiService');
    }
    return [];
  }

  /// Get market status
  Future<MarketStatus> getMarketStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString().toLowerCase() ?? 'unknown';
        
        switch (status) {
          case 'open':
          case 'active':
            return MarketStatus.open;
          case 'closed':
          case 'close':
            return MarketStatus.closed;
          case 'preopen':
          case 'pre-open':
            return MarketStatus.preOpen;
          case 'postclose':
          case 'post-close':
            return MarketStatus.postClose;
          default:
            return MarketStatus.unknown;
        }
      }
    } catch (e) {
      developer.log('Error fetching market status: $e', name: 'NepseApiService');
    }
    return MarketStatus.unknown;
  }

  /// Search stocks
  Future<List<StockQuote>> searchStocks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/market/search?q=$query'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? data['data'] ?? [];
        return results.map((e) => StockQuote.fromJson(e)).toList();
      }
    } catch (e) {
      developer.log('Error searching stocks: $e', name: 'NepseApiService');
    }
    return [];
  }

  void dispose() {
    _client.close();
  }
}
