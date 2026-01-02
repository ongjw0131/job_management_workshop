/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-13
/// @modify date 2025-09-13
/// @desc [BarcodeController: Controller for managing barcode scanning and parts tracking operations]

library;

import 'package:job_management_workshop/models/vehicle_part.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

/// Result wrapper for barcode operations
class BarcodeResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const BarcodeResult({required this.success, this.data, this.error});

  factory BarcodeResult.success(T data) {
    return BarcodeResult(success: true, data: data);
  }

  factory BarcodeResult.failure(String error) {
    return BarcodeResult(success: false, error: error);
  }
}

/// Controller for barcode scanning and parts management
class BarcodeController {
  /// Get all vehicle parts with optional filtering
  Future<BarcodeResult<List<VehiclePart>>> getAllParts({
    String? category,
    String? searchQuery,
  }) async {
    try {
      final queryBuilder = await SupabaseService.from('vehicle_parts');
      var query = queryBuilder.select();

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'part_name.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('part_name');
      final parts = (response as List)
          .map((json) => VehiclePart.fromJson(json))
          .toList();

      return BarcodeResult.success(parts);
    } catch (e) {
      return BarcodeResult.failure('Error fetching parts: $e');
    }
  }

  /// Get parts usage history for a task
  Future<BarcodeResult<List<Map<String, dynamic>>>> getTaskPartsUsage(
    int taskId,
  ) async {
    try {
      final queryBuilder = await SupabaseService.from(
        'task_parts_requirements',
      );
      final response = await queryBuilder
          .select('''
            *,
            vehicle_parts(part_name, part_number, category, unit_price),
            staff(first_name, last_name)
          ''')
          .eq('task_id', taskId)
          .order('usage_date', ascending: false);

      return BarcodeResult.success(response);
    } catch (e) {
      return BarcodeResult.failure('Error fetching parts usage: $e');
    }
  }

  /// Get available categories
  Future<BarcodeResult<List<String>>> getPartCategories() async {
    try {
      final queryBuilder = await SupabaseService.from('vehicle_parts');
      final response = await queryBuilder
          .select('category')
          .not('category', 'is', null);

      final categories = (response as List)
          .map((item) => item['category'] as String)
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();

      categories.sort();
      return BarcodeResult.success(categories);
    } catch (e) {
      return BarcodeResult.failure('Error fetching categories: $e');
    }
  }
}
