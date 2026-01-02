/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 00:29:24
/// @modify date 2025-09-17 00:29:24
/// @desc [StaffService: Service to handle staff-related operations using Supabase as the backend.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

class StaffService {
  static const String _tableName = 'staff';

  Future<Staff> getStaffById(String staffId) async {
    try {
      AppLogger.info('Fetching staff with id $staffId from Supabase');
      final queryBuilder = await SupabaseService.from(_tableName);
      final response = await queryBuilder
          .select()
          .eq('staff_id', staffId)
          .single();
      return Staff.fromJson(response);
    } catch (e) {
      AppLogger.error('Error fetching staff by id: $e', e);
      rethrow;
    }
  }

  Future<bool> updateStaff(Staff staff) async {
    try {
      AppLogger.info('Updating staff with id ${staff.staffId}');
      // only update first name, last name, phone number, address
      final updateData = {
        'first_name': staff.firstName,
        'last_name': staff.lastName,
        'phone_number': staff.phoneNumber,
        'address': staff.address,
      };
      final queryBuilder = await SupabaseService.from(_tableName);
      await queryBuilder.update(updateData).eq('staff_id', staff.staffId);
      AppLogger.info('Updated staff with id ${staff.staffId}');
      return true;
    } catch (e) {
      AppLogger.error('Error updating staff: $e', e);
      return false;
    }
  }
}
