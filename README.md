# TopView - NEPSE Portfolio Tracker

A Flutter portfolio tracking application for the Nepal Stock Exchange (NEPSE) that automatically parses broker SMS messages to track stock transactions and provide real-time portfolio insights with stop-loss monitoring and notifications.

## Features

### Core Features
- **Automatic SMS Parsing**: Scans broker messages to extract transactions
- **Portfolio Tracking**: Real-time holdings with live prices from NEPSE
- **Transaction History**: Complete record of all buy/sell transactions
- **Profit/Loss Tracking**: Both realized and unrealized P/L calculations
- **Market Overview**: Live NEPSE index and market movers

### Stop-Loss & Notifications
- **Stop-Loss Alerts**: Set custom stop-loss prices for holdings
- **Smart Monitoring**: Automatic price monitoring with notifications
- **Persistent Settings**: Stop-loss preferences saved locally
- **Recovery Tracking**: Re-triggers alerts if price drops again after recovery

### Data Management
- **Local-First Architecture**: All data stored on device
- **Efficient Caching**: Smart caching with TTL-based invalidation
  - Market data: 5-minute cache
  - Share prices: Database-backed with daily updates
- **Incremental Updates**: Only processes new SMS messages

### User Experience
- **Dark/Light Theme**: Adaptive theme support
- **Modern UI**: Clean interface with Ferrofluid animations
- **Real-time Updates**: Live price tracking and automatic refreshes

## Setup

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android SDK (for Android builds)
- Xcode (for iOS builds)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd topview
```

2. Install dependencies
```bash
flutter pub get
```

3. Create environment configuration
```bash
cp .env.example .env
```

4. Edit `.env` and add your API keys (optional)
```
NEPSE_API_KEY=your_api_key_here
```

5. Run the app
```bash
flutter run
```

## First Time Setup

1. Grant SMS permissions when prompted
2. The app will automatically scan your SMS messages for broker transactions
3. Select your client ID from the dropdown
4. View your portfolio and transaction history
5. Set stop-loss alerts on your holdings (optional)

## Parsing Format

The app can parse SMS messages from various brokers that follow standard formats:
- Format: "BNo.XX Purchased/Sold on DATE (SYMBOL XX kitta @ PRICE)"
- Supports multiple stock transactions in single SMS
- Automatic client ID extraction from messages

## Privacy & Security

- All data stored locally on your device
- No data transmitted to external servers
- SMS permissions used only for parsing broker messages
- API keys stored securely in .env (gitignored)

## Known Limitations

- Broker commissions not automatically deducted
- Dividend adjustments require manual entry
- Right shares not tracked automatically
- IPO tracking requires manual monitoring (planned feature)

## License

This project is licensed under the MIT License - see the LICENSE file for details.