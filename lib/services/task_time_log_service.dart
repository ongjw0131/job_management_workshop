/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 00:29:24
/// @modify date 2025-09-17 00:29:24
/// @desc [TaskTimeLogService: Service to handle task time log-related operations using Supabase as the backend.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/task_time_log.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:job_management_workshop/services/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TaskTimeLogService {
  static const String _tableName = 'task_time_logs';

  /// Get time logs for a specific task
  Future<List<TaskTimeLog>> getTaskTimeLogsByTaskId(int taskId) async {
    try {
      AppLogger.info('Fetching task time logs for task id: $taskId');
      final queryBuilder = await SupabaseService.from(_tableName);
      final taskTimeLogsData = await queryBuilder
          .select()
          .eq('task_id', taskId)
          .order('timestamp', ascending: true);
      return (taskTimeLogsData as List)
          .map((data) => TaskTimeLog.fromJson(data))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching task time logs by task id: $e', e);
      rethrow;
    }
  }

  /// Get local (SQLite) time logs for a specific task
  Future<List<TaskTimeLog>> getLocalTaskTimeLogsByTaskId(int taskId) async {
    try {
      AppLogger.info('Fetching LOCAL task time logs for task id: $taskId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'task_id = ? ',
        whereArgs: [taskId],
        orderBy: 'timestamp ASC',
      );
      return maps.map((m) => TaskTimeLog.fromJson(m)).toList();
    } catch (e) {
      AppLogger.error('Error fetching LOCAL task time logs: $e', e);
      return [];
    }
  }

  /// Log a timer action to Supabase (start, pause, resume, complete)
  Future<TaskTimeLog?> logTimerAction({
    required int taskId,
    required String staffId,
    required String action,
    Duration? duration,
  }) async {
    try {
      AppLogger.info(
        'Logging timer action: $action for task: $taskId, staff: $staffId',
      );

      final queryBuilder = await SupabaseService.from(_tableName);
      final logData = {
        'task_id': taskId,
        'staff_id': staffId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add duration if provided
      if (duration != null) {
        logData['duration'] =
            'PT${duration.inHours}H${duration.inMinutes.remainder(60)}M${duration.inSeconds.remainder(60)}S';
      }

      // Insert to remote (Supabase)
      TaskTimeLog? created;
      try {
        final response = await queryBuilder.insert(logData).select().single();
        created = TaskTimeLog.fromJson(response);
        AppLogger.info('Timer action logged to Supabase: $action');
      } catch (e) {
        AppLogger.warning('Failed remote log (will still persist locally): $e');
      }

      // Always persist locally
      try {
        final db = await DatabaseProvider.getDatabase();
        final localData = Map<String, Object?>.from(logData);
        // Duration string already encoded if present
        final id = await db.insert(
          _tableName,
          localData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (created == null) {
          // Build from local insert if remote failed
            created = TaskTimeLog.fromJson({
            ...localData,
            'log_id': id,
          });
        }
        AppLogger.info('Timer action persisted locally: $action (id=$id)');
      } catch (e) {
        AppLogger.error('Failed to persist timer action locally: $e');
      }

      return created;
    } catch (e) {
      AppLogger.error('Error logging timer action: $e', e);
      return null;
    }
  }

  /// Log timer start
  Future<TaskTimeLog?> logTimerStart(int taskId, String staffId) async {
    return await logTimerAction(
      taskId: taskId,
      staffId: staffId,
      action: 'start',
    );
  }

  /// Log timer pause
  Future<TaskTimeLog?> logTimerPause(
    int taskId,
    String staffId,
    Duration workDuration,
  ) async {
    return await logTimerAction(
      taskId: taskId,
      staffId: staffId,
      action: 'pause',
      duration: workDuration,
    );
  }

  /// Log timer resume
  Future<TaskTimeLog?> logTimerResume(int taskId, String staffId) async {
    return await logTimerAction(
      taskId: taskId,
      staffId: staffId,
      action: 'resume',
    );
  }

  /// Log timer complete
  Future<TaskTimeLog?> logTimerComplete(
    int taskId,
    String staffId,
    Duration totalDuration,
  ) async {
    return await logTimerAction(
      taskId: taskId,
      staffId: staffId,
      action: 'complete',
      duration: totalDuration,
    );
  }

  /// Log timer reset - uses 'complete' action with special handling
  /// Note: Database schema only allows 'start', 'pause', 'resume', 'complete'
  /// Reset is logged as 'complete' to track time before reset
  Future<TaskTimeLog?> logTimerReset(
    int taskId,
    String staffId,
    Duration totalDuration,
  ) async {
    try {
      AppLogger.info('Logging timer reset for task: $taskId, staff: $staffId');

      final queryBuilder = await SupabaseService.from(_tableName);
      final logData = {
        'task_id': taskId,
        'staff_id': staffId,
        'action': 'complete',
        // Using 'complete' as reset is not allowed in DB schema
        'timestamp': DateTime.now().toIso8601String(),
        'duration':
            'PT${totalDuration.inHours}H${totalDuration.inMinutes.remainder(60)}M${totalDuration.inSeconds.remainder(60)}S',
      };

      final response = await queryBuilder.insert(logData).select().single();

      AppLogger.info('Timer reset logged successfully');
      return TaskTimeLog.fromJson(response);
    } catch (e) {
      AppLogger.error('Error logging timer reset: $e', e);
      return null;
    }
  }
}
