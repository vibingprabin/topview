import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service
/// Loads and manages environment variables from .env file
class EnvConfig {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // If .env doesn't exist, use defaults
      print('Warning: .env file not found, using default configuration');
    }
  }

  // API Configuration
  static String get marketApiBaseUrl =>
      dotenv.get('MARKET_API_BASE_URL', fallback: 'https://www.nepalstock.com.np');
  
  static int get apiTimeout =>
      int.tryParse(dotenv.get('API_TIMEOUT', fallback: '15')) ?? 15;

  // Cache Configuration  
  static int get marketDataCacheDuration =>
      int.tryParse(dotenv.get('MARKET_DATA_CACHE_DURATION', fallback: '3600')) ?? 3600;
  
  static int get cacheMaxAgeSeconds =>
      int.tryParse(dotenv.get('CACHE_MAX_AGE_SECONDS', fallback: '86400')) ?? 86400;
  
  static bool get cacheStaleRevalidate =>
      dotenv.get('CACHE_STALE_REVALIDATE', fallback: 'true').toLowerCase() == 'true';

  // Feature Flags
  static bool get enableBackgroundSync =>
      dotenv.get('ENABLE_BACKGROUND_SYNC', fallback: 'true').toLowerCase() == 'true';
  
  static bool get enableNotifications =>
      dotenv.get('ENABLE_NOTIFICATIONS', fallback: 'true').toLowerCase() == 'true';
  
  static bool get enableStopLossAlerts =>
      dotenv.get('ENABLE_STOP_LOSS_ALERTS', fallback: 'true').toLowerCase() == 'true';
  
  static bool get enableIpoAlerts =>
      dotenv.get('ENABLE_IPO_ALERTS', fallback: 'true').toLowerCase() == 'true';
  
  static bool get enablePriceAlerts =>
      dotenv.get('ENABLE_PRICE_ALERTS', fallback: 'true').toLowerCase() == 'true';

  // Notification Settings
  static int get notificationCheckInterval =>
      int.tryParse(dotenv.get('NOTIFICATION_CHECK_INTERVAL', fallback: '300000')) ?? 300000;

  // Database Configuration
  static int get dbVersion =>
      int.tryParse(dotenv.get('DB_VERSION', fallback: '1')) ?? 1;
  
  static bool get enableDbLogging =>
      dotenv.get('ENABLE_DB_LOGGING', fallback: 'false').toLowerCase() == 'true';
}
