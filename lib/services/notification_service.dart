import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Notification Service
/// 
/// Handles all local notifications for the app:
/// - Stop-loss alerts
/// - Price alerts
/// - IPO announcements
/// - General portfolio notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      final granted = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (granted == true) {
        _initialized = true;
        debugPrint('✅ Notification service initialized');
        
        // Request permissions for Android 13+
        await _requestPermissions();
      } else {
        debugPrint('⚠️ Notification permissions not granted');
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Show stop-loss alert notification
  Future<void> showStopLossAlert({
    required String symbol,
    required double currentPrice,
    required double stopLossPrice,
    required double quantity,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'stop_loss_channel',
      'Stop-Loss Alerts',
      channelDescription: 'Notifications for triggered stop-loss alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Stop-Loss Triggered',
      styleInformation: BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = '🚨 Stop-Loss Triggered: $symbol';
    final body = 'Price dropped to Rs. ${currentPrice.toStringAsFixed(2)} '
        '(Stop-loss: Rs. ${stopLossPrice.toStringAsFixed(2)})\n'
        'Holdings: $quantity units';

    await _notifications.show(
      symbol.hashCode, // Use symbol hash as unique ID
      title,
      body,
      details,
      payload: 'stop_loss:$symbol',
    );
  }

  /// Show price alert notification
  Future<void> showPriceAlert({
    required String symbol,
    required double currentPrice,
    required double targetPrice,
    required String direction, // 'above' or 'below'
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'price_alert_channel',
      'Price Alerts',
      channelDescription: 'Notifications for price target alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Price Alert',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final emoji = direction == 'above' ? '📈' : '📉';
    final title = '$emoji Price Alert: $symbol';
    final body = 'Current price: Rs. ${currentPrice.toStringAsFixed(2)} '
        '(Target: Rs. ${targetPrice.toStringAsFixed(2)})';

    await _notifications.show(
      '${symbol}_price'.hashCode,
      title,
      body,
      details,
      payload: 'price_alert:$symbol',
    );
  }

  /// Show IPO notification
  Future<void> showIpoNotification({
    required String companyName,
    required String openDate,
    required String closeDate,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'ipo_channel',
      'IPO Alerts',
      channelDescription: 'Notifications for new IPO announcements',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'New IPO',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = '🎯 New IPO: $companyName';
    final body = 'Opening: $openDate | Closing: $closeDate';

    await _notifications.show(
      companyName.hashCode,
      title,
      body,
      details,
      payload: 'ipo:$companyName',
    );
  }

  /// Show general portfolio notification
  Future<void> showPortfolioNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'portfolio_channel',
      'Portfolio Updates',
      channelDescription: 'General portfolio notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title,
      message,
      details,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Dispose resources
  void dispose() {
    _initialized = false;
  }
}
