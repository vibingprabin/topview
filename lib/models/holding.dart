class Holding {
  final String symbol;
  final int quantity;
  final double averageBuyPrice;
  // final double currentValue; // Will be calculated using LTP
  final double investedValue;
  // final double profitLoss; // Will be replaced by unrealizedPL
  // final double profitLossPercentage; // Will be replaced by unrealizedPLPercentage

  // New fields for live data
  final double? ltp; // Last Traded Price
  final String? percentChange; // From scraped data
  final double currentValue; // Calculated: quantity * (ltp ?? averageBuyPrice)
  final double unrealizedPL; // Calculated: currentValue - investedValue
  final double unrealizedPLPercentage; // Calculated: (unrealizedPL / investedValue) * 100

  // Stop-loss fields
  final double? stopLossPrice; // User-defined stop-loss trigger price
  final bool stopLossEnabled; // Whether stop-loss monitoring is active

  Holding({
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
    required this.investedValue,
    this.ltp,
    this.percentChange,
    // Calculated fields are now required
    required this.currentValue,
    required this.unrealizedPL,
    required this.unrealizedPLPercentage,
    // Stop-loss fields
    this.stopLossPrice,
    this.stopLossEnabled = false,
  });

  // Helper to create a holding without live data (e.g. if API fails)
  factory Holding.withoutLiveData({
    required String symbol,
    required int quantity,
    required double averageBuyPrice,
    double? stopLossPrice,
    bool stopLossEnabled = false,
  }) {
    final invested = quantity * averageBuyPrice;
    return Holding(
      symbol: symbol,
      quantity: quantity,
      averageBuyPrice: averageBuyPrice,
      investedValue: invested,
      ltp: null, // No LTP available
      percentChange: null,
      currentValue: invested, // Current value is same as invested if no LTP
      unrealizedPL: 0, // No profit or loss if no LTP
      unrealizedPLPercentage: 0,
      stopLossPrice: stopLossPrice,
      stopLossEnabled: stopLossEnabled,
    );
  }

  // Create a copy with updated fields
  Holding copyWith({
    String? symbol,
    int? quantity,
    double? averageBuyPrice,
    double? investedValue,
    double? ltp,
    String? percentChange,
    double? currentValue,
    double? unrealizedPL,
    double? unrealizedPLPercentage,
    double? stopLossPrice,
    bool? stopLossEnabled,
  }) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
      investedValue: investedValue ?? this.investedValue,
      ltp: ltp ?? this.ltp,
      percentChange: percentChange ?? this.percentChange,
      currentValue: currentValue ?? this.currentValue,
      unrealizedPL: unrealizedPL ?? this.unrealizedPL,
      unrealizedPLPercentage: unrealizedPLPercentage ?? this.unrealizedPLPercentage,
      stopLossPrice: stopLossPrice ?? this.stopLossPrice,
      stopLossEnabled: stopLossEnabled ?? this.stopLossEnabled,
    );
  }

  // Check if stop-loss has been triggered
  bool get isStopLossTriggered {
    if (!stopLossEnabled || stopLossPrice == null || ltp == null) {
      return false;
    }
    return ltp! <= stopLossPrice!;
  }
}
