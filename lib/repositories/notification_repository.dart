/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-18 20:30:00
/// @modify date 2025-09-18 20:30:00
/// @desc [NotificationRepository: Repository to handle local database operations for notifications using SQLite.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/notifications.dart';
import 'package:job_management_workshop/services/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class NotificationRepository {
  static const String _tableName = 'notifications';

  /// Batch insert or upsert notifications in SQLite
  Future<bool> batchInsertNotificationList(
    Batch batch,
    List<AppNotification> notifications,
  ) async {
    if (notifications.isEmpty) return true;
    try {
      AppLogger.info(
        'Batch inserting/upserting ${notifications.length} notifications',
      );
      final db = await DatabaseProvider.getDatabase();
      final batch = db.batch();
      // if exists, replace; else insert
      for (var notification in notifications) {
        batch.insert(
          _tableName,
          notification.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      AppLogger.error('Error batch inserting/upserting notifications: $e', e);
      return false;
    }
  }

  Future<List<AppNotification>> getAllNotifications() async {
    try {
      AppLogger.info('Fetching all notifications from local database');
      final db = await DatabaseProvider.getDatabase();
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return AppNotification.fromJson(maps[i]);
      });
    } catch (e) {
      AppLogger.error('Error fetching notifications: $e', e);
      return [];
    }
  }

  Future<List<AppNotification>> getAllNotificationsByStaffId(
    String staffId,
  ) async {
    try {
      AppLogger.info('Fetching notifications for staff ID: $staffId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'staff_id = ?',
        whereArgs: [staffId],
        orderBy: 'created_at DESC',
      );
      return maps.map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Error fetching notifications: $e');
      return [];
    }
  }

  Future<bool> insertNotification(AppNotification notification) async {
    try {
      AppLogger.info('Inserting notification: ${notification.toJson()}');
      final db = await DatabaseProvider.getDatabase();
      await db.insert(
        _tableName,
        notification.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      AppLogger.error('Error inserting notification: $e', e);
      return false;
    }
  }

  /// Creates a notification when a task is accepted by a staff member (SQLite version)
  Future<void> createTaskAcceptedNotification({
    required String staffId,
    required int taskId, // kept for description
    required String taskTitle,
    required String? orderId, // kept for description
    String? deadline,
  }) async {
    try {
      AppLogger.info(
        'Creating task accepted notification (SQLite) for staff ID: $staffId, task ID: $taskId',
      );
      final notification = AppNotification(
        id: 0,
        // SQLite will auto-increment, value ignored on insert
        staffId: staffId,
        taskId: taskId,
        title: 'Task Accepted',
        subtitle: 'Task: $taskTitle',
        description:
            'You have accepted the task${orderId != null ? ' for order $orderId' : ''}. ${deadline != null ? 'Deadline: $deadline' : 'Click to view details and start working.'}',
        iconType: 'thumb_up',
        iconColor: 'orange',
        isRead: false,
        createdAt: DateTime.now(),
      );
      await insertNotification(notification);
    } catch (e) {
      AppLogger.error(
        'Error creating task accepted notification (SQLite): $e',
        e,
      );
    }
  }

  /// Creates a notification when a task is accepted by a staff member (SQLite version)
  Future<void> createTaskCompletedNotification({
    required String staffId,
    required int taskId, // kept for description
    required String taskTitle,
    required String? orderId, // kept for description
    String? deadline,
  }) async {
    try {
      AppLogger.info(
        'Creating task accepted notification (SQLite) for staff ID: $staffId, task ID: $taskId',
      );
      final notification = AppNotification(
        id: 0,
        // SQLite will auto-increment, value ignored on insert
        staffId: staffId,
        taskId: taskId,
        title: 'Task Completed',
        subtitle: 'Task: $taskTitle',
        description:
            'You have accepted the task${orderId != null ? ' for order $orderId' : ''}. ${deadline != null ? 'Deadline: $deadline' : 'Click to view details and start working.'}',
        iconType: 'check_circle',
        iconColor: 'green',
        isRead: false,
        createdAt: DateTime.now(),
      );
      await insertNotification(notification);
    } catch (e) {
      AppLogger.error(
        'Error creating task accepted notification (SQLite): $e',
        e,
      );
    }
  }

  /// Marks a notification as read in the local SQLite database
  Future<void> markAsRead(int notificationId) async {
    try {
      AppLogger.info('Marking notification as read: id=$notificationId');
      final db = await DatabaseProvider.getDatabase();
      await db.update(
        _tableName,
        {'is_read': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e', e);
    }
  }

  /// Gets unread notification count for a staff member (SQLite version)
  Future<int> getUnreadCount(String staffId) async {
    try {
      AppLogger.info(
        'Fetching unread notification count for staff ID: $staffId',
      );
      final db = await DatabaseProvider.getDatabase();
      final result = await db.query(
        _tableName,
        columns: ['COUNT(*) as count'],
        where: 'staff_id = ? AND is_read = 0',
        whereArgs: [staffId],
      );
      return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
    } catch (e) {
      AppLogger.error('Error fetching unread notification count: $e', e);
      return 0;
    }
  }
}
