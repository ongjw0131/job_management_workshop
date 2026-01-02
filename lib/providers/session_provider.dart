/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-16 21:10:07
/// @modify date 2025-09-16 21:10:07
/// @desc [SessionProvider: Manages user session state, authentication, and synchronization between Supabase and local SQLite database.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/repositories/session_repository.dart';
import 'package:job_management_workshop/repositories/staff_repository.dart';
import 'package:job_management_workshop/services/sqlite_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionProvider extends ChangeNotifier {
  final SQLiteService _sqliteService = SQLiteService();
  final StaffRepository _staffRepository = StaffRepository();

  Staff? _staff;

  bool _isLoading = false;

  Staff? get staff => _staff;

  bool get isLoading => _isLoading;

  bool get isLoggedIn => _staff != null;

  String? get staffId => _staff?.staffId;

  String? get staffName =>
      _staff != null ? '${_staff!.firstName} ${_staff!.lastName}' : null;

  String? get firstName => _staff?.firstName;

  String? get lastName => _staff?.lastName;

  final SessionRepository _sessionRepo;

  SessionProvider({SessionRepository? sessionRepository})
    : _sessionRepo = sessionRepository ?? SessionRepository();

  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing session provider');
      final restored = await _sessionRepo.restoreSession();
      if (restored != null) {
        _staff = restored;
        AppLogger.info('Session restored for staff ID: ${_staff?.staffId}');
        notifyListeners();
      } else {
        AppLogger.info('No valid stored session found');
      }
    } catch (e) {
      AppLogger.error('Error: $e');
    }
    AppLogger.info('Staff authentication provider initialized');
  }

  Future<bool> signInWithStaffCredentials(
    String staffId,
    String password, {
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final ok = await _sessionRepo.signInOnline(staffId, password);
      if (ok) {
        // refresh _staff from local sqlite for provider state
        try {
          _staff = await _staffRepository.getStaffById(staffId);
        } catch (_) {
          _staff = null;
        }
      }
      return ok;
    } catch (e) {
      AppLogger.error('Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the in-memory staff record from local SQLite and notify listeners.
  /// Useful after an external sync updates the local DB (e.g., realtime or full pull).
  Future<void> refreshStaffFromLocal() async {
    final id = staffId;
    if (id == null) return;
    try {
      final local = await _staffRepository.getStaffById(id);
      _staff = local;
      AppLogger.info('Staff refreshed from local DB');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error: $e');
    }
  }

  // password hashing is handled by the repository

  bool _isSupabaseInitialized() {
    try {
      Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Public helper to check whether Supabase client appears available.
  bool isSupabaseAvailable() {
    return _isSupabaseInitialized();
  }

  /// Attempts to sign in using local SQLite data (offline mode).
  /// Returns true on success.
  Future<bool> signInOffline(String staffId, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      final ok = await _sessionRepo.signInOffline(staffId, password);
      if (ok) {
        try {
          _staff = await _staffRepository.getStaffById(staffId);
        } catch (_) {
          _staff = null;
        }
        AppLogger.info('Offline sign-in successful for staffId: $staffId');
        notifyListeners();
      }
      return ok;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _sessionRepo.logout();
      await _sqliteService.clearAllData();
      _staff = null;
      AppLogger.info(
        'Staff logout completed successfully, all local SQLite data cleared',
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error: $e');
      try {
        await _sessionRepo.logout();
        await _sqliteService.clearAllData();
      } catch (storageError) {
        AppLogger.error(
          'Error clearing stored session or SQLite data: $storageError',
        );
      }
      _staff = null;
      notifyListeners();
    }
  }
}
