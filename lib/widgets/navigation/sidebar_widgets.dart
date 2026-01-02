/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 16:16:39
/// @modify date 2025-09-11 16:16:39
/// @desc [SidebarWidgets: A collection of widgets for the sidebar navigation drawer, including header, navigation tiles, notification badge, and theme toggle.]

library;

import 'package:flutter/material.dart';

class SidebarHeaderWidget extends StatelessWidget {
  final String staffId;
  final String staffName;
  final ColorScheme colorScheme;
  final double avatarRadius;
  final double avatarIconSize;
  final double headerSpacing;

  const SidebarHeaderWidget({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.colorScheme,
    this.avatarRadius = 30.0,
    this.avatarIconSize = 35.0,
    this.headerSpacing = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: avatarIconSize,
              color: colorScheme.primary,
              semanticLabel: 'User profile',
            ),
          ),
          SizedBox(height: headerSpacing),
          Text(
            'ID: $staffId',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            staffName.isEmpty ? '-' : staffName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: headerSpacing),
        ],
      ),
    );
  }
}

class SidebarNavigationTileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isCurrentPage;
  final Widget? trailing;

  const SidebarNavigationTileWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.semanticLabel,
    required this.onTap,
    this.isCurrentPage = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        semanticLabel: semanticLabel,
        color: isCurrentPage ? colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isCurrentPage ? colorScheme.primary : null,
          fontWeight: isCurrentPage ? FontWeight.w600 : null,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      tileColor: isCurrentPage
          ? colorScheme.primaryContainer.withAlpha(77)
          : null,
      shape: isCurrentPage
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
          : null,
      enableFeedback: true,
      selected: isCurrentPage,
    );
  }
}

class NotificationBadgeWidget extends StatelessWidget {
  final String count;
  final double badgePadding;
  final double badgeVerticalPadding;
  final double badgeBorderRadius;
  final double badgeFontSize;

  const NotificationBadgeWidget({
    super.key,
    required this.count,
    this.badgePadding = 6.0,
    this.badgeVerticalPadding = 2.0,
    this.badgeBorderRadius = 10.0,
    this.badgeFontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgePadding,
        vertical: badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(badgeBorderRadius),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: Colors.white,
          fontSize: badgeFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ThemeToggleWidget extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggle;

  const ThemeToggleWidget({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.nightlight_round),
      title: const Text('Dark Mode'),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (value) {
          onToggle(value);
          // Removed Navigator.pop(context) to avoid double-pop when caller also pops.
        },
      ),
      enableFeedback: true,
    );
  }
}
