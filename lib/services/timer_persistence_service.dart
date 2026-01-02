/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 11:24:38
/// @modify date 2025-09-21 11:24:38
/// @desc [TimerPersistenceService: Service for saving and restoring timer states to survive app restarts]
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/helpers/job_timer_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerPersistenceService {
  static const String _keyPrefix = 'job_timer_';

  /// Generate timer key with staff isolation
  static String _generateTimerKey(int taskId, String? staffId) {
    if (staffId != null) {
      return '$_keyPrefix${staffId}_$taskId';
    }
    return '$_keyPrefix$taskId'; // Fallback for backward compatibility
  }

  /// Save timer state to persistent storage
  static Future<void> saveTimerState(int taskId, JobTimer timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _generateTimerKey(taskId, timer.staffId);

      final timerData = {
        'taskId': taskId,
        'staffId': timer.staffId, // Save staff ID for user isolation
        'state': timer.state.name,
        'totalWorkTimeMs': timer.totalWorkTime.inMilliseconds,
        'currentSessionTimeMs': timer.currentSessionTime.inMilliseconds,
        'startTime': timer.startTimeInternal?.toIso8601String(),
        'timeEntries': timer.timeEntries
            .map(
              (entry) => {
                'timestamp': entry.timestamp.toIso8601String(),
                'type': entry.type.name,
                'description': entry.description,
                'durationMs': entry.duration?.inMilliseconds,
              },
            )
            .toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, jsonEncode(timerData));

      if (kDebugMode) {
        AppLogger.info(
          'Saved timer state for task $taskId (staff: ${timer.staffId})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error saving timer state', e);
      }
    }
  }

  /// Load timer state from persistent storage
  static Future<Map<String, dynamic>?> loadTimerState(int taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$taskId';
      final dataString = prefs.getString(key);

      if (dataString == null) return null;

      final data = jsonDecode(dataString) as Map<String, dynamic>;

      if (kDebugMode) {
        AppLogger.info('Loaded timer state for task $taskId');
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading timer state', e);
      }
      return null;
    }
  }

  /// Restore timer from saved state
  static Future<JobTimer?> restoreTimer(int taskId) async {
    try {
      final data = await loadTimerState(taskId);
      if (data == null) return null;

      // Check if saved data is recent (within 24 hours)
      final savedAt = DateTime.parse(data['savedAt'] as String);
      if (DateTime.now().difference(savedAt).inHours > 24) {
        // Clear old timer data
        await clearTimerState(taskId);
        return null;
      }

  final staffId = data['staffId'] as String?; // may be null for legacy
  final timer = JobTimer(taskId: taskId, staffId: staffId);

      // Restore basic state
      final stateName = data['state'] as String;
      final totalWorkTimeMs = data['totalWorkTimeMs'] as int;

      // Set internal timer state
      timer.totalWorkTimeInternal = Duration(milliseconds: totalWorkTimeMs);

      // Restore timestamps
      if (data['startTime'] != null) {
        timer.startTimeInternal = DateTime.parse(data['startTime'] as String);
      }

      // Restore time entries
      final entriesData = data['timeEntries'] as List<dynamic>;
      timer.clearTimeEntriesInternal();
      for (final entryData in entriesData) {
        final entry = TimeEntry(
          timestamp: DateTime.parse(entryData['timestamp'] as String),
          type: TimeEntryType.values.firstWhere(
            (type) => type.name == entryData['type'],
          ),
          description: entryData['description'] as String,
          duration: entryData['durationMs'] != null
              ? Duration(milliseconds: entryData['durationMs'] as int)
              : null,
        );
        timer.addTimeEntryInternal(entry);
      }

      // Restore state
      final state = TimerState.values.firstWhere(
        (state) => state.name == stateName,
        orElse: () => TimerState.stopped,
      );
      timer.stateInternal = state;

      // If state was running, resume ticker to continue updates
      if (timer.state == TimerState.running) {
        timer.resumeTickerIfNeeded();
      }

      if (kDebugMode) {
        AppLogger.info('Restored timer for task $taskId with state: $stateName (staff: $staffId)');
      }

      return timer;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error restoring timer', e);
      }
      return null;
    }
  }

  /// Clear timer state for a specific task
  static Future<void> clearTimerState(int taskId, [String? staffId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear both staff-specific and old format keys
      if (staffId != null) {
        final staffKey = _generateTimerKey(taskId, staffId);
        await prefs.remove(staffKey);
      }

      // Also clear old format key for backward compatibility
      final oldKey = '$_keyPrefix$taskId';
      await prefs.remove(oldKey);

      if (kDebugMode) {
        AppLogger.info(
          'Cleared timer state for task $taskId (staff: $staffId)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error clearing timer state', e);
      }
    }
  }

  /// Clear all timer states for a specific staff member
  static Future<void> clearAllTimerStatesForStaff(String staffId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final timerKeys = keys.where((key) => key.startsWith(_keyPrefix));

      int clearedCount = 0;
      for (final key in timerKeys) {
        try {
          // Check if this timer belongs to the specified staff
          final dataString = prefs.getString(key);
          if (dataString != null) {
            final data = jsonDecode(dataString) as Map<String, dynamic>;
            final savedStaffId = data['staffId'] as String?;

            if (savedStaffId == staffId || key.contains('${staffId}_')) {
              await prefs.remove(key);
              clearedCount++;
            }
          }
        } catch (e) {
          // If we can't parse the data, check if the key contains the staff ID
          if (key.contains('${staffId}_')) {
            await prefs.remove(key);
            clearedCount++;
          }
        }
      }

      if (kDebugMode) {
        AppLogger.info(
          'Cleared $clearedCount timer states for staff: $staffId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error clearing timer states for staff $staffId', e);
      }
    }
  }

  /// Get all active timers (running or paused) for a specific staff member
  static Future<Map<int, Map<String, dynamic>>> getAllActiveTimers([
    String? currentStaffId,
  ]) async {
    final activeTimers = <int, Map<String, dynamic>>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final timerKeys = keys.where((key) => key.startsWith(_keyPrefix));

      for (final key in timerKeys) {
        try {
          final dataString = prefs.getString(key);
          if (dataString == null) continue;

          final data = jsonDecode(dataString) as Map<String, dynamic>;
          final savedStaffId = data['staffId'] as String?;
          final taskId = data['taskId'] as int;

          // Filter by staff ID if provided
          if (currentStaffId != null && savedStaffId != currentStaffId) {
            continue;
          }

          // Check if saved data is recent (within 24 hours)
          final savedAt = DateTime.parse(data['savedAt'] as String);
          if (DateTime.now().difference(savedAt).inHours > 24) {
            // Remove old timer data
            await prefs.remove(key);
            continue;
          }

          final timer = await restoreTimer(taskId);
          if (timer != null && (timer.isRunning || timer.isPaused)) {
            activeTimers[taskId] = {
              'timer': timer,
              'task': null, // Task data would need to be loaded separately
              'taskId': taskId,
              'staffId': savedStaffId,
            };
          }
        } catch (e) {
          // Skip invalid timer data
          if (kDebugMode) {
            AppLogger.warning('Skipping invalid timer data for key: $key');
          }
        }
      }

      if (kDebugMode) {
        AppLogger.info(
          'Found ${activeTimers.length} active timers for staff: $currentStaffId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error getting active timers', e);
      }
    }

    return activeTimers;
  }
}
