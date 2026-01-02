/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-16 15:49:53
/// @modify date 2025-09-16 15:49:53
/// @desc [SupabaseService: Manages Supabase client initialization and provides access to authentication, database, and storage functionalities.]
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:job_management_workshop/config/supabase_config.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  /// Track initialization state per isolate
  static bool _isInitialized = false;
  static bool _initializationInProgress = false;

  /// Get Supabase client with safety checks
  static SupabaseClient get client {
    if (!_isInitialized) {
      AppLogger.error(
        'SupabaseService: Attempting to access client before initialization. '
        'Call SupabaseService.initialize() first or use getSafeClient().',
      );
      throw StateError('Supabase must be initialized before accessing client');
    }
    return Supabase.instance.client;
  }

  /// Safe client getter that auto-initializes if needed
  static Future<SupabaseClient> getSafeClient() async {
    if (!_isInitialized && !_initializationInProgress) {
      AppLogger.info(
        'SupabaseService: Auto-initializing for safe client access',
      );
      await initialize();
    }

    // Wait for initialization to complete if in progress
    while (_initializationInProgress) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return client;
  }

  /// Initialize Supabase with proper error handling and state tracking
  static Future<bool> initialize() async {
    // Prevent multiple simultaneous initializations
    if (_initializationInProgress) {
      AppLogger.info(
        'SupabaseService: Initialization already in progress, waiting...',
      );
      while (_initializationInProgress) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    // Return early if already initialized
    if (_isInitialized) {
      if (kDebugMode) {
        AppLogger.info('SupabaseService: Already initialized, skipping');
      }
      return true;
    }

    _initializationInProgress = true;

    try {
      // Check if credentials are configured
      if (SupabaseConfig.supabaseUrl == 'YOUR_SUPABASE_URL_HERE' ||
          SupabaseConfig.supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY_HERE') {
        if (kDebugMode) {
          AppLogger.info(
            '⚠️ Supabase credentials not configured. Please update lib/config/supabase_config.dart',
          );
        }
        _initializationInProgress = false;
        return false;
      }

      AppLogger.info('SupabaseService: Starting initialization...');

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;
      _initializationInProgress = false;

      if (kDebugMode) {
        AppLogger.info('✅ Supabase initialized successfully');
      }
      return true;
    } catch (e) {
      _isInitialized = false;
      _initializationInProgress = false;

      if (kDebugMode) {
        AppLogger.error('❌ Failed to initialize Supabase: $e');
      }
      return false;
    }
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (useful for testing or isolate cleanup)
  static void reset() {
    _isInitialized = false;
    _initializationInProgress = false;
    if (kDebugMode) {
      AppLogger.info('SupabaseService: Reset initialization state');
    }
  }

  // Convenient getters that use safe client access
  static Future<GoTrueClient> get auth async => (await getSafeClient()).auth;

  static Future<SupabaseQueryBuilder> from(String table) async =>
      (await getSafeClient()).from(table);

  static Future<SupabaseStorageClient> get storage async =>
      (await getSafeClient()).storage;

  static Future<String> uploadImageToBucket(
    String bucket,
    String filePath,
  ) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    final storagePath = 'Image/$fileName';
    final storageClient = await storage;
    await storageClient.from(bucket).upload(storagePath, file);
    return storagePath;
  }

  static Future<String> uploadSignatureToBucket(
    String bucket,
    String filePath,
  ) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    final storagePath = 'Image/$fileName';
    final storageClient = await storage;
    await storageClient.from(bucket).upload(storagePath, file);
    return storagePath;
  }
}
