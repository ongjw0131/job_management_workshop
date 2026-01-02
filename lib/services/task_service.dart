/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 00:29:24
/// @modify date 2025-09-17 00:29:24
/// @desc [TaskService: Service to handle task-related operations using Supabase as the backend.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/repositories/task_repository.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

class TaskService {
  final TaskRepository _taskRepository = TaskRepository();
  static const String _tableName = 'task';

  Future<List<Task>> getAllTaskByStaffId(String staffId) async {
    try {
      AppLogger.info('Fetching all tasks for staff ID: $staffId');
      final queryBuilder = await SupabaseService.from(_tableName);
      final taskData = await queryBuilder
          .select('*,repair_image_path')
          .eq('staff_id', staffId)
          .order('deadline', ascending: true);
      List<Task> response = taskData
          .map<Task>((json) => Task.fromJson(json))
          .toList();
      return response;
    } catch (e) {
      AppLogger.error('Error fetching tasks for staff ID $staffId: $e');
      return [];
    }
  }

  Future<bool> updateTaskStatus(int taskId, TaskStatus newStatus) async {
    try {
      AppLogger.info('Updating status for task ID $taskId to $newStatus');
      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder
          .update({'status': newStatus.value})
          .eq('task_id', taskId);
      return true;
    } catch (e) {
      AppLogger.error('Error updating status for task $taskId: $e');
      return false;
    }
  }

  Future<bool> updateUploadImagePath(
    int taskId,
    List<String> uploadImagePaths,
  ) async {
    try {
      AppLogger.info('Updating upload image paths for task ID $taskId');
      final queryBuilder = await SupabaseService.from(_tableName);
      final response = await queryBuilder
          .update({'upload_image_path': uploadImagePaths})
          .eq('task_id', taskId);
      if (response == null) {
        AppLogger.error(
          'No response from Supabase while updating upload image paths for task $taskId',
        );
        return false;
      }
      AppLogger.info(
        'Successfully updated upload image paths for task $taskId: $uploadImagePaths',
      );
      return true;
    } catch (e) {
      AppLogger.error('Error updating upload image paths for task $taskId: $e');
      return false;
    }
  }

  Future<List<String>> uploadImageToBucket(
    int taskId,
    List<String> uploadImagePaths,
  ) async {
    try {
      final renamedUploadImagePaths = <String>[];
      for (final path in uploadImagePaths) {
        AppLogger.info('Uploading image for task $taskId: $path');
        final filePath = await SupabaseService.uploadImageToBucket(
          'ImageBucket',
          path,
        );
        renamedUploadImagePaths.add(filePath);
      }
      AppLogger.info(
        'Successfully uploaded images for task $taskId: $renamedUploadImagePaths',
      );
      return renamedUploadImagePaths;
    } catch (e) {
      AppLogger.error('Error uploading images for task $taskId: $e');
      return [];
    }
  }

  /// Upload a local signature file to Supabase and update both Supabase and local SQLite
  /// Returns the remote storage path on success, or null on failure.
  Future<bool> uploadSignatureToBucket(int taskId, String localFilePath) async {
    try {
      AppLogger.info(
        'Uploading signature for task $taskId from $localFilePath',
      );
      final filePath = await SupabaseService.uploadSignatureToBucket(
        'SignatureBucket',
        localFilePath,
      );
      await updateTaskSignaturePath(taskId, filePath);
      AppLogger.info(
        'Successfully uploaded signature for task $taskId: $filePath',
      );
      return true;
    } catch (e) {
      AppLogger.error('Error uploading signature for task $taskId: $e');
      return false;
    }
  }

  Future<bool> updateTaskSignaturePath(int taskId, String signaturePath) async {
    try {
      AppLogger.info('Updating signature path for task ID $taskId');
      final clientInstance = await SupabaseService.getSafeClient();
      await clientInstance
          .from(_tableName)
          .update({'signature_path': signaturePath})
          .eq('task_id', taskId)
          .select();
      return true;
    } catch (e) {
      AppLogger.error('Error updating signature path for task $taskId: $e');
      return false;
    }
  }

  Future<bool> clearLocalCacheByTaskId(int taskId) async {
    try {
      AppLogger.info('Clearing local cache for task ID $taskId');
      final dir = await _taskRepository.createCacheDirForTask(taskId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      AppLogger.info('Successfully cleared local cache for task ID $taskId');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing local cache for task ID $taskId: $e');
      return false;
    }
  }
}
