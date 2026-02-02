import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/transaction.dart';

/// SMS Parsing Service
/// 
/// Comprehensive broker SMS message parser for NEPSE transactions.
/// Supports multiple broker message formats and handles various edge cases.
/// 
/// Supported SMS Formats:
/// 1. Standard TMS Alert: "BNo.XX Purchased/Sold 2024-01-15 123456 (SYMBOL 100 kitta @ 500)"
/// 2. Multi-stock: "BNo.XX Purchased 2024-01-15 123456 (SYM1 50 kitta @ 100, SYM2 25 kitta @ 200)"
/// 3. Alternate format: "Dear Client, Your order BNo.XX..."
class SmsParsingService {
  /// Parse a single SMS message body and extract transactions
  static List<Transaction> parseMessage(String body, {String? overrideClientId}) {
    if (body.isEmpty) return [];

    final transactions = <Transaction>[];

    // Try multiple parsing strategies
    transactions.addAll(_parseStandardFormat(body, overrideClientId));
    
    if (transactions.isEmpty) {
      transactions.addAll(_parseAlternateFormat(body, overrideClientId));
    }

    return transactions;
  }

  /// Parse standard broker message format
  /// Format: "BNo.XX Purchased/Sold YYYY-MM-DD CLIENTID (SYMBOL QTY kitta @ PRICE)"
  static List<Transaction> _parseStandardFormat(String body, String? overrideClientId) {
    final transactions = <Transaction>[];

    // Check for required markers
    if (!body.contains('BNo.') || 
        (!body.contains('Purchased') && !body.contains('Sold'))) {
      return transactions;
    }

    try {
      // Extract broker number
      final brokerMatch = RegExp(r'BNo\.(\d+)').firstMatch(body);
      final brokerNumber = brokerMatch?.group(1) ?? '';

      // Determine transaction type
      final transactionType = body.contains('Purchased') ? 'Purchased' : 'Sold';

      // Extract date (YYYY-MM-DD format)
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(body);
      final dateStr = dateMatch?.group(1);
      final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
      
      if (date == null) {
        debugPrint('SmsParsingService: Could not parse date from message');
        return transactions;
      }

      // Extract client ID (number after date)
      String clientId = overrideClientId ?? '';
      if (clientId.isEmpty) {
        final clientMatch = RegExp(r'\d{4}-\d{2}-\d{2}\s+(\d+)').firstMatch(body);
        clientId = clientMatch?.group(1) ?? '';
      }

      if (clientId.isEmpty) {
        debugPrint('SmsParsingService: Could not extract client ID');
        return transactions;
      }

      // Extract stock information from parentheses
      final stockInfoMatch = RegExp(r'\(([^)]+)\)').firstMatch(body);
      if (stockInfoMatch == null) {
        debugPrint('SmsParsingService: Could not find stock info in parentheses');
        return transactions;
      }

      final stocksInfo = stockInfoMatch.group(1) ?? '';
      
      // Split by comma for multiple stocks
      final segments = stocksInfo.split(',');

      for (final segment in segments) {
        final parsed = _parseStockSegment(segment.trim());
        if (parsed != null) {
          transactions.add(Transaction(
            clientId: clientId,
            transactionType: transactionType,
            date: date,
            symbol: parsed['symbol']!,
            quantity: int.parse(parsed['quantity']!),
            price: double.parse(parsed['price']!),
            brokerNumber: brokerNumber,
          ));
        }
      }
    } catch (e) {
      debugPrint('SmsParsingService: Error parsing standard format: $e');
    }

    return transactions;
  }

  /// Parse alternate broker message formats
  static List<Transaction> _parseAlternateFormat(String body, String? overrideClientId) {
    final transactions = <Transaction>[];

    // Pattern: "Dear Client, ... BNo.XX ... Symbol: XXXX, Qty: XX, Rate: XXXX"
    try {
      if (!body.toLowerCase().contains('dear client') && 
          !body.toLowerCase().contains('order executed')) {
        return transactions;
      }

      // Extract broker number
      final brokerMatch = RegExp(r'BNo\.?(\d+)', caseSensitive: false).firstMatch(body);
      final brokerNumber = brokerMatch?.group(1) ?? '';

      // Determine transaction type
      String transactionType = 'Unknown';
      if (body.toLowerCase().contains('buy') || body.toLowerCase().contains('purchased')) {
        transactionType = 'Purchased';
      } else if (body.toLowerCase().contains('sell') || body.toLowerCase().contains('sold')) {
        transactionType = 'Sold';
      }

      // Extract date
      final dateMatch = RegExp(r'(\d{4}[-/]\d{2}[-/]\d{2})|(\d{2}[-/]\d{2}[-/]\d{4})').firstMatch(body);
      DateTime date = DateTime.now();
      if (dateMatch != null) {
        final dateStr = dateMatch.group(0)?.replaceAll('/', '-') ?? '';
        date = DateTime.tryParse(dateStr) ?? DateTime.now();
      }

      // Extract client ID
      String clientId = overrideClientId ?? '';
      if (clientId.isEmpty) {
        final clientMatch = RegExp(r'Client\s*:?\s*(\d+)', caseSensitive: false).firstMatch(body);
        clientId = clientMatch?.group(1) ?? '';
      }

      // Extract symbol, quantity, price
      final symbolMatch = RegExp(r'Symbol\s*:?\s*([A-Z0-9]+)', caseSensitive: false).firstMatch(body);
      final qtyMatch = RegExp(r'Qty\s*:?\s*(\d+)', caseSensitive: false).firstMatch(body);
      final rateMatch = RegExp(r'Rate\s*:?\s*([\d,]+(?:\.\d+)?)', caseSensitive: false).firstMatch(body);

      if (symbolMatch != null && qtyMatch != null && rateMatch != null && clientId.isNotEmpty) {
        final priceStr = rateMatch.group(1)?.replaceAll(',', '') ?? '0';
        
        transactions.add(Transaction(
          clientId: clientId,
          transactionType: transactionType,
          date: date,
          symbol: symbolMatch.group(1) ?? '',
          quantity: int.tryParse(qtyMatch.group(1) ?? '0') ?? 0,
          price: double.tryParse(priceStr) ?? 0,
          brokerNumber: brokerNumber,
        ));
      }
    } catch (e) {
      debugPrint('SmsParsingService: Error parsing alternate format: $e');
    }

    return transactions;
  }

  /// Parse a single stock segment like "SYMBOL 100 kitta @ 500"
  static Map<String, String>? _parseStockSegment(String segment) {
    // Pattern 1: "SYMBOL QTY kitta @ PRICE"
    final pattern1 = RegExp(r'([A-Z0-9]+)\s+(\d+)\s+kitta\s*@\s*([\d,]+(?:\.\d+)?)');
    final match1 = pattern1.firstMatch(segment);
    
    if (match1 != null) {
      return {
        'symbol': match1.group(1) ?? '',
        'quantity': match1.group(2) ?? '0',
        'price': (match1.group(3) ?? '0').replaceAll(',', ''),
      };
    }

    // Pattern 2: "SYMBOL: QTY @ PRICE"
    final pattern2 = RegExp(r'([A-Z0-9]+)\s*:\s*(\d+)\s*@\s*([\d,]+(?:\.\d+)?)');
    final match2 = pattern2.firstMatch(segment);
    
    if (match2 != null) {
      return {
        'symbol': match2.group(1) ?? '',
        'quantity': match2.group(2) ?? '0',
        'price': (match2.group(3) ?? '0').replaceAll(',', ''),
      };
    }

    // Pattern 3: Just "SYMBOL QTY PRICE" (space separated)
    final pattern3 = RegExp(r'([A-Z0-9]+)\s+(\d+)\s+([\d,]+(?:\.\d+)?)');
    final match3 = pattern3.firstMatch(segment);
    
    if (match3 != null) {
      return {
        'symbol': match3.group(1) ?? '',
        'quantity': match3.group(2) ?? '0',
        'price': (match3.group(3) ?? '0').replaceAll(',', ''),
      };
    }

    return null;
  }

  /// Extract client ID from a message
  static String? extractClientId(String body) {
    // Pattern 1: After date "YYYY-MM-DD CLIENTID"
    final pattern1 = RegExp(r'\d{4}-\d{2}-\d{2}\s+(\d+)');
    final match1 = pattern1.firstMatch(body);
    if (match1 != null) return match1.group(1);

    // Pattern 2: "Client: CLIENTID" or "ClientID: XXXX"
    final pattern2 = RegExp(r'Client\s*(?:ID)?\s*:?\s*(\d+)', caseSensitive: false);
    final match2 = pattern2.firstMatch(body);
    if (match2 != null) return match2.group(1);

    // Pattern 3: "A/C: CLIENTID"
    final pattern3 = RegExp(r'A/C\s*:?\s*(\d+)', caseSensitive: false);
    final match3 = pattern3.firstMatch(body);
    if (match3 != null) return match3.group(1);

    return null;
  }

  /// Validate if a message looks like a broker transaction message
  static bool isBrokerMessage(String body) {
    if (body.isEmpty) return false;

    // Must contain broker number
    if (!RegExp(r'BNo\.?\d+', caseSensitive: false).hasMatch(body)) {
      return false;
    }

    // Must contain transaction indicator
    final hasTransactionType = 
        body.toLowerCase().contains('purchased') ||
        body.toLowerCase().contains('sold') ||
        body.toLowerCase().contains('buy') ||
        body.toLowerCase().contains('sell');

    if (!hasTransactionType) return false;

    // Must contain stock symbol pattern
    final hasStockPattern = 
        RegExp(r'[A-Z]{2,10}\s+\d+').hasMatch(body) ||
        RegExp(r'Symbol\s*:', caseSensitive: false).hasMatch(body);

    return hasStockPattern;
  }

  /// Parse multiple SMS messages and return all transactions
  static Future<ParseResult> parseMessages(List<SmsMessage> messages) async {
    final result = ParseResult();
    final clientIds = <String>{};

    for (final message in messages) {
      final body = message.body ?? '';
      
      if (!isBrokerMessage(body)) {
        result.skippedCount++;
        continue;
      }

      final clientId = extractClientId(body);
      if (clientId != null) {
        clientIds.add(clientId);
      }

      final transactions = parseMessage(body);
      if (transactions.isNotEmpty) {
        result.transactions.addAll(transactions);
        result.successCount++;
      } else {
        result.failedCount++;
        result.failedMessages.add(body.substring(0, body.length > 100 ? 100 : body.length));
      }
    }

    result.clientIds = clientIds.toList()..sort();
    return result;
  }
}

/// Result of parsing multiple messages
class ParseResult {
  List<Transaction> transactions = [];
  List<String> clientIds = [];
  List<String> failedMessages = [];
  int successCount = 0;
  int failedCount = 0;
  int skippedCount = 0;

  int get totalProcessed => successCount + failedCount;
  int get totalMessages => totalProcessed + skippedCount;
  
  double get successRate => totalProcessed > 0 
      ? (successCount / totalProcessed) * 100 
      : 0;
}
