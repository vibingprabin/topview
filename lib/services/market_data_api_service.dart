import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import '../config/env_config.dart';

/// Market Data API Service
/// 
/// Provides access to live market data including:
/// - Market Status & Live Data
/// - Stock Prices (Paginated)
/// - Dividends
/// - IPO/FPO Offerings
/// - News/Articles
/// - Bulk Transactions
class MarketDataApiService {
  late final String baseUrl;
  final http.Client _client;
  late final Map<String, String> _headers;

  MarketDataApiService({http.Client? client}) : _client = client ?? http.Client() {
    baseUrl = EnvConfig.marketApiBaseUrl;
    _headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36',
      'Accept': 'application/json',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': '$baseUrl/',
    };
  }

  /// Get current market status
  Future<Map<String, dynamic>?> getMarketStatus() async {
    try {
      final uri = Uri.parse('$baseUrl/live/api/v1/nepselive/market-status');
      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        developer.log('Market status error: ${response.statusCode}', name: 'MarketAPI');
      }
    } catch (e) {
      developer.log('Error fetching market status: $e', name: 'MarketAPI');
    }
    return null;
  }

  /// Fetch all stock prices with pagination
  Future<List<Map<String, dynamic>>> getAllStockPrices({
    int limit = 50,
    String sortBy = '',
    String order = '',
    String searchText = '',
  }) async {
    final allStocks = <Map<String, dynamic>>[];
    int page = 1;

    while (true) {
      try {
        final uri = Uri.parse('$baseUrl/live/api/v2/nepselive/todays-price').replace(
          queryParameters: {
            'queryKey[0]': 'todayPrice',
            'queryKey[1][order]': order,
            'queryKey[1][sortBy]': sortBy,
            'queryKey[1][searchText]': searchText,
            'queryKey[1][page]': page.toString(),
            'queryKey[1][limit]': limit.toString(),
            'queryKey[1][sortDirection]': '',
          },
        );

        final response = await _client.get(uri, headers: _headers)
            .timeout(Duration(seconds: EnvConfig.apiTimeout));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final pageData = data['data'] as List<dynamic>?;

          if (pageData == null || pageData.isEmpty) {
            break;
          }

          allStocks.addAll(pageData.cast<Map<String, dynamic>>());
          page++;

          // Rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          developer.log('Stock prices error page $page: ${response.statusCode}', name: 'MarketAPI');
          break;
        }
      } catch (e) {
        developer.log('Error fetching stocks page $page: $e', name: 'MarketAPI');
        break;
      }
    }

    return allStocks;
  }

  /// Fetch single page of stock prices (for faster initial load)
  Future<Map<String, dynamic>?> getStockPricesPage({
    int page = 1,
    int limit = 50,
    String sortBy = '',
    String order = '',
    String searchText = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/live/api/v2/nepselive/todays-price').replace(
        queryParameters: {
          'queryKey[0]': 'todayPrice',
          'queryKey[1][order]': order,
          'queryKey[1][sortBy]': sortBy,
          'queryKey[1][searchText]': searchText,
          'queryKey[1][page]': page.toString(),
          'queryKey[1][limit]': limit.toString(),
          'queryKey[1][sortDirection]': '',
        },
      );

      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('Error fetching stock prices page: $e', name: 'MarketAPI');
    }
    return null;
  }

  /// Fetch dividend information
  Future<List<Map<String, dynamic>>> getDividends({
    int size = 100,
    bool listedOnly = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/data/api/v1/dividend').replace(
        queryParameters: {
          'size': size.toString(),
          'pageSize': size.toString(),
          'ListedStocksOnly': listedOnly ? 'true' : 'false',
        },
      );

      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final dividends = data['data'] as List<dynamic>?;
        return dividends?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (e) {
      developer.log('Error fetching dividends: $e', name: 'MarketAPI');
    }
    return [];
  }

  /// Fetch IPO/FPO public offerings
  /// 
  /// [offeringType]: 0 for all, specific type for filtered results
  Future<List<Map<String, dynamic>>> getPublicOfferings({
    int size = 100,
    int offeringType = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/data/api/v1/public-offering/').replace(
        queryParameters: {
          'size': size.toString(),
          'type': offeringType.toString(),
          'for': '2',
        },
      );

      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // API returns { data: { content: [...] } } structure
        final dataObj = data['data'];
        if (dataObj is Map<String, dynamic>) {
          final content = dataObj['content'] as List<dynamic>?;
          return content?.cast<Map<String, dynamic>>() ?? [];
        } else if (dataObj is List<dynamic>) {
          // Fallback if API returns list directly
          return dataObj.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      developer.log('Error fetching public offerings: $e', name: 'MarketAPI');
    }
    return [];
  }

  /// Fetch news articles
  Future<Map<String, dynamic>?> getNews({
    int page = 1,
    int size = 20,
    String mediaType = 'News',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/account/api/v1/khula-manch/post').replace(
        queryParameters: {
          'MediaType': mediaType,
          'Size': size.toString(),
          'Page': page.toString(),
        },
      );

      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('Error fetching news: $e', name: 'MarketAPI');
    }
    return null;
  }

  /// Fetch bulk transactions
  Future<List<Map<String, dynamic>>> getBulkTransactions({int size = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/live/api/v1/floorsheet/bulk-transactions').replace(
        queryParameters: {'size': size.toString()},
      );

      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final transactions = data['data'] as List<dynamic>?;
        return transactions?.cast<Map<String, dynamic>>() ?? [];
      }
    } catch (e) {
      developer.log('Error fetching bulk transactions: $e', name: 'MarketAPI');
    }
    return [];
  }

  /// Fetch home page data (comprehensive market overview)
  Future<Map<String, dynamic>?> getHomePageData() async {
    try {
      final uri = Uri.parse('$baseUrl/live/api/v2/nepselive/home-page-data');
      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('Error fetching home page data: $e', name: 'MarketAPI');
    }
    return null;
  }

  /// Harvest all available data at once
  Future<Map<String, dynamic>> harvestAllData() async {
    developer.log('Starting data harvest...', name: 'MarketAPI');

    final results = await Future.wait([
      getMarketStatus().then((v) => MapEntry('marketStatus', v)),
      getStockPricesPage(limit: 100).then((v) => MapEntry('stocks', v)),
      getDividends().then((v) => MapEntry('dividends', v)),
      getPublicOfferings().then((v) => MapEntry('offerings', v)),
      getNews(size: 50).then((v) => MapEntry('news', v)),
      getBulkTransactions().then((v) => MapEntry('bulkTransactions', v)),
      getHomePageData().then((v) => MapEntry('homeData', v)),
    ]);

    developer.log('Data harvest complete!', name: 'MarketAPI');
    return Map.fromEntries(results);
  }

  Future<Map<String, dynamic>> fetchAllLivePrices() async {
    try {
      final uri = Uri.parse('$baseUrl/live/api/v2/nepselive/todays-price').replace(
        queryParameters: {
          'queryKey[0]': 'todayPrice',
          'queryKey[1][page]': '1',
          'queryKey[1][limit]': '500',
        },
      );

      final response = await _client.get(uri, headers: _headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final stocks = data['data'] as List<dynamic>? ?? [];
        
        String? businessDate;
        if (stocks.isNotEmpty) {
          businessDate = stocks.first['businessDate'] as String?;
        }
        
        return {
          'success': true,
          'data': stocks.cast<Map<String, dynamic>>(),
          'date': businessDate,
          'count': stocks.length,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'data': <Map<String, dynamic>>[],
        };
      }
    } catch (e) {
      developer.log('Error fetching all live prices: $e', name: 'MarketAPI');
      return {
        'success': false,
        'error': e.toString(),
        'data': <Map<String, dynamic>>[],
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
