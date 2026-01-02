/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 14:32:52
/// @modify date 2025-09-21 14:32:52
/// @desc [MainController: Handles staff login and session management.]
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/repositories/staff_repository.dart';
import 'package:job_management_workshop/services/session_service.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

class LoginResult {
  final bool success;
  final String? error;

  LoginResult({required this.success, this.error});
}

class MainController {
  final StaffRepository _staffRepository = StaffRepository();

  Future<LoginResult> loginStaff(String staffId, String password) async {
    if (staffId.trim().isEmpty || password.isEmpty) {
      return LoginResult(
        success: false,
        error: 'Please enter both Staff ID and password.',
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(staffId.trim())) {
      return LoginResult(
        success: false,
        error: 'Staff ID should contain only numbers.',
      );
    }
    try {
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      try {
        final queryBuilder = await SupabaseService.from('staff');
        final staffData = await queryBuilder
            .select('staff_id, password, first_name, last_name')
            .eq('staff_id', staffId.trim())
            .single();
        Staff response = Staff.fromJson(staffData);
        if (response.password != hashedPassword) {
          return LoginResult(
            success: false,
            error: 'Invalid Staff ID or password. Please try again.',
          );
        }
        await SessionStorage.storeSession(staffId: response.staffId);
        AppLogger.info('Login successful for staff ID: ${response.staffId}');
        return LoginResult(success: true);
      } catch (e) {
        AppLogger.error('Supabase lookup failed in loginStaff: $e');
        try {
          final localStaff = await _staffRepository.getStaffById(
            staffId.trim(),
          );
          if (localStaff.password != hashedPassword) {
            return LoginResult(
              success: false,
              error: 'Invalid Staff ID or password (offline)',
            );
          }
          await SessionStorage.storeSession(staffId: localStaff.staffId);
          AppLogger.info(
            'Offline login successful for staff ID: ${localStaff.staffId}',
          );
          return LoginResult(success: true);
        } catch (localErr) {
          AppLogger.error('Offline login attempt failed: $localErr');
          return LoginResult(
            success: false,
            error: 'Login failed. Please check your connection and try again.',
          );
        }
      }
    } catch (e) {
      return LoginResult(
        success: false,
        error: 'Login failed. Please try again.',
      );
    }
  }
}
