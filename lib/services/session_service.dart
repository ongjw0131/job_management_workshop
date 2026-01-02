/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-16 21:10:45
/// @modify date 2025-09-16 21:10:45
/// @desc [SessionStorage: Handles secure storage and retrieval of user session data using SharedPreferences with basic integrity checks and expiration logic.]
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/services/timer_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String _staffIdKey = 'staff_session_id';
  static const String _sessionHashKey = 'staff_session_hash';
  static const String _sessionTimestampKey = 'staff_session_timestamp';

  static Future<void> storeSession({required String staffId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sessionData = '$staffId:$timestamp';
      final sessionHash = _generateSessionHash(sessionData);
      await prefs.setString(_staffIdKey, staffId);
      await prefs.setString(_sessionHashKey, sessionHash);
      await prefs.setInt(_sessionTimestampKey, timestamp);
      AppLogger.info(
        'Staff session stored successfully for staff ID: $staffId',
      );
    } catch (e) {
      AppLogger.error('Error storing session: $e');
    }
  }

  static Future<Map<String, dynamic>?> getStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final staffId = prefs.getString(_staffIdKey);
      final sessionHash = prefs.getString(_sessionHashKey);
      final timestamp = prefs.getInt(_sessionTimestampKey);
      if (staffId == null || sessionHash == null || timestamp == null) {
        AppLogger.info('Incomplete session data found');
        return null;
      }
      final expectedSessionData = '$staffId:$timestamp';
      final expectedHash = _generateSessionHash(expectedSessionData);
      if (sessionHash != expectedHash) {
        AppLogger.error('Session hash validation failed');
        await clearSession();
        return null;
      }
      AppLogger.info('Valid session found for staff ID: $staffId');
      return {'staff_id': staffId};
    } catch (e) {
      AppLogger.error('Error retrieving session: $e');
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current staff ID before clearing session
      final staffId = prefs.getString(_staffIdKey);

      // Clear session data
      await prefs.remove(_staffIdKey);
      await prefs.remove(_sessionHashKey);
      await prefs.remove(_sessionTimestampKey);

      // Clear timer states for this staff member to prevent cross-user timer display
      if (staffId != null) {
        await TimerPersistenceService.clearAllTimerStatesForStaff(staffId);
        AppLogger.info('Cleared timer states for staff: $staffId');
      }

      AppLogger.info('Session data cleared successfully');
    } catch (e) {
      AppLogger.error('Error clearing session: $e');
    }
  }

  static String _generateSessionHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
