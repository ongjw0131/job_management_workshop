/// @author [Ong Jun Wei, Chong Jun Xiang]
/// @email [ongjw-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 17:08:24
/// @modify date 2025-09-13 09:30:00
/// @desc [This file contains the NotificationsPage widget which displays a list of notifications for a staff member. It fetches data from a Supabase database and allows theme toggling. Enhanced with popup and navigation to job details.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/notification_controller.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/repositories/notification_repository.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:job_management_workshop/views/apps/sidebar.dart';
import 'package:job_management_workshop/views/job_details_page.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const NotificationsPage({
    super.key,
    this.isDarkMode = false,
    required this.onThemeToggle,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late bool _currentDarkMode;
  late String staffId;
  late String staffName;
  List<NotificationItem> notifications = [];
  bool _isLoading = true;
  final NotificationController _notificationController =
      NotificationController();

  @override
  void initState() {
    super.initState();
    _currentDarkMode = widget.isDarkMode;
    _loadNotifications();
  }

  @override
  void dispose() {
    _notificationController.removeListener(_onNotificationControllerChanged);
    _notificationController.dispose();
    super.dispose();
  }

  void _loadNotifications() async {
    final sessionProvider = Provider.of<SessionProvider>(
      context,
      listen: false,
    );
    staffId = sessionProvider.staffId ?? '';
    staffName = sessionProvider.staffName ?? '';
    await _notificationController.initializeRealTimeNotifications(staffId);
    await _loadNotificationsFromController();
    _notificationController.addListener(_onNotificationControllerChanged);
  }

  Future<void> _loadNotificationsFromController() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _notificationController.loadNotifications(staffId);
      _convertControllerNotificationsToUI();
    } catch (e) {
      AppLogger.error('Error loading notifications: $e');
      await _fetchNotifications();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _convertControllerNotificationsToUI() {
    notifications = _notificationController.notifications.map((
      appNotification,
    ) {
      return NotificationItem(
        id: appNotification.id.toString(),
        title: appNotification.title,
        subtitle: appNotification.subtitle ?? '',
        description: appNotification.description ?? 'Click to view details...',
        time: _formatTime(appNotification.createdAt.toIso8601String()),
        icon: _getIconFromString(appNotification.iconType ?? 'notifications'),
        iconColor: _getColorFromString(appNotification.iconColor ?? 'blue'),
        taskId: appNotification.taskId,
        orderId: null,
      );
    }).toList();
    setState(() {});
  }

  void _onNotificationControllerChanged() {
    if (mounted) {
      _convertControllerNotificationsToUI();
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await NotificationRepository()
          .getAllNotificationsByStaffId(staffId);
      if (response.isNotEmpty) {
        final items = response
            .map<NotificationItem>((appNotification) {
              final int? parsedTaskId = appNotification.taskId;
              return NotificationItem(
                id: appNotification.id?.toString() ?? '',
                title: appNotification.title,
                subtitle: appNotification.subtitle ?? '',
                description:
                    appNotification.description ?? 'Click to view details...',
                icon: _getIconFromString(
                  appNotification.iconType ?? 'notifications',
                ),
                iconColor: _getColorFromString(
                  appNotification.iconColor ?? 'blue',
                ),
                time: _formatTime(appNotification.createdAt.toIso8601String()),
                taskId: parsedTaskId,
                orderId:
                    null, // AppNotification does not have orderId; set to null or extend if needed
              );
            })
            .where((n) => n.taskId != null)
            .toList();
        setState(() {
          notifications = items;
        });
      } else {
        setState(() {
          notifications = [];
        });
      }
    } catch (e) {
      setState(() {
        notifications = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIconFromString(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'check_circle':
        return Icons.check_circle;
      case 'task_alt':
        return Icons.task_alt;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'error':
        return Icons.error;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  void _handleThemeToggle(bool isDark) {
    setState(() {
      _currentDarkMode = isDark;
    });
    widget.onThemeToggle(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              _loadNotifications();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: AppSidebar(
        isDarkMode: _currentDarkMode,
        onThemeToggle: _handleThemeToggle,
        staffId: staffId,
        staffName: staffName,
      ),
      body: _isLoading
          ? const SafeArea(child: Center(child: CircularProgressIndicator()))
          : SafeArea(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Task assignments and updates will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchNotifications();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return NotificationCard(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onDismiss: () => _dismissNotification(index),
                          );
                        },
                      ),
                    ),
            ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).dialogTheme.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          notification.time,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (notification.subtitle.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: notification.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: notification.iconColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                notification.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (notification.orderId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Order: ${notification.orderId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToJobDetails(notification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: notification.iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('View Job Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToJobDetails(NotificationItem notification) async {
    Navigator.pop(context);
    try {
      if (notification.taskId != null) {
        try {
          final queryBuilder = await SupabaseService.from('notifications');
          await queryBuilder
              .update({'is_read': true})
              .eq('id', notification.id);
        } catch (_) {}
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsPage(taskId: notification.taskId!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No linked job details for this notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error navigating to job details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading job details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _dismissNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification dismissed'),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.title + notification.time),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notification.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notification.time,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: notification.iconColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String time;
  final int? taskId;
  final String? orderId;
  final String id;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.time,
    this.taskId,
    this.orderId,
    required this.id,
  });
}
