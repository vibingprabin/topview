import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/models/share_data.dart'; // Import ShareData
import 'package:topview/models/portfolio_analysis.dart';
import 'stop_loss_dao.dart'; // Import StopLossDAO

class PortfolioService {
  // Calculate current holdings based on transactions
  static Future<List<Holding>> calculateHoldings(
    List<Transaction> transactions, 
    Map<String, ShareData> liveShareData, // Add live share data as a parameter
  ) async {
    final Map<String, List<Transaction>> groupedBySymbol = {};
    for (var transaction in transactions) {
      if (!groupedBySymbol.containsKey(transaction.symbol)) {
        groupedBySymbol[transaction.symbol] = [];
      }
      groupedBySymbol[transaction.symbol]!.add(transaction);
    }

    // Load stop-loss settings once
    final stopLossMap = await StopLossDAO.getAllAsMap();

    List<Holding> holdings = [];
    groupedBySymbol.forEach((symbol, transactions) {
      // Sort transactions by date for FIFO
      transactions.sort((a, b) => a.date.compareTo(b.date));

      List<Transaction> buyPool = [];
      for (var tx in transactions) {
        if (tx.transactionType == 'Purchased') {
          buyPool.add(Transaction(
            clientId: tx.clientId,
            transactionType: tx.transactionType,
            date: tx.date,
            symbol: tx.symbol,
            quantity: tx.quantity,
            price: tx.price,
            brokerNumber: tx.brokerNumber,
          ));
        } else if (tx.transactionType == 'Sold') {
          int remainingSell = tx.quantity;
          while (remainingSell > 0 && buyPool.isNotEmpty) {
            if (buyPool[0].quantity <= remainingSell) {
              remainingSell -= buyPool[0].quantity;
              buyPool.removeAt(0);
            } else {
              buyPool[0] = Transaction(
                clientId: buyPool[0].clientId,
                transactionType: buyPool[0].transactionType,
                date: buyPool[0].date,
                symbol: buyPool[0].symbol,
                quantity: buyPool[0].quantity - remainingSell,
                price: buyPool[0].price,
                brokerNumber: buyPool[0].brokerNumber,
              );
              remainingSell = 0;
            }
          }
        }
      }

      int totalQuantity = buyPool.fold(0, (sum, tx) => sum + tx.quantity);

      if (totalQuantity > 0) {
        double totalCost = buyPool.fold(0.0, (sum, tx) => sum + (tx.quantity * tx.price));
        double averageBuyPrice = totalCost / totalQuantity;
        
        double currentInvestedValue = totalQuantity * averageBuyPrice;

        ShareData? currentShareInfo = liveShareData[symbol];
        double ltp = currentShareInfo?.ltpNumeric ?? averageBuyPrice;
        String? percentChange = currentShareInfo?.percentChange;

        double currentValue = totalQuantity * ltp;
        double unrealizedPL = currentValue - currentInvestedValue;
        double unrealizedPLPercentage = (currentInvestedValue != 0) ? (unrealizedPL / currentInvestedValue) * 100 : 0;

        final stopLossSettings = stopLossMap[symbol];

        holdings.add(Holding(
          symbol: symbol,
          quantity: totalQuantity,
          averageBuyPrice: averageBuyPrice,
          investedValue: currentInvestedValue,
          ltp: ltp,
          percentChange: percentChange,
          currentValue: currentValue,
          unrealizedPL: unrealizedPL,
          unrealizedPLPercentage: unrealizedPLPercentage,
          stopLossPrice: stopLossSettings?.stopLossPrice,
          stopLossEnabled: stopLossSettings?.enabled ?? false,
        ));
      }
    });

    return holdings;
  }
  
  // Comprehensive Portfolio Analysis
  static PortfolioAnalysis analyzePortfolio(
    List<Transaction> transactions,
    Map<String, ShareData> liveShareData,
  ) {
    final Map<String, List<Transaction>> groupedBySymbol = {};
    for (var tx in transactions) {
      if (!groupedBySymbol.containsKey(tx.symbol)) {
        groupedBySymbol[tx.symbol] = [];
      }
      groupedBySymbol[tx.symbol]!.add(tx);
    }

    List<StockPnL> stockPnLs = [];
    Map<String, double> monthlyRealizedPnL = {};
    double totalRealized = 0;
    double totalUnrealized = 0;

    groupedBySymbol.forEach((symbol, symbolTransactions) {
      symbolTransactions.sort((a, b) => a.date.compareTo(b.date));
      
      List<Transaction> buyPool = [];
      double realizedForStock = 0;
      double totalInvestedForStock = 0;

      for (var tx in symbolTransactions) {
        if (tx.transactionType == 'Purchased') {
          totalInvestedForStock += tx.quantity * tx.price;
          buyPool.add(Transaction(
            clientId: tx.clientId,
            transactionType: tx.transactionType,
            date: tx.date,
            symbol: tx.symbol,
            quantity: tx.quantity,
            price: tx.price,
            brokerNumber: tx.brokerNumber,
          ));
        } else if (tx.transactionType == 'Sold') {
          int remainingSell = tx.quantity;
          double sellRealized = 0;
          
          while (remainingSell > 0 && buyPool.isNotEmpty) {
            int usedQty = buyPool[0].quantity <= remainingSell 
                ? buyPool[0].quantity 
                : remainingSell;
            
            double profit = usedQty * (tx.price - buyPool[0].price);
            sellRealized += profit;
            realizedForStock += profit;

            remainingSell -= usedQty;
            if (usedQty == buyPool[0].quantity) {
              buyPool.removeAt(0);
            } else {
              buyPool[0] = Transaction(
                clientId: buyPool[0].clientId,
                transactionType: buyPool[0].transactionType,
                date: buyPool[0].date,
                symbol: buyPool[0].symbol,
                quantity: buyPool[0].quantity - usedQty,
                price: buyPool[0].price,
                brokerNumber: buyPool[0].brokerNumber,
              );
            }
          }
          
          // Monthly tracking
          String monthKey = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
          monthlyRealizedPnL[monthKey] = (monthlyRealizedPnL[monthKey] ?? 0) + sellRealized;
        }
      }

      int currentQty = buyPool.fold(0, (sum, tx) => sum + tx.quantity);
      double avgPrice = currentQty > 0 
          ? buyPool.fold(0.0, (sum, tx) => sum + (tx.quantity * tx.price)) / currentQty 
          : 0;
      
      double ltp = liveShareData[symbol]?.ltpNumeric ?? avgPrice;
      double unrealizedForStock = currentQty * (ltp - avgPrice);

      stockPnLs.add(StockPnL(
        symbol: symbol,
        realizedPnL: realizedForStock,
        unrealizedPnL: unrealizedForStock,
        currentQuantity: currentQty,
        averageBuyPrice: avgPrice,
        totalInvested: totalInvestedForStock,
      ));

      totalRealized += realizedForStock;
      totalUnrealized += unrealizedForStock;
    });

    List<MonthlyPnL> monthlyList = monthlyRealizedPnL.entries
        .map((e) => MonthlyPnL(month: e.key, realizedPnL: e.value))
        .toList()
      ..sort((a, b) => b.month.compareTo(a.month));

    return PortfolioAnalysis(
      stockPnL: stockPnLs,
      monthlyPnL: monthlyList,
      totalRealizedPnL: totalRealized,
      totalUnrealizedPnL: totalUnrealized,
    );
  }

  // Calculate realized profit/loss (Legacy - kept for compatibility)
  static double calculateRealizedProfitLoss(List<Transaction> transactions) {
    return analyzePortfolio(transactions, {}).totalRealizedPnL;
  }
  
  // Calculate break-even portfolio value
  static double calculateBreakEvenValue(List<Transaction> transactions, List<Holding> holdings) {
    double totalInvested = 0;
    
    // Sum the total amount invested across all purchases
    for (var transaction in transactions) {
      if (transaction.transactionType == 'Purchased') {
        totalInvested += transaction.quantity * transaction.price;      } else if (transaction.transactionType == 'Sold') {
        totalInvested -= transaction.quantity * transaction.price;
      }
    }
    
    // The break-even value is what the portfolio must reach to recover the investment
    return double.parse(totalInvested.toStringAsFixed(2));
  }
}
