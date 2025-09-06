import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/services/sms_service.dart';
import 'package:topview/utils/message_parser.dart';
import 'package:topview/services/supabase_service.dart';

class PortfolioProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Holding> _holdings = [];
  double _realizedProfitLoss = 0;
  double _breakEvenValue = 0;
  String _currentClientId = '';
  List<String> _availableClientIds = [];
  bool _isLoadingMessages = false;
  bool _hasPermissionError = false;
  Transaction? _lastTransaction;

  final SupabaseService _supabaseService = SupabaseService();

  List<Transaction> get transactions => _transactions;
  List<Holding> get holdings => _holdings;
  double get realizedProfitLoss => _realizedProfitLoss;
  double get breakEvenValue => _breakEvenValue;
  String get currentClientId => _currentClientId;
  List<String> get availableClientIds => _availableClientIds;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasPermissionError => _hasPermissionError;
  Transaction? get lastTransaction => _lastTransaction;

  // Initialize portfolio data
  Future<void> initialize() async {
    try {
      await _loadLocalData();
      await _fetchSmsMessagesIncrementally();
    } catch (e) {
      debugPrint('Error initializing portfolio: $e');
    }
  }

  // Load data from local storage
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load available client IDs
      final clientIdsJson = prefs.getString('available_client_ids');
      if (clientIdsJson != null) {
        final clientIdsList = jsonDecode(clientIdsJson) as List;
        _availableClientIds = clientIdsList.cast<String>();
      }
      
      // Load current client ID
      _currentClientId = prefs.getString('current_client_id') ?? '';
      
      // Load transactions for current client
      if (_currentClientId.isNotEmpty) {
        await _loadTransactionsFromLocal(_currentClientId);
      }
      
      // Set first available client if current one is empty
      if (_currentClientId.isEmpty && _availableClientIds.isNotEmpty) {
        setClientId(_availableClientIds.first);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  // Load transactions from local storage
  Future<void> _loadTransactionsFromLocal(String clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions_$clientId');
      
      if (transactionsJson != null) {
        final transactionsList = jsonDecode(transactionsJson) as List;
        _transactions = transactionsList
            .map((json) => Transaction.fromJson(json))
            .toList();
        
        // Sort by date (newest first)
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        
        // Set last transaction
        _lastTransaction = _transactions.isNotEmpty ? _transactions.first : null;
        
        // Calculate holdings and profits
        _calculateHoldingsFromTransactions();
      } else {
        _transactions = [];
        _holdings = [];
        _lastTransaction = null;
      }
    } catch (e) {
      debugPrint('Error loading transactions from local: $e');
      _transactions = [];
      _holdings = [];
      _lastTransaction = null;
    }
  }

  // Save transactions to local storage
  Future<void> _saveTransactionsToLocal(String clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = jsonEncode(
        _transactions.map((t) => t.toJson()).toList(),
      );
      await prefs.setString('transactions_$clientId', transactionsJson);
    } catch (e) {
      debugPrint('Error saving transactions to local: $e');
    }
  }

  // Save client IDs to local storage
  Future<void> _saveClientIdsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'available_client_ids', 
        jsonEncode(_availableClientIds),
      );
      await prefs.setString('current_client_id', _currentClientId);
    } catch (e) {
      debugPrint('Error saving client IDs to local: $e');
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
    await _saveClientIdsToLocal();
    notifyListeners();
  }

  // Set active client ID
  Future<void> setClientId(String clientId) async {
    _currentClientId = clientId;
    await _saveClientIdsToLocal();
    await _loadTransactionsFromLocal(_currentClientId);
    notifyListeners();
  }

  // Process new broker message
  Future<bool> processMessage(String message, {bool useExtractedClientId = false}) async {
    try {
      final transactions = MessageParser.parseMessage(
        message, 
        clientId: useExtractedClientId ? null : _currentClientId,
      );
      
      if (transactions.isEmpty) return false;
      
      bool hasNewTransaction = false;
      for (var transaction in transactions) {
        if (!_isDuplicateTransaction(transaction)) {
          _transactions.add(transaction);
          hasNewTransaction = true;
          
          // Also save to Supabase (currently no-op)
          await _supabaseService.insertOrUpdateTransaction(transaction);
        }
      }
      
      if (hasNewTransaction) {
        // Sort transactions by date (newest first)
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _lastTransaction = _transactions.first;
        
        // Save to local storage
        await _saveTransactionsToLocal(_currentClientId);
        
        // Recalculate holdings
        _calculateHoldingsFromTransactions();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error processing message: $e');
      return false;
    }
  }

  // Check if transaction is duplicate
  bool _isDuplicateTransaction(Transaction newTransaction) {
    return _transactions.any((existing) =>
        existing.clientId == newTransaction.clientId &&
        existing.transactionType == newTransaction.transactionType &&
        existing.date.isAtSameMomentAs(newTransaction.date) &&
        existing.symbol == newTransaction.symbol &&
        existing.quantity == newTransaction.quantity &&
        existing.price == newTransaction.price &&
        existing.brokerNumber == newTransaction.brokerNumber);
  }

  // Calculate holdings from transactions
  void _calculateHoldingsFromTransactions() {
    if (_transactions.isEmpty) {
      _holdings = [];
      _realizedProfitLoss = 0;
      _breakEvenValue = 0;
      return;
    }

    Map<String, _HoldingCalculation> holdingMap = {};
    double totalRealizedPL = 0;

    for (var transaction in _transactions) {
      final symbol = transaction.symbol;
      holdingMap[symbol] ??= _HoldingCalculation();
      
      final calc = holdingMap[symbol]!;
      
      if (transaction.transactionType == 'Purchased') {
        calc.totalQuantity += transaction.quantity;
        calc.totalInvested += transaction.quantity * transaction.price;
      } else if (transaction.transactionType == 'Sold') {
        final soldQuantity = transaction.quantity;
        final soldPrice = transaction.price;
        
        if (calc.totalQuantity > 0) {
          final avgBuyPrice = calc.totalInvested / calc.totalQuantity;
          final realizedPL = (soldPrice - avgBuyPrice) * soldQuantity;
          totalRealizedPL += realizedPL;
          
          // Reduce holdings
          calc.totalQuantity -= soldQuantity;
          calc.totalInvested -= avgBuyPrice * soldQuantity;
          
          // Ensure no negative quantities
          if (calc.totalQuantity < 0) calc.totalQuantity = 0;
          if (calc.totalInvested < 0) calc.totalInvested = 0;
        }
      }
    }

    // Create holdings list
    _holdings = holdingMap.entries
        .where((entry) => entry.value.totalQuantity > 0)
        .map((entry) {
          final symbol = entry.key;
          final calc = entry.value;
          final avgBuyPrice = calc.totalInvested / calc.totalQuantity;
          
          // For now, use average buy price as current value (no live data)
          final currentValue = calc.totalQuantity * avgBuyPrice;
          
          return Holding(
            symbol: symbol,
            quantity: calc.totalQuantity,
            averageBuyPrice: avgBuyPrice,
            investedValue: calc.totalInvested,
            currentValue: currentValue,
            unrealizedPL: currentValue - calc.totalInvested,
            unrealizedPLPercentage: ((currentValue - calc.totalInvested) / calc.totalInvested) * 100,
          );
        }).toList();

    _realizedProfitLoss = totalRealizedPL;
    _breakEvenValue = _holdings.fold(0, (sum, holding) => sum + holding.investedValue);
  }

  // Get portfolio summary
  String getPortfolioSummary() {
    if (_lastTransaction == null) {
      return "No transactions recorded yet.";
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
          await _loadTransactionsFromLocal(clientId);
          allTransactions.addAll(_transactions);
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

  // Clear all data
  Future<void> clearData() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('transactions_') || 
            key == 'available_client_ids' || 
            key == 'current_client_id') {
          await prefs.remove(key);
        }
      }
      
      // Clear in-memory data
      _transactions = [];
      _holdings = [];
      _availableClientIds = [];
      _currentClientId = '';
      _lastTransaction = null;
      _realizedProfitLoss = 0;
      _breakEvenValue = 0;
      
      // Clear Supabase data (currently no-op)
      await _supabaseService.clearAllData();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }
}

// Helper class for calculations
class _HoldingCalculation {
  int totalQuantity = 0;
  double totalInvested = 0;
}
