/// @author [Ong Jun Wei, Chong Jun Xiang]
/// @email [ongjw-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-13
/// @modify date 2025-09-17
/// @desc [NotificationService: Service for managing task-related notifications]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/notifications.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

/// Service for managing task-related notifications
class NotificationService {
  static const String _tableName = 'notifications';

  Future<List<AppNotification>> getAllNotificationsByStaffId(
    String staffId,
  ) async {
    try {
      AppLogger.info('Fetching notifications for staff ID: $staffId');
      final queryBuilder = await SupabaseService.from(_tableName);
      final response = await queryBuilder
          .select()
          .eq('staff_id', staffId)
          .order('created_at', ascending: false);
      final notificationList = (response as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
      return notificationList;
    } catch (e) {
      AppLogger.error('Error fetching notifications: $e');
      return [];
    }
  }

  Future<bool> batchInsertNotification(
    List<AppNotification> notifications,
  ) async {
    try {
      AppLogger.info('Batch upserting ${notifications.length} notifications');
      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder.upsert(
        notifications.map((e) => e.toJson()).toList(),
        onConflict: 'staff_id,task_id,title', // must match DB unique constraint
      );
      return true;
    } catch (e) {
      AppLogger.error('Error batch upserting notifications (Supabase): $e');
      return false;
    }
  }
}
