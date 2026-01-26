import 'package:sqflite/sqflite.dart' as sqflite;
import 'database_service.dart';

/// Stop-Loss Settings Model
class StopLossSettings {
  final String symbol;
  final double stopLossPrice;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StopLossSettings({
    required this.symbol,
    required this.stopLossPrice,
    required this.enabled,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'stop_loss_price': stopLossPrice,
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory StopLossSettings.fromMap(Map<String, dynamic> map) {
    return StopLossSettings(
      symbol: map['symbol'] as String,
      stopLossPrice: map['stop_loss_price'] as double,
      enabled: (map['enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }
}

/// Data Access Object for Stop-Loss Settings
class StopLossDAO {
  static const String tableName = 'stop_loss_settings';

  static Future<sqflite.Database> get _db async => await DatabaseService.database;

  /// Create the stop-loss settings table
  static Future<void> createTable(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        symbol TEXT PRIMARY KEY,
        stop_loss_price REAL NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  /// Get stop-loss settings for a specific symbol
  static Future<StopLossSettings?> getBySymbol(String symbol) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'symbol = ?',
      whereArgs: [symbol],
    );

    if (maps.isEmpty) return null;
    return StopLossSettings.fromMap(maps.first);
  }

  /// Get all stop-loss settings
  static Future<List<StopLossSettings>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => StopLossSettings.fromMap(maps[i]));
  }

  /// Get all enabled stop-loss settings
  static Future<List<StopLossSettings>> getAllEnabled() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'enabled = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => StopLossSettings.fromMap(maps[i]));
  }

  /// Upsert (insert or update) stop-loss settings
  static Future<void> upsert(StopLossSettings settings) async {
    final db = await _db;
    
    // Check if exists
    final existing = await getBySymbol(settings.symbol);
    
    if (existing == null) {
      // Insert new
      await db.insert(tableName, settings.toMap());
    } else {
      // Update existing with new timestamp
      final updated = StopLossSettings(
        symbol: settings.symbol,
        stopLossPrice: settings.stopLossPrice,
        enabled: settings.enabled,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.update(
        tableName,
        updated.toMap(),
        where: 'symbol = ?',
        whereArgs: [settings.symbol],
      );
    }
  }

  /// Enable/disable stop-loss for a symbol
  static Future<void> setEnabled(String symbol, bool enabled) async {
    final db = await _db;
    await db.update(
      tableName,
      {
        'enabled': enabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'symbol = ?',
      whereArgs: [symbol],
    );
  }

  /// Delete stop-loss settings for a symbol
  static Future<void> delete(String symbol) async {
    final db = await _db;
    await db.delete(
      tableName,
      where: 'symbol = ?',
      whereArgs: [symbol],
    );
  }

  /// Delete all stop-loss settings
  static Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(tableName);
  }

  /// Get stop-loss settings as a map (symbol -> settings)
  static Future<Map<String, StopLossSettings>> getAllAsMap() async {
    final all = await getAll();
    return {for (var s in all) s.symbol: s};
  }
}
