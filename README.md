# TopView

A modern Flutter portfolio tracking application for NEPSE that automatically parses broker SMS messages to track stock transactions and displays them in an organized format.

## Features

- **SMS-based Transaction Parsing**: Automatically detects and parses broker transaction messages
- **Portfolio Tracking**: Track your holdings and transaction history
- **Modern UI**: Clean, Material Design 3 inspired interface with dark/light theme support
- **Local Storage**: Data stored locally with SharedPreferences
- **Future-Ready**: Built with Supabase integration foundation for cloud sync

## First Time Setup

1. Grant SMS permissions when prompted
2. The app will automatically scan your SMS messages for broker transactions
3. Select your client ID from available options
4. View your portfolio and transaction history

## Message Parsing

The app can parse SMS messages from various brokers that follow standard formats:
- Broker messages with format: "BNo.XX Purchased/Sold on DATE (SYMBOL XX kitta @ PRICE)"
- Multiple stock transactions in single SMS
- Automatic client ID extraction from messages

## Architecture

- **Modern Theme**: Material Design 3 with green color scheme and Poppins font
- **State Management**: Provider pattern for reactive state management
- **Local Storage**: SharedPreferences for temporary data storage
- **Future Cloud Sync**: Supabase integration ready for implementation
- **No Dependencies**: Removed SQLite and web scraping for simplified architecture

## Privacy & Security

- All data stored locally on your device
- No data transmitted to external servers currently
- SMS permissions used only for parsing broker messages
- Ready for secure cloud backup with Supabase

## Development Status

- ✅ Core message parsing and portfolio tracking
- ✅ Modern UI with adaptive theming
- ✅ Local data persistence
- 🔄 Supabase cloud integration (planned)
- 🔄 Real-time market data integration (planned)
- 🔄 Advanced portfolio analytics (planned)

## Technical Details

- **Frontend**: Flutter with Material Design 3
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Future Backend**: Supabase
- **Themes**: Adaptive light/dark themes
- **Typography**: Google Fonts (Poppins)