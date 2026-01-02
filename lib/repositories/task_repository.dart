/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-18 02:03:07
/// @modify date 2025-09-18 02:03:07
/// @desc [TaskRepository: Handles all task-related data operations using SQLite.]
library;

import 'dart:io';

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/helpers/date_helper.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/repositories/notification_repository.dart';
import 'package:job_management_workshop/services/database_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqlite_api.dart';

class TaskRepository {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  static const String _tableName = 'task';

  /// Deletes local tasks for a staff that are not present on the server.
  Future<int> deleteTasksNotOnServer({
    required String staffId,
    required Set<int> serverTaskIds,
    Database? db,
  }) async {
    try {
      AppLogger.info(
        'Deleting local tasks not present on server for staff $staffId',
      );
      final database = db ?? await DatabaseProvider.getDatabase();
      final localMaps = await database.query(
        _tableName,
        columns: ['task_id'],
        where: 'staff_id = ?',
        whereArgs: [staffId],
      );
      final toDelete = <int>[];
      for (final m in localMaps) {
        try {
          final dynamic raw = m['task_id'];
          if (raw == null) continue;
          final localId = raw is int ? raw : int.tryParse(raw.toString());
          if (localId == null) continue;
          if (!serverTaskIds.contains(localId)) {
            toDelete.add(localId);
          }
        } catch (_) {}
      }
      if (toDelete.isNotEmpty) {
        final batchDel = database.batch();
        for (final id in toDelete) {
          batchDel.delete(_tableName, where: 'task_id = ?', whereArgs: [id]);
        }
        await batchDel.commit(noResult: true);
        AppLogger.info(
          'Deleted ${toDelete.length} local task(s) not present on server for staff $staffId',
        );
      }
      return toDelete.length;
    } catch (e) {
      AppLogger.error(
        'Error deleting local tasks not present on server: $e',
        e,
      );
      return 0;
    }
  }

  Future<Directory> createCacheDirForTask(int taskId) async {
    final tempDir = await getTemporaryDirectory();
    final dirPath = Directory(
      [
        tempDir.path,
        Task.cacheFolderName,
        'task_$taskId',
      ].join(Platform.pathSeparator),
    );
    if (!await dirPath.exists()) {
      await dirPath.create(recursive: true);
    }
    return dirPath;
  }

  Future<List<Task>> getAllTasks() async {
    try {
      AppLogger.info('Fetching all tasks');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(_tableName);
      return maps.map((map) {
        final mutable = Map<String, dynamic>.from(map);
        mutable['repair_image_path'] =
            (map['repair_image_path'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        mutable['upload_image_path'] =
            (map['upload_image_path'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        return Task.fromJson(mutable);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching all tasks: $e', e);
      return [];
    }
  }

  Future<Task> getTaskById(int taskId) async {
    try {
      AppLogger.info('Fetching task with id $taskId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      if (maps.isEmpty) {
        throw Exception('Task with id $taskId not found');
      }
      final mutable = Map<String, dynamic>.from(maps.first);
      mutable['repair_image_path'] =
          (maps.first['repair_image_path'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];
      mutable['upload_image_path'] =
          (maps.first['upload_image_path'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];
      return Task.fromJson(mutable);
    } catch (e) {
      AppLogger.error('Error fetching task by id: $e', e);
      rethrow;
    }
  }

  Future<List<Task>> getAssignedTask(String staffId) async {
    try {
      AppLogger.info('Fetching assigned tasks for staff $staffId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'staff_id = ? AND (status = ? OR status = ?)',
        whereArgs: [
          staffId,
          TaskStatus.assigned.value,
          TaskStatus.accepted.value,
        ],
      );
      return maps.map((map) {
        final mutable = Map<String, dynamic>.from(map);
        mutable['repair_image_path'] =
            (map['repair_image_path'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        mutable['upload_image_path'] =
            (map['upload_image_path'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        return Task.fromJson(mutable);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching assigned tasks: $e', e);
      return [];
    }
  }

  Future<List<Task>> getCompletedTask({
    required String staffId,
    bool ascending = true,
  }) async {
    try {
      AppLogger.info('Fetching completed tasks for staff $staffId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'staff_id = ? AND status = ?',
        whereArgs: [staffId, TaskStatus.completed.value],
      );
      return maps.map((map) {
        final mutable = Map<String, dynamic>.from(map);
        mutable['repair_image_path'] =
            (map['repair_image_path'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        mutable['upload_image_path'] =
            (map['upload_image_path'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        return Task.fromJson(mutable);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching completed tasks: $e', e);
      return [];
    }
  }

  Future<bool> insertTask(Task task) async {
    try {
      AppLogger.info('Inserting task with id ${task.taskId}');
      final db = await DatabaseProvider.getDatabase();
      await db.insert(
        _tableName,
        task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      AppLogger.error('Error inserting task: $e', e);
      return false;
    }
  }

  Future<bool> batchInsertTaskList(Batch batch, List<Task> taskList) async {
    try {
      AppLogger.info('Batch inserting tasks');
      for (final task in taskList) {
        batch.insert(
          _tableName,
          task.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Error in batch inserting tasks: $e', e);
      return false;
    }
  }

  Future<bool> updateTaskStatus(int taskId, TaskStatus newStatus) async {
    try {
      //  Retrieve staffId for notification
      final task = await getTaskById(taskId);
      final staffId = task.staffId;
      final orderId = task.orderId;
      final deadline = task.deadline;
      AppLogger.info('Updating task $taskId to status ${newStatus.value}');
      final db = await DatabaseProvider.getDatabase();
      await db.transaction((txn) async {
        await txn.update(
          _tableName,
          {'status': newStatus.value},
          where: 'task_id = ?',
          whereArgs: [taskId],
        );
      });
      // insert notification based on new status
      if (newStatus == TaskStatus.completed) {
        _notificationRepository.createTaskCompletedNotification(
          staffId: staffId,
          taskId: taskId,
          taskTitle: task.title,
          orderId: orderId,
          deadline: DateHelper.toDateTimeString(deadline),
        );
      } else if (newStatus == TaskStatus.accepted) {
        _notificationRepository.createTaskAcceptedNotification(
          staffId: staffId,
          taskId: taskId,
          taskTitle: task.title,
          orderId: orderId,
          deadline: DateHelper.toDateTimeString(deadline),
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Error updating task status: $e', e);
      return false;
    }
  }

  Future<bool> updateUploadImagePath(int taskId, List<String> paths) async {
    try {
      AppLogger.info('Updating upload image paths for task $taskId');
      final db = await DatabaseProvider.getDatabase();
      final pathString = paths.join(',');
      return await db.transaction((txn) async {
        await txn.update(
          _tableName,
          {'upload_image_path': pathString},
          where: 'task_id = ?',
          whereArgs: [taskId],
        );
        return true;
      });
    } catch (e) {
      AppLogger.error('Error updating upload image paths: $e', e);
      return false;
    }
  }

  Future<bool> updateSignaturePath(int taskId, String? path) async {
    try {
      AppLogger.info('Updating signature path for task $taskId to: $path');
      final db = await DatabaseProvider.getDatabase();
      return await db.transaction((txn) async {
        await txn.update(
          _tableName,
          {'signature_path': path},
          where: 'task_id = ?',
          whereArgs: [taskId],
        );
        return true;
      });
    } catch (e) {
      AppLogger.error('Error updating signature path: $e', e);
      return false;
    }
  }
}
