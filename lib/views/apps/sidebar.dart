/// @author [Chong Jun Xiang, Liew Kai Quan, Ong Jun Wei]
/// @email [chongjx-wm22@student.tarc.edu.my, liewkq-wm22@student.tarc.edu.my, ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 16:16:39
/// @modify date 2025-09-11 16:16:39
/// @desc [Sidebar: A navigation drawer for the app with user info, navigation links, settings, and theme toggle.]

library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/main.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/views/help_and_support_page.dart';
import 'package:job_management_workshop/views/notification_page.dart';
import 'package:job_management_workshop/views/parts_management_page.dart';
import 'package:job_management_workshop/widgets/navigation/sidebar_widgets.dart';
import 'package:provider/provider.dart';

class AppSidebar extends StatelessWidget {
  static const String _notificationCount = '3';

  static const String _homeRoute = '/';
  static const String _notificationsRoute = '/notifications';
  static const String _partsRoute = '/parts';
  static const String _helpSupportRoute = '/help-support';

  final bool isDarkMode;

  final ValueChanged<bool> onThemeToggle;

  const AppSidebar({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.staffId,
    required this.staffName,
  });

  final String staffId;

  final String staffName;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      semanticLabel: 'Navigation drawer',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(context),
                _buildNavigationSection(context),
                const Divider(),
                _buildSettingsSection(context),
              ],
            ),
          ),

          _buildThemeToggleSection(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        final staffId = session.staffId ?? "-";
        final staffName =
            ("${(session.firstName ?? "").toString().trim()} ${(session.lastName ?? "").toString().trim()}")
                .trim();
        return SidebarHeaderWidget(
          staffId: staffId,
          staffName: staffName,
          colorScheme: colorScheme,
        );
      },
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);

    return Column(
      children: [
        _buildNavigationTile(
          context: context,
          icon: Icons.home,
          title: 'Home',
          semanticLabel: 'Navigate to home page',
          onTap: () => _navigateToHome(context),
          isCurrentPage: _isCurrentPage(currentRoute, _homeRoute),
        ),

        _buildNavigationTile(
          context: context,
          icon: Icons.notifications,
          title: 'Notifications',
          semanticLabel: 'View notifications, $_notificationCount unread',
          trailing: _buildNotificationBadge(context),
          onTap: () => _navigateToNotifications(context),
          isCurrentPage: _isCurrentPage(currentRoute, _notificationsRoute),
        ),

        _buildNavigationTile(
          context: context,
          icon: Icons.scanner,
          title: 'Parts Scanner',
          semanticLabel: 'Open parts scanner',
          onTap: () => _navigateToParts(context),
          isCurrentPage: _isCurrentPage(currentRoute, _partsRoute),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);

    return Column(
      children: [
        _buildNavigationTile(
          context: context,
          icon: Icons.help,
          title: 'Help & Support',
          semanticLabel: 'Get help and support',
          onTap: () => _navigateToHelpSupport(context),
          isCurrentPage: _isCurrentPage(currentRoute, _helpSupportRoute),
        ),

        _buildNavigationTile(
          context: context,
          icon: Icons.logout,
          title: 'Logout',
          semanticLabel: 'Logout from the app',
          onTap: () => _handleLogout(context),
          isCurrentPage: false,
        ),
      ],
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String semanticLabel,
    required VoidCallback onTap,
    Widget? trailing,
    bool isCurrentPage = false,
  }) {
    return SidebarNavigationTileWidget(
      icon: icon,
      title: title,
      semanticLabel: semanticLabel,
      onTap: onTap,
      trailing: trailing,
      isCurrentPage: isCurrentPage,
    );
  }

  Widget _buildNotificationBadge(BuildContext context) {
    return const NotificationBadgeWidget(count: _notificationCount);
  }

  Widget _buildThemeToggleSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ThemeToggleWidget(
      isDarkMode: themeProvider.isDarkMode,
      onToggle: (value) {
        themeProvider.toggleTheme(value);
        Navigator.pop(context);
      },
    );
  }

  String? _getCurrentRoute(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      if (route?.settings.name != null) {
        return route!.settings.name;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isCurrentPage(String? currentRoute, String targetRoute) {
    if (currentRoute == null) {
      return targetRoute == _homeRoute;
    }

    if (currentRoute == targetRoute) {
      return true;
    }

    if ((currentRoute.isEmpty || currentRoute == '/') &&
        targetRoute == _homeRoute) {
      return true;
    }

    return false;
  }

  void _showCurrentPageMessage(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You are already on the $pageName page'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);

    if (_isCurrentPage(currentRoute, _homeRoute)) {
      Navigator.pop(context);
      _showCurrentPageMessage(context, 'Home');
      return;
    }

    try {
      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to navigate to home');
    }
  }

  void _navigateToNotifications(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);

    if (_isCurrentPage(currentRoute, _notificationsRoute)) {
      Navigator.pop(context);
      _showCurrentPageMessage(context, 'Notifications');
      return;
    }

    try {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsPage(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          ),
          settings: const RouteSettings(name: _notificationsRoute),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open notifications');
    }
  }

  void _navigateToParts(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);

    if (_isCurrentPage(currentRoute, _partsRoute)) {
      Navigator.pop(context);
      _showCurrentPageMessage(context, 'Parts Scanner');
      return;
    }

    try {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PartsManagementPage(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          ),
          settings: const RouteSettings(name: _partsRoute),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open parts scanner');
    }
  }

  void _navigateToHelpSupport(BuildContext context) {
    final currentRoute = _getCurrentRoute(context);

    if (_isCurrentPage(currentRoute, _helpSupportRoute)) {
      Navigator.pop(context);
      _showCurrentPageMessage(context, 'Help & Support');
      return;
    }

    try {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HelpSupportPage(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          ),
          settings: const RouteSettings(name: _helpSupportRoute),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open help & support');
    }
  }

  void _handleLogout(BuildContext context) {
    Navigator.pop(context);
    _showLogoutDialog(context);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),

          TextButton(
            onPressed: () => _performLogout(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext dialogContext) async {
    try {
      Navigator.pop(dialogContext);

      Provider.of<SessionProvider>(dialogContext, listen: false).logout();

      Navigator.of(
        dialogContext,
      ).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      Navigator.pop(dialogContext);
      _showErrorSnackBar(dialogContext, 'Logout failed. Please try again.');
    }
  }
}
