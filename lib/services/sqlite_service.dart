/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 17:41:05
/// @modify date 2025-09-20 17:41:05
/// @desc [SQLiteService: Manages local SQLite database operations and synchronization with Supabase.]]
library;

import 'package:job_management_workshop/config/sqlite_config.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/repositories/customer_repository.dart';
import 'package:job_management_workshop/repositories/notification_repository.dart';
import 'package:job_management_workshop/repositories/staff_repository.dart';
import 'package:job_management_workshop/repositories/task_repository.dart';
import 'package:job_management_workshop/services/customer_service.dart';
import 'package:job_management_workshop/services/notification_service.dart';
import 'package:job_management_workshop/services/staff_service.dart';
import 'package:job_management_workshop/services/task_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();

  factory SQLiteService() => _instance;

  SQLiteService._internal();

  Database? _db;

  /// Initializes the SQLite database and creates tables if they do not exist.
  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, SqliteConfig.dbName);
    AppLogger.info('Initializing SQLite DB at: $path');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS staff (
            staff_id TEXT PRIMARY KEY,
            password TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            role TEXT,
            email TEXT,
            phone_number TEXT,
            address TEXT,
            profile_image TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now'))
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer (
            customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            vehicle_make TEXT,
            vehicle_model TEXT,
            vehicle_registration TEXT,
            equipment_type TEXT,
            equipment_serial TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS task (
            task_id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            order_id TEXT,
            customer_id INTEGER,
            description TEXT,
            status TEXT CHECK (status IN ('assigned', 'accepted', 'completed')),
            deadline TEXT,
            created_at TEXT DEFAULT (datetime('now')),
            staff_id TEXT NOT NULL,
            repair_image_path TEXT,
            upload_image_path TEXT,
            signature_path TEXT,
            FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE SET NULL,
            FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            staff_id TEXT NOT NULL,
            task_id INTEGER,
            title TEXT NOT NULL,
            subtitle TEXT,
            description TEXT,
            icon_type TEXT DEFAULT 'notifications',
            icon_color TEXT DEFAULT 'blue',
            is_read INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
            -- 🚨 Unique constraint to prevent duplicates
            UNIQUE (staff_id, task_id, title)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS task_time_logs (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            staff_id TEXT NOT NULL,
            action TEXT NOT NULL CHECK (action IN ('start', 'pause', 'resume', 'complete')),
            timestamp TEXT NOT NULL,
            duration TEXT,
            FOREIGN KEY (task_id) REFERENCES task(task_id) ON DELETE CASCADE,
            FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  /// Fetches data from Supabase for the given staffId and synchronizes it into the local SQLite database.
  /// Also reconciles local tasks that are not present on the server.
  Future<void> fetchFromSupabase(String staffId) async {
    // Initialize DB if not already
    await initialize();

    // Fetch data from Supabase
    final staffData = await StaffService().getStaffById(staffId);
    final taskList = await TaskService().getAllTaskByStaffId(staffId);
    final customerList = await CustomerService().getAllCustomers();
    final notificationList = await NotificationService()
        .getAllNotificationsByStaffId(staffId);

    // Batch insert into SQLite
    final batch = _db!.batch();
    await StaffRepository().batchInsertStaff(batch, staffData);
    await TaskRepository().batchInsertTaskList(batch, taskList);
    await CustomerRepository().batchInsertCustomerList(batch, customerList);
    await NotificationRepository().batchInsertNotificationList(
      batch,
      notificationList,
    );
    await batch.commit(noResult: true);
    AppLogger.info('Sync with Supabase completed.');

    // Reconcile local tasks not present on server
    try {
      final serverTaskIds = <int>{};
      for (final t in taskList) {
        try {
          final dynamic raw = t.taskId;
          if (raw == null) continue;
          if (raw is int) {
            serverTaskIds.add(raw);
          } else {
            final parsed = int.tryParse(raw.toString());
            if (parsed != null) serverTaskIds.add(parsed);
          }
        } catch (_) {}
      }
      final deletedCount = await TaskRepository().deleteTasksNotOnServer(
        staffId: staffId,
        serverTaskIds: serverTaskIds,
        db: _db,
      );
      if (deletedCount > 0) {
        AppLogger.info(
          'Reconciled and deleted $deletedCount local task(s) not present on server',
        );
      }
    } catch (e) {
      AppLogger.error('Reconciliation error: $e');
    }
  }

  /// Closes the SQLite database connection if open.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  /// Upserts (inserts or replaces) a list of records for the specified table in the SQLite database.
  Future<void> upsertRecordsForTable(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    await initialize();
    if (records.isEmpty) return;
    final batch = _db!.batch();
    for (final rec in records) {
      final row = Map<String, dynamic>.from(rec);
      try {
        batch.insert(
          tableName,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        AppLogger.error(
          'upsert failed for $tableName record: $row; attempting update',
        );
      }
    }
    await batch.commit(noResult: true);
  }

  /// Deletes all data from all tables in the SQLite database.
  Future<void> clearAllData() async {
    await initialize();
    final batch = _db!.batch();
    batch.delete('staff');
    batch.delete('customer');
    batch.delete('task');
    batch.delete('notifications');
    batch.delete('task_time_logs');
    await batch.commit(noResult: true);
  }

  /// Deletes a row from the specified table by its primary key value.
  Future<void> deleteRowByPk(
    String tableName,
    String pkName,
    dynamic pkValue,
  ) async {
    await initialize();
    try {
      await _db!.delete(tableName, where: '$pkName = ?', whereArgs: [pkValue]);
      AppLogger.info('deleted $tableName row: $pkName=$pkValue');
    } catch (e) {
      AppLogger.error('failed to delete $tableName $pkName=$pkValue: $e');
    }
  }

  /// Pushes local changes for the given staffId to Supabase, including tasks, staff, and notifications.
  Future<void> pushToSupabase(String staffId) async {
    AppLogger.info('Pushing local changes to Supabase for staff $staffId');
    AppLogger.info('Pushing [tasks] to Supabase');
    final taskData = await TaskRepository().getAllTasks();
    for (final task in taskData) {
      try {
        await TaskService().updateTaskStatus(task.taskId, task.status);
        List<String> uploadedImagePaths = await TaskService()
            .uploadImageToBucket(task.taskId, task.uploadImagePath);
        await TaskService().updateUploadImagePath(
          task.taskId,
          uploadedImagePaths,
        );
        await TaskService().uploadSignatureToBucket(
          task.taskId,
          task.signaturePath!,
        );
        await TaskService().clearLocalCacheByTaskId(task.taskId);
        AppLogger.info('Pushed [tasks] to Supabase');
      } catch (e) {
        AppLogger.error('Failed to push [tasks] for task ${task.taskId}: $e');
      }
    }
    AppLogger.info('Pushing [staff] to Supabase');
    final staffData = await StaffRepository().getStaffById(staffId);
    try {
      await StaffService().updateStaff(staffData);
      AppLogger.info('Pushed [staff] to Supabase');
    } catch (e) {
      AppLogger.error('Failed to push [staff] for staff $staffId: $e');
    }
    AppLogger.info('Pushing [notifications] to Supabase');
    final notificationData = await NotificationRepository()
        .getAllNotifications();
    await NotificationService().batchInsertNotification(notificationData);
    AppLogger.info('Pushed [notifications] to Supabase');
  }
}
