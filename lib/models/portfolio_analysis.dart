import 'package:topview/models/transaction.dart';

class StockPnL {
  final String symbol;
  double realizedPnL;
  double unrealizedPnL;
  int currentQuantity;
  double averageBuyPrice;
  double totalInvested; // Total amount invested (including sold positions)
  
  StockPnL({
    required this.symbol,
    this.realizedPnL = 0,
    this.unrealizedPnL = 0,
    this.currentQuantity = 0,
    this.averageBuyPrice = 0,
    this.totalInvested = 0,
  });

  double get totalPnL => realizedPnL + unrealizedPnL;
  
  // Calculate percentage return based on total invested amount
  double get totalPnLPercentage => totalInvested > 0 ? (totalPnL / totalInvested) * 100 : 0;
}

class MonthlyPnL {
  final String month; // Format: YYYY-MM
  double realizedPnL;
  
  MonthlyPnL({
    required this.month,
    this.realizedPnL = 0,
  });
}

class PortfolioAnalysis {
  final List<StockPnL> stockPnL;
  final List<MonthlyPnL> monthlyPnL;
  final double totalRealizedPnL;
  final double totalUnrealizedPnL;

  PortfolioAnalysis({
    required this.stockPnL,
    required this.monthlyPnL,
    required this.totalRealizedPnL,
    required this.totalUnrealizedPnL,
  });
}
