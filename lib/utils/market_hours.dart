/// Market Hours Utility for NEPSE (Nepal Stock Exchange)
/// 
/// Trading hours: Sunday to Thursday, 11:00 AM - 3:00 PM Nepal Time (NPT)
/// Nepal Time is UTC+5:45

class MarketHours {
  // Nepal is UTC+5:45
  static const Duration _nepalUtcOffset = Duration(hours: 5, minutes: 45);
  
  // Market hours (in 24-hour format)
  static const int _marketOpenHour = 11;  // 11:00 AM
  static const int _marketOpenMinute = 0;
  static const int _marketCloseHour = 15; // 3:00 PM
  static const int _marketCloseMinute = 0;
  
  // Trading days: Sunday (7) to Thursday (4)
  // In Dart: Monday=1, Tuesday=2, ..., Sunday=7
  static const List<int> _tradingDays = [7, 1, 2, 3, 4]; // Sun, Mon, Tue, Wed, Thu

  /// Get current time in Nepal timezone
  static DateTime getNepaliTime() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(_nepalUtcOffset);
  }

  /// Check if today is a trading day (Sunday to Thursday)
  static bool isTradingDay([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    return _tradingDays.contains(now.weekday);
  }

  /// Check if current time is within market hours (11 AM - 3 PM NPT)
  static bool isWithinMarketHours([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    
    final marketOpen = DateTime(now.year, now.month, now.day, _marketOpenHour, _marketOpenMinute);
    final marketClose = DateTime(now.year, now.month, now.day, _marketCloseHour, _marketCloseMinute);
    
    return now.isAfter(marketOpen) && now.isBefore(marketClose);
  }

  /// Check if the market is currently open (trading day + within hours)
  static bool isMarketOpen([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    return isTradingDay(now) && isWithinMarketHours(now);
  }

  /// Get time until market opens (returns null if market is open or closed for the day)
  static Duration? timeUntilMarketOpen([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    
    if (!isTradingDay(now)) return null;
    
    final marketOpen = DateTime(now.year, now.month, now.day, _marketOpenHour, _marketOpenMinute);
    
    if (now.isBefore(marketOpen)) {
      return marketOpen.difference(now);
    }
    
    return null; // Market is open or already closed
  }

  /// Get time until market closes (returns null if market is closed)
  static Duration? timeUntilMarketClose([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    
    if (!isMarketOpen(now)) return null;
    
    final marketClose = DateTime(now.year, now.month, now.day, _marketCloseHour, _marketCloseMinute);
    return marketClose.difference(now);
  }

  /// Get a human-readable market status string
  static String getMarketStatusText([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    
    if (isMarketOpen(now)) {
      final closeIn = timeUntilMarketClose(now);
      if (closeIn != null) {
        final hours = closeIn.inHours;
        final minutes = closeIn.inMinutes % 60;
        if (hours > 0) {
          return 'Market Open (closes in ${hours}h ${minutes}m)';
        }
        return 'Market Open (closes in ${minutes}m)';
      }
      return 'Market Open';
    }
    
    if (!isTradingDay(now)) {
      return 'Market Closed (Weekend)';
    }
    
    final marketOpen = DateTime(now.year, now.month, now.day, _marketOpenHour, _marketOpenMinute);
    final marketClose = DateTime(now.year, now.month, now.day, _marketCloseHour, _marketCloseMinute);
    
    if (now.isBefore(marketOpen)) {
      final openIn = timeUntilMarketOpen(now);
      if (openIn != null) {
        final hours = openIn.inHours;
        final minutes = openIn.inMinutes % 60;
        if (hours > 0) {
          return 'Market Closed (opens in ${hours}h ${minutes}m)';
        }
        return 'Market Closed (opens in ${minutes}m)';
      }
    }
    
    if (now.isAfter(marketClose)) {
      return 'Market Closed (trading ended)';
    }
    
    return 'Market Closed';
  }

  /// Get the recommended refresh interval based on market status
  /// Returns Duration for auto-refresh timer
  static Duration getRecommendedRefreshInterval([DateTime? nepaliTime]) {
    final now = nepaliTime ?? getNepaliTime();
    
    if (isMarketOpen(now)) {
      // During market hours: refresh every 1 minute
      return const Duration(minutes: 1);
    }
    
    // Market closed: refresh every 5 minutes (or could be longer)
    return const Duration(minutes: 5);
  }

  /// Check if we should auto-refresh data
  /// Returns true only during market hours on trading days
  static bool shouldAutoRefresh([DateTime? nepaliTime]) {
    return isMarketOpen(nepaliTime);
  }
}
