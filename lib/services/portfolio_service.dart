import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';

class PortfolioService {
  // Calculate current holdings based on transactions
  static List<Holding> calculateHoldings(List<Transaction> transactions) {
    final Map<String, List<Transaction>> groupedBySymbol = {};
    for (var transaction in transactions) {
      if (!groupedBySymbol.containsKey(transaction.symbol)) {
        groupedBySymbol[transaction.symbol] = [];
      }
      groupedBySymbol[transaction.symbol]!.add(transaction);
    }

    List<Holding> holdings = [];
    groupedBySymbol.forEach((symbol, transactions) {
      // Calculate total quantity and total cost for BUY transactions only for current holdings
      // Sell transactions are handled by realized P/L
      List<Transaction> buyTransactions = transactions.where((t) => t.transactionType == 'Purchased').toList();
      List<Transaction> sellTransactions = transactions.where((t) => t.transactionType == 'Sold').toList();

      double averageBuyPrice = 0;

      int cumulatedBuyQuantity = 0;
      double cumulatedBuyCost = 0;
      for (var buyTx in buyTransactions) {
        cumulatedBuyQuantity += buyTx.quantity;
        cumulatedBuyCost += buyTx.quantity * buyTx.price;
      }

      int cumulatedSellQuantity = 0;
      for (var sellTx in sellTransactions) {
        cumulatedSellQuantity += sellTx.quantity;
      }

      int totalQuantity = cumulatedBuyQuantity - cumulatedSellQuantity;

      if (totalQuantity > 0) {
        if (cumulatedBuyQuantity > 0) {
          averageBuyPrice = cumulatedBuyCost / cumulatedBuyQuantity;
        }
        
        double currentInvestedValue = totalQuantity * averageBuyPrice;
        
        // Without live data, current value equals invested value (no profit/loss shown)
        double currentValue = currentInvestedValue;

        
        holdings.add(Holding(
          symbol: symbol,
          quantity: totalQuantity,
          averageBuyPrice: averageBuyPrice,
          investedValue: currentInvestedValue,
          currentValue: currentValue,
          unrealizedPL: 0, // No profit/loss without live data
          unrealizedPLPercentage: 0,
        ));
      }
    });

    return holdings;
  }
  
  // Calculate realized profit/loss
  static double calculateRealizedProfitLoss(List<Transaction> transactions) {
    double realizedPL = 0;
    
    // Group transactions by symbol
    final Map<String, List<Transaction>> groupedBySymbol = {};
    
    for (var transaction in transactions) {
      if (!groupedBySymbol.containsKey(transaction.symbol)) {
        groupedBySymbol[transaction.symbol] = [];
      }
      groupedBySymbol[transaction.symbol]!.add(transaction);
    }
    
    groupedBySymbol.forEach((symbol, transactions) {
      List<Transaction> buys = [];
      
      // Sort transactions by date to maintain FIFO
      transactions.sort((a, b) => a.date.compareTo(b.date));
      
      // Process transactions in chronological order
      for (var transaction in transactions) {
        if (transaction.transactionType == 'Purchased') {
          buys.add(transaction);
        } else if (transaction.transactionType == 'Sold') {
          int remainingSellQuantity = transaction.quantity;
          double sellPrice = transaction.price;
          
          // Apply FIFO principle
          while (remainingSellQuantity > 0 && buys.isNotEmpty) {
            var oldestBuy = buys.first;
            
            if (oldestBuy.quantity <= remainingSellQuantity) {
              // Sell entire oldest buy lot
              realizedPL += oldestBuy.quantity * (sellPrice - oldestBuy.price);
              remainingSellQuantity -= oldestBuy.quantity;
              buys.removeAt(0);
            } else {
              // Partial sell of oldest buy lot
              realizedPL += remainingSellQuantity * (sellPrice - oldestBuy.price);
              buys[0] = Transaction(
                clientId: oldestBuy.clientId,
                transactionType: oldestBuy.transactionType,
                date: oldestBuy.date,
                symbol: oldestBuy.symbol,
                quantity: oldestBuy.quantity - remainingSellQuantity,
                price: oldestBuy.price,
                brokerNumber: oldestBuy.brokerNumber,
              );
              remainingSellQuantity = 0;
            }
          }
        }
      }
    });
    
    return realizedPL;
  }
  
  // Calculate break-even value (total invested amount)
  static double calculateBreakEvenValue(List<Transaction> transactions, List<Holding> holdings) {
    return holdings.fold(0, (sum, holding) => sum + holding.investedValue);
  }
}
