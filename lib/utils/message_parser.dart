import 'package:topview/models/transaction.dart';
import 'package:topview/services/sms_parsing_service.dart';

/// Message Parser - Wrapper for SmsParsingService
/// 
/// This class provides backward compatibility with existing code
/// while delegating to the comprehensive SmsParsingService.
class MessageParser {
  /// Parse a broker SMS message and extract transactions
  static List<Transaction> parseMessage(String message, {String? clientId}) {
    return SmsParsingService.parseMessage(message, overrideClientId: clientId);
  }
  
  /// Extract client ID from a broker message
  static String? extractClientId(String message) {
    return SmsParsingService.extractClientId(message);
  }

  /// Check if a message is a valid broker transaction message
  static bool isBrokerMessage(String message) {
    return SmsParsingService.isBrokerMessage(message);
  }
}
