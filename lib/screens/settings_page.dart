import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:provider/provider.dart';

import '../providers/portfolio_provider.dart';
import '../providers/market_provider.dart';
import '../themes/broker_intel_theme.dart';
import '../services/notification_service.dart';
import 'input_page.dart';

/// Settings Page
/// 
/// Provides app configuration options including:
/// - Account settings (Client ID switching)
/// - Theme settings (Light/Dark/System)
/// - Data management (Refresh, Clear)
/// - Notification preferences with test button
/// - About information
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _stopLossAlertsEnabled = true;
  bool _priceAlertsEnabled = true;
  bool _ipoAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptiveThemeManager = AdaptiveTheme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Account Settings Section (Client ID)
          _buildSectionCard(
            title: 'Account',
            icon: Icons.account_circle_outlined,
            child: _buildClientIdSelector(),
          ),
          
          const SizedBox(height: 16),
          
          // Theme Settings Section
          _buildSectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: _buildThemeSelector(adaptiveThemeManager, theme),
          ),
          
          const SizedBox(height: 16),
          
          // Notification Settings Section
          _buildSectionCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive alerts and updates',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  icon: Icons.notifications_active_outlined,
                ),
                if (_notificationsEnabled) ...[
                  const Divider(),
                  _buildSwitchTile(
                    title: 'Stop-Loss Alerts',
                    subtitle: 'Notify when stop-loss triggers',
                    value: _stopLossAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _stopLossAlertsEnabled = value);
                    },
                    icon: Icons.trending_down,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: 'Price Alerts',
                    subtitle: 'Notify on price targets',
                    value: _priceAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _priceAlertsEnabled = value);
                    },
                    icon: Icons.price_change_outlined,
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: 'IPO Alerts',
                    subtitle: 'Notify on new IPO/FPO',
                    value: _ipoAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _ipoAlertsEnabled = value);
                    },
                    icon: Icons.new_releases_outlined,
                  ),
                  const Divider(),
                  // Test Notification Button
                  _buildActionTile(
                    title: 'Test Notification',
                    subtitle: 'Send a test notification to verify',
                    icon: Icons.send_outlined,
                    iconColor: BrokerIntelTheme.midIntensity,
                    onTap: () => _sendTestNotification(context),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Data Management Section
          _buildSectionCard(
            title: 'Data Management',
            icon: Icons.storage_outlined,
            child: Column(
              children: [
                // Add Transaction (moved from bottom nav)
                _buildActionTile(
                  title: 'Add Transaction',
                  subtitle: 'Manually paste broker message',
                  icon: Icons.add_circle_outline,
                  iconColor: BrokerIntelTheme.successGreen,
                  onTap: () => _openAddTransaction(context),
                ),
                
                const Divider(),
                
                // Refresh Market Data
                _buildActionTile(
                  title: 'Refresh Market Data',
                  subtitle: 'Fetch latest prices from NEPSE',
                  icon: Icons.refresh,
                  iconColor: BrokerIntelTheme.midIntensity,
                  onTap: () => _refreshMarketData(context),
                ),
                
                const Divider(),
                
                // Re-scan SMS Messages
                _buildActionTile(
                  title: 'Re-scan SMS Messages',
                  subtitle: 'Parse broker messages again',
                  icon: Icons.sms_outlined,
                  iconColor: BrokerIntelTheme.midIntensity,
                  onTap: () => _refreshSmsMessages(context),
                ),
                
                const Divider(),
                
                // Clear Cache
                _buildActionTile(
                  title: 'Clear Cache',
                  subtitle: 'Remove cached market data',
                  icon: Icons.cached,
                  iconColor: BrokerIntelTheme.warningOrange,
                  onTap: () => _clearCache(context),
                ),
                
                const Divider(),
                
                // Clear All Data
                _buildActionTile(
                  title: 'Clear All Data',
                  subtitle: 'Remove all portfolio data',
                  icon: Icons.delete_forever,
                  iconColor: BrokerIntelTheme.dangerRed,
                  onTap: () => _showClearDataDialog(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          _buildSectionCard(
            title: 'About',
            icon: Icons.info_outline,
            child: Column(
              children: [
                _buildInfoTile(
                  title: 'TopView Portfolio Tracker',
                  subtitle: 'Version 1.1.0',
                  icon: Icons.apps,
                ),
                const Divider(),
                _buildInfoTile(
                  title: 'Data Source',
                  subtitle: 'NEPSE Market API',
                  icon: Icons.cloud_outlined,
                ),
                const Divider(),
                _buildInfoTile(
                  title: 'Developer',
                  subtitle: 'Built with Flutter',
                  icon: Icons.code,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Build Client ID selector dropdown
  Widget _buildClientIdSelector() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final availableIds = portfolio.availableClientIds;
        final currentId = portfolio.currentClientId;
        
        if (availableIds.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrokerIntelTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: BrokerIntelTheme.warningOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No client accounts found',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan SMS messages to detect broker accounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Client ID',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            ...availableIds.map((clientId) {
              final isSelected = clientId == currentId;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? BrokerIntelTheme.midIntensity.withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                      ? BrokerIntelTheme.midIntensity
                      : Theme.of(context).dividerColor,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    'Client: $clientId',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: isSelected 
                    ? const Text('Currently active', style: TextStyle(fontSize: 11))
                    : null,
                  value: clientId,
                  groupValue: currentId,
                  activeColor: BrokerIntelTheme.midIntensity,
                  onChanged: (value) async {
                    if (value != null && value != currentId) {
                      await portfolio.setClientId(value);
                      if (context.mounted) {
                        _showSuccessSnackBar(
                          context, 
                          'Switched to Client ID: $value'
                        );
                      }
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              '${availableIds.length} account(s) detected from SMS',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: BrokerIntelTheme.midIntensity),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AdaptiveThemeManager<ThemeData> adaptiveThemeManager, ThemeData theme) {
    return Column(
      children: [
        _buildThemeOption(
          'Light Mode',
          Icons.light_mode,
          adaptiveThemeManager.mode == AdaptiveThemeMode.light,
          () => adaptiveThemeManager.setLight(),
          theme,
        ),
        const SizedBox(height: 8),
        _buildThemeOption(
          'Dark Mode',
          Icons.dark_mode,
          adaptiveThemeManager.mode == AdaptiveThemeMode.dark,
          () => adaptiveThemeManager.setDark(),
          theme,
        ),
        const SizedBox(height: 8),
        _buildThemeOption(
          'System Default',
          Icons.settings_system_daydream,
          adaptiveThemeManager.mode == AdaptiveThemeMode.system,
          () => adaptiveThemeManager.setSystem(),
          theme,
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? theme.colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? theme.colorScheme.primary
            : theme.dividerColor,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
            ? theme.colorScheme.primary
            : theme.iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          ),
        ),
        trailing: isSelected 
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: BrokerIntelTheme.midIntensity),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: BrokerIntelTheme.midIntensity,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: BrokerIntelTheme.midIntensity),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }

  /// Send a test notification
  Future<void> _sendTestNotification(BuildContext context) async {
    try {
      final notificationService = NotificationService();
      await notificationService.showPortfolioNotification(
        title: '🔔 Test Notification',
        message: 'TopView notifications are working correctly!',
      );
      if (context.mounted) {
        _showSuccessSnackBar(context, 'Test notification sent! Check your notification panel.');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to send notification: $e');
      }
    }
  }

  /// Open Add Transaction page
  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const InputPage()),
    );
  }

  Future<void> _refreshMarketData(BuildContext context) async {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    
    _showLoadingDialog(context, 'Refreshing market data...');
    
    try {
      await marketProvider.refreshAllData();
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar(context, 'Market data refreshed successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'Error refreshing market data: $e');
      }
    }
  }

  Future<void> _refreshSmsMessages(BuildContext context) async {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    _showLoadingDialog(context, 'Scanning SMS messages...');
    
    try {
      await portfolioProvider.fetchSmsMessages();
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar(context, 'SMS messages scanned successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'Error scanning SMS: $e');
      }
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove cached market data. Your portfolio data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final marketProvider = Provider.of<MarketProvider>(context, listen: false);
      await marketProvider.clearAllData();
      _showSuccessSnackBar(context, 'Cache cleared successfully');
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your portfolio data including transactions, holdings, and client information.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    
    _showLoadingDialog(context, 'Clearing all data...');
    
    try {
      await portfolioProvider.clearData();
      await marketProvider.clearAllData();
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar(context, 'All data cleared successfully');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(context, 'Error clearing data: $e');
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: BrokerIntelTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: BrokerIntelTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
