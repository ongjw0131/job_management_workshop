/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21
/// @modify date 2025-09-21
/// @desc [TaskPartsRequirementService: Service to handle task parts requirements operations]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/task_parts_requirement.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class TaskPartsRequirementService {
  static const String _tableName = 'task_parts_requirements';
  static const Uuid _uuid = Uuid();

  /// Get all parts requirements for a specific task
  Future<List<TaskPartsRequirement>> getTaskPartsRequirementsByTaskId(
    int taskId,
  ) async {
    try {
      AppLogger.info('Fetching parts requirements for task ID: $taskId');
      final queryBuilder = await SupabaseService.from(_tableName);
      final response = await queryBuilder
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      final requirements = (response as List)
          .map((json) => TaskPartsRequirement.fromJson(json))
          .toList();

      AppLogger.info(
        'Found ${requirements.length} parts requirements for task $taskId',
      );
      return requirements;
    } catch (e) {
      AppLogger.error('Error fetching task parts requirements: $e');
      return [];
    }
  }

  /// Add a new parts requirement to a task
  Future<bool> addTaskPartsRequirement({
    required int taskId,
    required String partId,
    required String barcode,
    required String partName,
    required int requiredQuantity,
    String? notes,
  }) async {
    try {
      AppLogger.info(
        'Adding parts requirement for task $taskId: $partName (qty: $requiredQuantity)',
      );

      final requirement = TaskPartsRequirement(
        requirementId: _uuid.v4(),
        taskId: taskId,
        partId: partId,
        barcode: barcode,
        partName: partName,
        requiredQuantity: requiredQuantity,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder.insert(requirement.toJson());

      AppLogger.info('Successfully added parts requirement');
      return true;
    } catch (e) {
      AppLogger.error('Error adding task parts requirement: $e');
      return false;
    }
  }

  /// Update parts requirement with verification data
  Future<bool> updatePartsRequirementVerification({
    required String requirementId,
    required int verifiedQuantity,
    bool? isVerified,
    String? notes,
  }) async {
    try {
      AppLogger.info(
        'Updating parts requirement verification for ID: $requirementId',
      );

      final updateData = <String, dynamic>{
        'verified_quantity': verifiedQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isVerified != null) {
        updateData['is_verified'] = isVerified;
        if (isVerified) {
          updateData['verified_date'] = DateTime.now().toIso8601String();
        }
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder.update(updateData).eq('requirement_id', requirementId);

      AppLogger.info('Successfully updated parts requirement verification');
      return true;
    } catch (e) {
      AppLogger.error('Error updating parts requirement verification: $e');
      return false;
    }
  }

  /// Get parts requirements that match a specific barcode
  Future<List<TaskPartsRequirement>> getRequirementsByBarcode({
    required int taskId,
    required String barcode,
  }) async {
    try {
      AppLogger.info(
        'Finding requirements for task $taskId with barcode: $barcode',
      );

      final queryBuilder = await SupabaseService.from(_tableName);
      final response = await queryBuilder
          .select()
          .eq('task_id', taskId)
          .eq('barcode', barcode);

      final requirements = (response as List)
          .map((json) => TaskPartsRequirement.fromJson(json))
          .toList();

      AppLogger.info('Found ${requirements.length} matching requirements');
      return requirements;
    } catch (e) {
      AppLogger.error('Error finding requirements by barcode: $e');
      return [];
    }
  }

  /// Check if a barcode is required for the task
  Future<bool> isBarcodeRequiredForTask({
    required int taskId,
    required String barcode,
  }) async {
    try {
      final requirements = await getRequirementsByBarcode(
        taskId: taskId,
        barcode: barcode,
      );
      return requirements.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking if barcode is required: $e');
      return false;
    }
  }

  /// Get verification status for a task (how many parts verified vs total)
  Future<Map<String, dynamic>> getTaskVerificationStatus(int taskId) async {
    try {
      final requirements = await getTaskPartsRequirementsByTaskId(taskId);

      int totalItems = requirements.length;
      int verifiedItems = requirements.where((r) => r.isVerified).length;
      int totalQuantity = requirements.fold(
        0,
        (sum, r) => sum + r.requiredQuantity,
      );
      int verifiedQuantity = requirements.fold(
        0,
        (sum, r) => sum + (r.verifiedQuantity ?? 0),
      );

      double itemProgress = totalItems > 0 ? verifiedItems / totalItems : 1.0;
      double quantityProgress = totalQuantity > 0
          ? verifiedQuantity / totalQuantity
          : 1.0;

      return {
        'totalItems': totalItems,
        'verifiedItems': verifiedItems,
        'totalQuantity': totalQuantity,
        'verifiedQuantity': verifiedQuantity,
        'itemProgress': itemProgress,
        'quantityProgress': quantityProgress,
        'isFullyVerified':
            verifiedItems == totalItems && verifiedQuantity >= totalQuantity,
      };
    } catch (e) {
      AppLogger.error('Error getting task verification status: $e');
      return {
        'totalItems': 0,
        'verifiedItems': 0,
        'totalQuantity': 0,
        'verifiedQuantity': 0,
        'itemProgress': 1.0,
        'quantityProgress': 1.0,
        'isFullyVerified': true,
      };
    }
  }

  /// Remove a parts requirement
  Future<bool> removePartsRequirement(String requirementId) async {
    try {
      AppLogger.info('Removing parts requirement: $requirementId');

      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder.delete().eq('requirement_id', requirementId);

      AppLogger.info('Successfully removed parts requirement');
      return true;
    } catch (e) {
      AppLogger.error('Error removing parts requirement: $e');
      return false;
    }
  }

  /// Bulk add parts requirements from a list
  Future<bool> bulkAddPartsRequirements(
    List<Map<String, dynamic>> requirements,
  ) async {
    try {
      AppLogger.info('Bulk adding ${requirements.length} parts requirements');

      final now = DateTime.now().toIso8601String();
      final formattedRequirements = requirements
          .map(
            (req) => {
              'requirement_id': _uuid.v4(),
              'created_at': now,
              'updated_at': now,
              ...req,
            },
          )
          .toList();

      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder.insert(formattedRequirements);

      AppLogger.info('Successfully bulk added parts requirements');
      return true;
    } catch (e) {
      AppLogger.error('Error bulk adding parts requirements: $e');
      return false;
    }
  }
}
