/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 17:39:04
/// @modify date 2025-09-20 17:39:04
/// @desc [BackgroundSyncService: Handles background synchronization of local SQLite data with Supabase.]
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/helpers/connection_helper.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/services/session_service.dart';
import 'package:job_management_workshop/services/sqlite_service.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:workmanager/workmanager.dart';

/// Entry point for background sync tasks dispatched by Workmanager.
/// Initializes required services and handles periodic or one-off sync logic.
/// This function should not be called directly; it is registered with Workmanager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  const className = 'BackgroundService';
  const callbackMethod = 'callbackDispatcher';
  AppLogger.info('$className.$callbackMethod: START');
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    AppLogger.info(
      '$className.$callbackMethod: Workmanager executeTask START - task=$task, inputData=$inputData',
    );
    AppLogger.info('$className.$callbackMethod: Background task started');
    try {
      AppLogger.info('$className.$callbackMethod: Initializing Supabase...');
      final supabaseInitialized = await SupabaseService.initialize();
      if (!supabaseInitialized) {
        AppLogger.error(
          '$className.$callbackMethod: Failed to initialize Supabase',
        );
        return Future.value(false);
      }
      AppLogger.info('$className.$callbackMethod: Initializing SQLite...');
      await SQLiteService().initialize();
      AppLogger.info(
        '$className.$callbackMethod: Services initialized successfully',
      );
      final now = DateTime.now();
      final bool isEightPm = now.hour == 20;
      ConnectionQuality quality = ConnectionQuality.offline;
      if (isEightPm) {
        AppLogger.info(
          '$className.$callbackMethod: Detected 8pm, running sync for current staff',
        );
        int retryCount = 0;
        const int maxRetries = 3;
        const int baseDelaySeconds = 5;
        while (retryCount < maxRetries) {
          final results = await ConnectionHelper.getCurrentConnectivity();
          quality = ConnectionHelper.mapResultsToQuality(results);
          AppLogger.info(
            '$className.$callbackMethod: Connection check attempt ${retryCount + 1}: $quality',
          );
          if (quality == ConnectionQuality.online) {
            break;
          }
          retryCount++;
          if (retryCount < maxRetries) {
            final backoffSecs = min(
              pow(2, retryCount - 1).toInt() * baseDelaySeconds,
              60,
            );
            AppLogger.info(
              '$className.$callbackMethod: No connection, waiting $backoffSecs seconds before next retry',
            );
            await Future.delayed(Duration(seconds: backoffSecs));
          }
        }
        if (quality != ConnectionQuality.online) {
          AppLogger.error(
            '$className.$callbackMethod: No connection after $maxRetries retries, scheduling next sync for next hour',
          );
          try {
            await BackgroundSyncService.scheduleOneOffSync(
              delay: const Duration(hours: 1),
              inputData: inputData,
            );
          } catch (e) {
            AppLogger.error(
              '$className.$callbackMethod: Failed to schedule one-off sync: $e',
            );
          }
          return Future.value(false);
        }
      } else {
        final results = await ConnectionHelper.getCurrentConnectivity();
        quality = ConnectionHelper.mapResultsToQuality(results);
        AppLogger.info(
          '$className.$callbackMethod: Hourly sync connection quality: $quality',
        );
        if (quality != ConnectionQuality.online) {
          AppLogger.info(
            '$className.$callbackMethod: Hourly sync skipped due to no connection',
          );
          return Future.value(false);
        }
      }
      final session = await SessionStorage.getStoredSession();
      final staffId = session != null ? session['staff_id'] as String? : null;
      if (staffId != null) {
        try {
          AppLogger.info(
            '$className.$callbackMethod: pushing local updates for $staffId',
          );
          await Future.delayed(const Duration(milliseconds: 500));
          AppLogger.info('$className.$callbackMethod: pushToSupabase START');
          await SQLiteService().pushToSupabase(staffId);
          AppLogger.info('$className.$callbackMethod: pushToSupabase END');
          AppLogger.info('$className.$callbackMethod: fetchFromSupabase START');
          await SQLiteService().fetchFromSupabase(staffId);
          AppLogger.info(
            '$className.$callbackMethod: fetchFromSupabase END for staffId=$staffId',
          );
          try {
            await SessionProvider().refreshStaffFromLocal();
          } catch (e) {
            AppLogger.error('failed to refresh session: $e');
          }
        } catch (e) {
          AppLogger.error(
            '$className.$callbackMethod: pushToSupabase error for staffId=$staffId: $e',
          );
          return Future.value(false);
        }
      } else {
        AppLogger.error(
          '$className.$callbackMethod: No valid staff session found, skipping pushToSupabase',
        );
        return Future.value(false);
      }
    } catch (e) {
      AppLogger.error(
        '$className.$callbackMethod: Error in background task: $e',
      );
      return Future.value(false);
    }
    AppLogger.info('$className.$callbackMethod: Background task completed');
    return Future.value(true);
  });
}

/// Service for managing background synchronization between local SQLite and Supabase.
/// Provides methods to initialize background tasks, schedule one-off syncs, and cancel all tasks.
class BackgroundSyncService {
  static const String _taskName = 'sync_to_supabase';
  static const String _oneOffTaskId = 'backgroundSync';
  static const String _periodicTaskId = 'sync-to-supabase-task';

  /// Initializes background sync tasks with Workmanager.
  ///
  /// If [cancelExisting] is true, cancels all existing tasks before initializing.
  /// Registers a periodic sync task to run every hour.
  static Future<void> initialize({bool cancelExisting = false}) async {
    try {
      if (cancelExisting) {
        await Workmanager().cancelAll();
        AppLogger.info('BackgroundSyncService: Existing tasks cancelled');
      }
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      await Workmanager().registerPeriodicTask(
        _periodicTaskId,
        _taskName,
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(seconds: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      AppLogger.info('BackgroundSyncService: Initialized successfully');
    } catch (e) {
      AppLogger.error('BackgroundSyncService: Failed to initialize: $e');
    }
  }

  /// Schedules a one-off background sync task to run after an optional [delay].
  ///
  /// [inputData] can be provided to pass data to the sync task.
  static Future<void> scheduleOneOffSync({
    Duration? delay,
    Map<String, dynamic>? inputData,
  }) async {
    try {
      await Workmanager().registerOneOffTask(
        _oneOffTaskId,
        _taskName,
        initialDelay: delay ?? const Duration(seconds: 30),
        inputData: inputData,
        constraints: Constraints(networkType: NetworkType.connected),
      );
      AppLogger.info('BackgroundSyncService: One-off sync scheduled');
    } catch (e) {
      AppLogger.error(
        'BackgroundSyncService: Failed to schedule one-off sync: $e',
      );
    }
  }

  /// Cancels all scheduled background sync tasks.
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      AppLogger.info('BackgroundSyncService: All tasks cancelled');
    } catch (e) {
      AppLogger.error('BackgroundSyncService: Failed to cancel tasks: $e');
    }
  }
}
