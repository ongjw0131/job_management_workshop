/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 11:24:22
/// @modify date 2025-09-21 11:24:22
/// @desc [NotificationDisplayHelper: Helper class for showing system-wide notifications and pop-ups]
library;

import 'package:flutter/material.dart';

class NotificationDisplayHelper {
  /// Show a success notification with timer start info
  static void showJobAcceptedNotification(
    BuildContext context,
    String taskTitle,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Accepted & Timer Started! ⏰',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Task: $taskTitle',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Notification saved to database',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View Timer',
          textColor: Colors.white,
          backgroundColor: Colors.green[400],
          onPressed: () {
            // Could navigate to timer view or expand timer section
          },
        ),
      ),
    );
  }

  /// Show a general notification pop-up
  static void showNotificationPopup(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Color backgroundColor = Colors.blue,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show error notification
  static void showErrorNotification(
    BuildContext context,
    String message, {
    String title = 'Error',
  }) {
    showNotificationPopup(
      context,
      title: title,
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red[600]!,
    );
  }

  /// Show success notification
  static void showSuccessNotification(
    BuildContext context,
    String message, {
    String title = 'Success',
  }) {
    showNotificationPopup(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green[600]!,
    );
  }

  /// Show info notification
  static void showInfoNotification(
    BuildContext context,
    String message, {
    String title = 'Info',
  }) {
    showNotificationPopup(
      context,
      title: title,
      message: message,
      icon: Icons.info,
      backgroundColor: Colors.blue[600]!,
    );
  }

  /// Show warning notification
  static void showWarningNotification(
    BuildContext context,
    String message, {
    String title = 'Warning',
  }) {
    showNotificationPopup(
      context,
      title: title,
      message: message,
      icon: Icons.warning,
      backgroundColor: Colors.orange[600]!,
    );
  }
}
