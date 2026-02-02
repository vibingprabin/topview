import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/providers/market_provider.dart';
import 'package:topview/screens/main_navigation.dart';
import 'package:topview/themes/broker_intel_theme.dart';
import 'package:topview/services/database_service.dart';
import 'package:topview/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  await EnvConfig.load();

  // Initialize database
  await DatabaseService.database;

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
          home: const MainNavigation(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
