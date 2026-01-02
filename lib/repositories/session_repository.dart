/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-18 15:27:40
/// @modify date 2025-09-18 15:27:40
/// @desc [SessionRepository: Handles user session management, including sign-in, sign-out, and session restoration by interacting with both Supabase and local SQLite storage.]
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/repositories/staff_repository.dart';
import 'package:job_management_workshop/services/session_service.dart';
import 'package:job_management_workshop/services/sqlite_service.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final SQLiteService _sqLiteService = SQLiteService();
  final StaffRepository _staffRepository = StaffRepository();
  static const String _tableName = 'staff';

  SessionRepository();

  Future<Staff?> restoreSession() async {
    final stored = await SessionStorage.getStoredSession();
    if (stored == null) return null;
    final staffId = stored['staff_id'];
    if (staffId == null) return null;
    try {
      final local = await _staffRepository.getStaffById(staffId);
      _refreshFromSupabaseAndSync(staffId);
      return local;
    } catch (e) {
      try {
        final queryBuilder = await SupabaseService.from(_tableName);
        final response = await queryBuilder
            .select('*')
            .eq('staff_id', staffId)
            .maybeSingle();
        if (response != null) {
          final staff = Staff.fromJson(response);
          try {
            await _staffRepository.insertStaff(staff);
          } catch (_) {}
          return staff;
        }
        return null;
      } catch (e) {
        return null;
      }
    }
  }

  void _refreshFromSupabaseAndSync(String staffId) async {
    try {
      AppLogger.info('Refreshing staff data for $staffId from Supabase');
      if (!_isSupabaseInitialized()) return;
      final queryBuilder = await SupabaseService.from(_tableName);
      final response = await queryBuilder
          .select('*')
          .eq('staff_id', staffId)
          .maybeSingle();
      if (response == null) return;
      final staff = Staff.fromJson(response);
      await _staffRepository.insertStaff(staff);
    } catch (e) {
      AppLogger.error('Error refreshing staff data for $staffId: $e');
    }
  }

  Future<bool> signInOnline(String staffId, String password) async {
    if (!_isSupabaseInitialized()) return false;
    final queryBuilder = await SupabaseService.from(_tableName);
    final response = await queryBuilder
        .select('*')
        .eq('staff_id', staffId)
        .maybeSingle();
    if (response == null) return false;
    final hashed = _hash(password);
    if (response['password'] != hashed) return false;
    final staff = Staff.fromJson(response);
    await _sqLiteService.clearAllData();
    await SessionStorage.storeSession(staffId: staff.staffId);
    try {
      await _staffRepository.insertStaff(staff);
      await _sqLiteService.fetchFromSupabase(staff.staffId);
    } catch (e) {
      AppLogger.error('Error during sign-in data sync: $e');
    }
    return true;
  }

  Future<bool> signInOffline(String staffId, String password) async {
    final hashed = _hash(password);
    try {
      final local = await _staffRepository.getStaffById(staffId);
      if (local.password != hashed) return false;
      await SessionStorage.storeSession(staffId: local.staffId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await SessionStorage.clearSession();
    await _sqLiteService.clearAllData();
  }

  String _hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isSupabaseInitialized() {
    try {
      final _ = Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }
}
