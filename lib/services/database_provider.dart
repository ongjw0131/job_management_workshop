/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-19 01:14:48
/// @modify date 2025-09-19 01:14:48
/// @desc [DatabaseProvider: Singleton provider for SQLite database connection]
library;

import 'package:job_management_workshop/config/sqlite_config.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:sqflite/sqflite.dart';

/// Global singleton provider for SQLite database connection
class DatabaseProvider {
  static Database? _db;

  /// Returns the singleton database instance, initializing if needed.
  static Future<Database> getDatabase() async {
    AppLogger.info('Getting database instance...');
    if (_db != null) return _db!;
    AppLogger.info('Initializing database...');
    final path = await SqliteConfig.getDbPath();
    _db = await openDatabase(path);
    AppLogger.info('Database initialized at $path');
    return _db!;
  }
}
