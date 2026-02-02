import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/providers/market_provider.dart';
import 'package:topview/screens/main_navigation.dart';
import 'package:topview/themes/broker_intel_theme.dart';
import 'package:topview/services/database_service.dart';
import 'package:topview/services/widget_service.dart';
import 'package:topview/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  await EnvConfig.load();

  // Initialize database
  await DatabaseService.database;

  // Initialize widget service
  await WidgetService.initialize();

  // Get saved theme mode
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  runApp(MyApp(savedThemeMode: savedThemeMode));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PortfolioProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => MarketProvider()..initialize(),
        ),
      ],
      child: AdaptiveTheme(
        light: BrokerIntelTheme.lightTheme,
        dark: BrokerIntelTheme.darkTheme,
        initial: savedThemeMode ?? AdaptiveThemeMode.light,
        builder: (theme, darkTheme) => MaterialApp(
          title: 'TopView - NEPSE Portfolio',
          theme: theme,
          darkTheme: darkTheme,
          home: const WidgetIntentHandler(child: MainNavigation()),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

/// Handles deep link intents from the Android widget
/// Checks for widget_refresh URI on startup and app resume
class WidgetIntentHandler extends StatefulWidget {
  final Widget child;
  
  const WidgetIntentHandler({super.key, required this.child});

  @override
  State<WidgetIntentHandler> createState() => _WidgetIntentHandlerState();
}

class _WidgetIntentHandlerState extends State<WidgetIntentHandler> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.topview/widget');
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for intent on startup
    _checkWidgetIntent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for intent when app resumes (e.g., from widget tap)
      _checkWidgetIntent();
    }
  }

  Future<void> _checkWidgetIntent() async {
    try {
      // Try to get the launch URI from platform channel
      final String? uri = await platform.invokeMethod('getInitialUri');
      if (uri != null && uri.contains('widget_refresh')) {
        debugPrint('WidgetIntentHandler: Received widget_refresh intent');
        await _handleWidgetRefresh();
      }
    } on PlatformException catch (e) {
      // Platform channel not set up, fall back to pending navigation check
      debugPrint('WidgetIntentHandler: Platform channel error: ${e.message}');
    } catch (e) {
      debugPrint('WidgetIntentHandler: Error checking intent: $e');
    }
    
    // Also check for pending navigation from WidgetService
    final pending = await WidgetService.getPendingNavigation();
    if (pending == 'refresh') {
      debugPrint('WidgetIntentHandler: Found pending refresh request');
      await _handleWidgetRefresh();
    }
  }

  Future<void> _handleWidgetRefresh() async {
    if (!mounted) return;
    
    debugPrint('WidgetIntentHandler: Triggering data refresh');
    
    // Refresh both market and portfolio data
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    await Future.wait([
      marketProvider.refreshAllData(),
      portfolioProvider.forceRefreshShareData(),
    ]);
    
    debugPrint('WidgetIntentHandler: Data refresh complete');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
