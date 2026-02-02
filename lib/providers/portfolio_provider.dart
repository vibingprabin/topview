import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/models/client.dart';
import 'package:topview/models/portfolio_analysis.dart';
import 'package:topview/services/portfolio_service.dart';
import 'package:topview/services/sms_service.dart';
import 'package:topview/services/client_dao.dart';
import 'package:topview/utils/message_parser.dart';
import 'package:topview/utils/market_hours.dart';
import '../services/transaction_dao.dart';
import '../models/share_data.dart';
import '../services/market_data_api_service.dart';
import '../services/database_service.dart';
import '../services/stop_loss_monitor_service.dart';
import '../services/widget_service.dart';

class PortfolioProvider extends ChangeNotifier {
  static const String _prefKeySelectedClientId = 'selected_client_id';
  
  List<Transaction> _transactions = [];
  List<Holding> _holdings = [];
  double _realizedProfitLoss = 0;
  double _breakEvenValue = 0;
  PortfolioAnalysis? _portfolioAnalysis;
  String _currentClientId = '';
  List<String> _availableClientIds = [];
  bool _isLoadingMessages = false;
  bool _hasPermissionError = false;
  Transaction? _lastTransaction;

  Map<String, ShareData> _liveShareDataMap = {};
  final MarketDataApiService _marketApiService = MarketDataApiService();
  final StopLossMonitorService _stopLossMonitor = StopLossMonitorService();
  bool _isShareDataLoading = false;
  String? _shareDataError;
  String? _shareDataDate;

  // Auto-refresh functionality
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = true;
  DateTime? _lastAutoRefresh;

  List<Transaction> get transactions => _transactions;
  List<Holding> get holdings => _holdings;
  double get realizedProfitLoss => _realizedProfitLoss;
  double get breakEvenValue => _breakEvenValue;
  PortfolioAnalysis? get portfolioAnalysis => _portfolioAnalysis;
  String get currentClientId => _currentClientId;
  List<String> get availableClientIds => _availableClientIds;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasPermissionError => _hasPermissionError;
  Transaction? get lastTransaction => _lastTransaction;
  Map<String, ShareData> get liveShareDataMap => _liveShareDataMap;
  bool get isShareDataLoading => _isShareDataLoading;
  String? get shareDataError => _shareDataError;
  String? get shareDataDate => _shareDataDate;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  bool get isMarketOpen => MarketHours.isMarketOpen();
  String get marketStatusText => MarketHours.getMarketStatusText();

  // Initialize portfolio data
  Future<void> initialize() async {
    try {
      // Initialize stop-loss monitoring
      await _stopLossMonitor.startMonitoring();
      
      await _loadClientsFromDatabase();
      if (_availableClientIds.isNotEmpty) {
        // Try to load saved client ID preference
        final savedClientId = await _loadSavedClientId();
        if (savedClientId != null && _availableClientIds.contains(savedClientId)) {
          await setClientId(savedClientId);
        } else {
          await setClientId(_availableClientIds.first);
        }
      } else {
        // If no clients, still try to fetch share data for general use if needed elsewhere
        await fetchLiveShareData(); 
      }
      await _fetchSmsMessagesIncrementally();
      
      // Start auto-refresh timer
      _startAutoRefreshTimer();
    } catch (e) {
      debugPrint('Error initializing portfolio: $e');
    }
  }

  // --- Auto-Refresh Methods ---

  /// Start the auto-refresh timer
  /// Refreshes every 1 minute when market is open, every 5 minutes when closed
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    
    // Check market status and set appropriate interval
    final interval = MarketHours.getRecommendedRefreshInterval();
    debugPrint('Starting auto-refresh timer with interval: ${interval.inMinutes} minutes');
    
    _autoRefreshTimer = Timer.periodic(interval, (_) => _onAutoRefreshTick());
  }

  /// Called on each auto-refresh timer tick
  Future<void> _onAutoRefreshTick() async {
    if (!_autoRefreshEnabled) return;
    
    // Only auto-refresh during market hours
    if (!MarketHours.shouldAutoRefresh()) {
      debugPrint('Auto-refresh skipped: Market is closed');
      // Reconfigure timer for closed market interval if needed
      final currentInterval = MarketHours.getRecommendedRefreshInterval();
      if (currentInterval.inMinutes > 1) {
        _startAutoRefreshTimer(); // Switch to longer interval
      }
      return;
    }

    // Skip if already loading
    if (_isShareDataLoading) {
      debugPrint('Auto-refresh skipped: Already loading');
      return;
    }

    debugPrint('Auto-refresh triggered at ${DateTime.now()}');
    _lastAutoRefresh = DateTime.now();
    
    // Force refresh during market hours to get latest prices
    await fetchLiveShareData(forceRefresh: true);
    
    // Reconfigure timer if market status changed
    _startAutoRefreshTimer();
  }

  /// Enable or disable auto-refresh
  void setAutoRefreshEnabled(bool enabled) {
    _autoRefreshEnabled = enabled;
    debugPrint('Auto-refresh ${enabled ? 'enabled' : 'disabled'}');
    
    if (enabled) {
      _startAutoRefreshTimer();
    } else {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    }
    notifyListeners();
  }

  /// Stop auto-refresh timer (call on dispose)
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Get time since last auto-refresh
  Duration? get timeSinceLastRefresh {
    if (_lastAutoRefresh == null) return null;
    return DateTime.now().difference(_lastAutoRefresh!);
  }

  // Load saved client ID from SharedPreferences
  Future<String?> _loadSavedClientId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefKeySelectedClientId);
    } catch (e) {
      debugPrint('Error loading saved client ID: $e');
      return null;
    }
  }

  // Save selected client ID to SharedPreferences
  Future<void> _saveSelectedClientId(String clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySelectedClientId, clientId);
    } catch (e) {
      debugPrint('Error saving client ID: $e');
    }
  }

  // Load clients from database
  Future<void> _loadClientsFromDatabase() async {
    try {
      final clients = await ClientDAO.getAllClients();
      _availableClientIds = clients.map((c) => c.id).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading clients from database: $e');
    }
  }
  
  // Fetch SMS messages and extract client IDs
  Future<void> fetchSmsMessages() async {
    _isLoadingMessages = true;
    _hasPermissionError = false;
    notifyListeners();
    
    try {
      // Request permission and get messages
      final hasPermission = await SmsService.requestSmsPermission();
      
      if (hasPermission) {
        final messages = await SmsService.getBrokerMessages();
        await processAllMessages(messages);
      } else {
        _hasPermissionError = true;
      }
    } catch (e) {
      debugPrint('Error fetching SMS messages: $e');
      _hasPermissionError = true;
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }
    // Process all broker messages
  Future<void> processAllMessages(List<SmsMessage> messages) async {
    Set<String> clientIdSet = {};
    
    for (var message in messages) {
      final clientId = MessageParser.extractClientId(message.body ?? '');
      if (clientId != null) {
        clientIdSet.add(clientId);
        await processMessage(message.body ?? '', useExtractedClientId: true);
      }
    }
    
    _availableClientIds = clientIdSet.toList()..sort();
    notifyListeners();
  }
    // Set active client ID
  Future<void> setClientId(String clientId) async {
    _currentClientId = clientId;
    await _saveSelectedClientId(clientId); // Persist selection
    _transactions = await TransactionDAO.getTransactionsByClientId(clientId);
    _lastTransaction = await TransactionDAO.getLatestTransaction(clientId);
    await _calculatePortfolioMetrics();
    notifyListeners();
  }

  // Load transactions for current client ID
  Future<void> loadTransactions() async {
    if (_currentClientId.isEmpty) return;
    try {
      _transactions = await TransactionDAO.getTransactionsByClientId(_currentClientId);
      _lastTransaction = await TransactionDAO.getLatestTransaction(_currentClientId);
      // Fetch live share data before calculating metrics
      // This ensures metrics are calculated with the latest available prices
      await fetchLiveShareData(); 
      await _calculatePortfolioMetrics(); // This will now use _liveShareDataMap
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
    // Process new broker message
  Future<bool> processMessage(String message, {bool useExtractedClientId = false}) async {
    final clientId = useExtractedClientId ? MessageParser.extractClientId(message) : _currentClientId;
    
    if (clientId == null && useExtractedClientId) {
      return false;
    }
    
    final newTransactions = MessageParser.parseMessage(
      message, 
      clientId: useExtractedClientId ? null : _currentClientId
    );
    
    if (newTransactions.isNotEmpty) {
      await TransactionDAO.insertTransactions(newTransactions);
      
      // Add new client ID to the list if needed
      if (useExtractedClientId && clientId != null && !_availableClientIds.contains(clientId)) {
        _availableClientIds.add(clientId);
        _availableClientIds.sort();
        
        // Create client record
        final client = Client(
          id: clientId,
          createdAt: DateTime.now(),
          lastTransactionDate: newTransactions.first.date,
        );
        await ClientDAO.insertOrUpdateClient(client);
        
        notifyListeners();
      }
      
      // Update client's last transaction date
      if (clientId != null) {
        await ClientDAO.updateLastTransactionDate(clientId, newTransactions.first.date);
      }
      
      // Only reload if the current client ID matches
      if (newTransactions.first.clientId == _currentClientId) {
        await loadTransactions();
      }
      
      return true;
    }
    
    return false;
  }
  
  // Fetch live share data from Primary API
  // Strategy: Fetch all stocks in one request, cache in SQLite, use cached data
  Future<void> fetchLiveShareData({bool forceRefresh = false}) async {
    _isShareDataLoading = true;
    _shareDataError = null;
    notifyListeners();

    try {
      // Check if we already have today's data cached (unless force refresh)
      if (!forceRefresh) {
        final cachedDate = await DatabaseService.getLatestStoredDataDate();
        final today = DateTime.now().toIso8601String().split('T')[0];
        
        if (cachedDate != null && cachedDate == today) {
          // Use cached data
          final cachedData = await DatabaseService.getShareDataByDate(cachedDate);
          if (cachedData.isNotEmpty) {
            _liveShareDataMap = {for (var item in cachedData) item.symbol: item};
            _shareDataDate = cachedDate;
            debugPrint('Using cached share data for $cachedDate (${cachedData.length} stocks)');
            
            if (_transactions.isNotEmpty) {
              _calculatePortfolioMetrics();
            }
            _isShareDataLoading = false;
            notifyListeners();
            return;
          }
        }
      }

      // Fetch fresh data from API
      debugPrint('Fetching fresh share data from API...');
      final result = await _marketApiService.fetchAllLivePrices();

      if (result['success'] == true) {
        final stocksData = result['data'] as List<Map<String, dynamic>>;
        final date = result['date'] as String? ?? DateTime.now().toIso8601String().split('T')[0];

        // Convert API response to ShareData objects
        final shareDataList = stocksData
            .map((s) => ShareData.fromApiMap(s))
            .where((s) => s.symbol.isNotEmpty)
            .toList();

        debugPrint('Fetched ${shareDataList.length} stocks from API for $date');

        // Store in SQLite for caching
        await DatabaseService.bulkInsertOrUpdateShareData(shareDataList, date);

        // Update in-memory map
        _liveShareDataMap = {for (var item in shareDataList) item.symbol: item};
        _shareDataDate = date;

        if (_transactions.isNotEmpty) {
          _calculatePortfolioMetrics();
        }
      } else {
        _shareDataError = result['error'] as String? ?? 'Unknown API error';
        debugPrint('API error: $_shareDataError');

        // Fallback to cached data if API fails
        final cachedDate = await DatabaseService.getLatestStoredDataDate();
        if (cachedDate != null) {
          final cachedData = await DatabaseService.getShareDataByDate(cachedDate);
          if (cachedData.isNotEmpty) {
            _liveShareDataMap = {for (var item in cachedData) item.symbol: item};
            _shareDataDate = cachedDate;
            debugPrint('Using fallback cached data from $cachedDate');
          }
        }
      }
    } catch (e) {
      _shareDataError = 'Failed to fetch share data: ${e.toString()}';
      debugPrint('PortfolioProvider: $_shareDataError');

      // Fallback to cached data on exception
      try {
        final cachedDate = await DatabaseService.getLatestStoredDataDate();
        if (cachedDate != null) {
          final cachedData = await DatabaseService.getShareDataByDate(cachedDate);
          if (cachedData.isNotEmpty) {
            _liveShareDataMap = {for (var item in cachedData) item.symbol: item};
            _shareDataDate = cachedDate;
            debugPrint('Using fallback cached data from $cachedDate after error');
          }
        }
      } catch (_) {
        // Ignore cache fallback errors
      }
    } finally {
      _isShareDataLoading = false;
      notifyListeners();
    }
  }

  // Method to be called by the settings page button
  Future<void> forceRefreshShareData() async {
    // Set loading and error states appropriately for UI feedback
    _isShareDataLoading = true;
    _shareDataError = null;
    notifyListeners();

    // Call fetchLiveShareData with forceRefresh = true
    await fetchLiveShareData(forceRefresh: true);

    // No need to set _isShareDataLoading to false here as fetchLiveShareData handles it in its finally block.
    // notifyListeners() is also called by fetchLiveShareData.
  }

  // Calculate all portfolio metrics
  Future<void> _calculatePortfolioMetrics() async {
    // Pass the live share data to calculateHoldings
    _holdings = await PortfolioService.calculateHoldings(_transactions, _liveShareDataMap);
    
    // Comprehensive Analysis
    _portfolioAnalysis = PortfolioService.analyzePortfolio(_transactions, _liveShareDataMap);
    _realizedProfitLoss = _portfolioAnalysis?.totalRealizedPnL ?? 0;
    
    _breakEvenValue = PortfolioService.calculateBreakEvenValue(_transactions, _holdings);
    
    // Check for stop-loss triggers after updating holdings
    await _stopLossMonitor.checkHoldings(_holdings);
    
    // Update home screen widget with portfolio data
    await _updateWidgetData();
    
    // Any other metrics that depend on holdings or live data should be recalculated here
    notifyListeners(); // Notify listeners after all metrics are updated
  }

  /// Update the Android home screen widget with current portfolio data
  Future<void> _updateWidgetData() async {
    if (_holdings.isEmpty) return;
    
    try {
      double totalValue = _holdings.fold(0.0, (sum, h) => sum + h.currentValue);
      double totalCost = _holdings.fold(0.0, (sum, h) => sum + (h.averageBuyPrice * h.quantity));
      double totalChange = totalValue - totalCost;
      double changePercent = totalCost > 0 ? (totalChange / totalCost) * 100 : 0;
      
      // Sort holdings by value descending to get top holdings
      final sortedHoldings = List<Holding>.from(_holdings)
        ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
      
      await WidgetService.updatePortfolioData(
        totalValue: totalValue,
        totalChange: totalChange,
        changePercent: changePercent,
        topHoldings: sortedHoldings.take(3).toList(),
      );
      
      debugPrint('PortfolioProvider: Widget data updated - Value: $totalValue, Change: $totalChange');
    } catch (e) {
      debugPrint('PortfolioProvider: Error updating widget data: $e');
    }
  }
    // Clear all data (for testing)
  Future<void> clearData() async {
    await TransactionDAO.deleteAllTransactions();
    await ClientDAO.deleteAllClients();
    _availableClientIds = [];
    _currentClientId = '';
    _transactions = [];
    _holdings = [];
    _lastTransaction = null;
    notifyListeners();
  }

  // Search transactions with various filters
  Future<List<Transaction>> searchTransactions({
    String? symbol,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return await TransactionDAO.searchTransactions(
      clientId: _currentClientId,
      symbol: symbol,
      transactionType: transactionType,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  // Get last transaction insight message
  String getLastTransactionInsight() {
    if (_lastTransaction == null) {
      return "No activity recorded yet.";
    }

    final daysDiff = DateTime.now().difference(_lastTransaction!.date).inDays;
    final transactionType = _lastTransaction!.transactionType == 'Purchased' ? 'Bought' : 'Sold';
    
    if (daysDiff == 0) {
      return "Last activity: $transactionType ${_lastTransaction!.quantity} shares of ${_lastTransaction!.symbol} today.";
    } else if (daysDiff == 1) {
      return "Last activity: $transactionType ${_lastTransaction!.quantity} shares of ${_lastTransaction!.symbol} yesterday.";
    } else if (daysDiff <= 7) {
      return "Last activity: $transactionType ${_lastTransaction!.quantity} shares of ${_lastTransaction!.symbol} $daysDiff days ago.";
    } else {
      return "No activity recorded in the last $daysDiff days.";
    }
  }
    // Fetch SMS messages incrementally (only new messages)
  Future<void> _fetchSmsMessagesIncrementally() async {
    try {
      // Get the latest transaction date to filter new messages
      DateTime? lastTransactionDate;
      if (_availableClientIds.isNotEmpty) {
        final allTransactions = <Transaction>[];
        for (String clientId in _availableClientIds) {
          final clientTransactions = await TransactionDAO.getTransactionsByClientId(clientId);
          allTransactions.addAll(clientTransactions);
        }
        
        if (allTransactions.isNotEmpty) {
          allTransactions.sort((a, b) => b.date.compareTo(a.date));
          lastTransactionDate = allTransactions.first.date;
        }
      }
      
      // Fetch messages (in background without loading indicator)
      final hasPermission = await SmsService.requestSmsPermission();
      
      if (hasPermission) {
        final messages = await SmsService.getBrokerMessages();
        
        // Filter messages newer than last transaction date
        final newMessages = lastTransactionDate != null
            ? messages.where((msg) {
                // Basic date parsing from message - this might need refinement
                // For now, process all messages but we could optimize this
                return true;
              }).toList()
            : messages;
        
        await processAllMessages(newMessages);
      }
    } catch (e) {
      debugPrint('Error fetching SMS messages incrementally: $e');
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    _marketApiService.dispose();
    super.dispose();
  }
}
