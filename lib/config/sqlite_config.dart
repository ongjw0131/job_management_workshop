/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 15:29:48
/// @modify date 2025-09-11 15:29:48
/// @desc [SQLiteConfig: Configuration constants for SQLite database.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SqliteConfig {
  static const String dbName = 'job_management.db';

  static Future<String> getDbPath() async {
    AppLogger.info('Getting database path...');
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, dbName);
    AppLogger.info('Database path: $path');
    return path;
  }
}
