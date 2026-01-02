/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 11:05:00
/// @modify date 2025-09-17 11:05:00
/// @desc [NotificationController: Handles loading/marking notifications and mapping for the view.]
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:job_management_workshop/helpers/app_logger.dart'; // Added for logging
import 'package:job_management_workshop/models/notifications.dart';
import 'package:job_management_workshop/repositories/notification_repository.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  bool isLoading = false;
  List<AppNotification> notifications = [];
  RealtimeChannel? _notificationSubscription;
  String? _currentStaffId;

  /// Initialize real-time notifications for a staff member
  Future<void> initializeRealTimeNotifications(String staffId) async {
    _currentStaffId = staffId;
    await _subscribeToNotificationChanges(staffId);
  }

  /// Subscribe to real-time notification changes from Supabase
  Future<void> _subscribeToNotificationChanges(String staffId) async {
    try {
      AppLogger.info('Setting up real-time notifications for staff: $staffId');

      final client = await SupabaseService.getSafeClient();

      // Clean up existing subscription
      _notificationSubscription?.unsubscribe();

      _notificationSubscription = client
          .channel('notifications_$staffId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'staff_id',
              value: staffId,
            ),
            callback: (payload) {
              AppLogger.info('New notification received: ${payload.newRecord}');
              _handleNewNotification(payload.newRecord);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'staff_id',
              value: staffId,
            ),
            callback: (payload) {
              AppLogger.info('Notification updated: ${payload.newRecord}');
              _handleUpdatedNotification(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      AppLogger.error('Error setting up real-time notifications: $e');
    }
  }

  /// Handle new notification received via real-time subscription
  void _handleNewNotification(Map<String, dynamic>? newRecord) {
    if (newRecord == null) return;

    try {
      final newNotification = AppNotification.fromJson(newRecord);
      notifications.insert(0, newNotification); // Add to top of list
      notifyListeners();
      AppLogger.info('Added new notification: ${newNotification.title}');
    } catch (e) {
      AppLogger.error('Error handling new notification: $e');
    }
  }

  /// Handle updated notification received via real-time subscription
  void _handleUpdatedNotification(Map<String, dynamic>? updatedRecord) {
    if (updatedRecord == null) return;

    try {
      final updatedNotification = AppNotification.fromJson(updatedRecord);
      final index = notifications.indexWhere(
        (n) => n.id == updatedNotification.id,
      );

      if (index != -1) {
        notifications[index] = updatedNotification;
        notifyListeners();
        AppLogger.info('Updated notification: ${updatedNotification.title}');
      }
    } catch (e) {
      AppLogger.error('Error handling updated notification: $e');
    }
  }

  Future<void> loadNotifications(String staffId) async {
    isLoading = true;
    notifyListeners();
    try {
      AppLogger.info('Loading notifications for staff: $staffId');
      notifications = await _notificationRepository
          .getAllNotificationsByStaffId(staffId);
      AppLogger.info('Loaded ${notifications.length} notifications');
    } catch (e) {
      AppLogger.error('Error loading notifications: $e');
      notifications = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      final idx = notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final n = notifications[idx];
        notifications[idx] = AppNotification(
          id: n.id,
          staffId: n.staffId,
          title: n.title,
          subtitle: n.subtitle,
          description: n.description,
          iconType: n.iconType,
          iconColor: n.iconColor,
          isRead: true,
          createdAt: n.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('markAsRead error: $e');
      }
    }
  }

  Future<int> getUnreadCount(String staffId) =>
      _notificationRepository.getUnreadCount(staffId);

  /// Refresh notifications manually from Supabase
  Future<void> refreshNotifications() async {
    if (_currentStaffId != null) {
      await loadNotifications(_currentStaffId!);
    }
  }

  /// Clean up resources and subscriptions
  @override
  void dispose() {
    _notificationSubscription?.unsubscribe();
    super.dispose();
  }
}
