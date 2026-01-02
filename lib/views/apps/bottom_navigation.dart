/// @author [Chong Jun Xiang, Liew Kai Quan]
/// @email [chongjx-wm22@student.tarc.edu.my, liewkq-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 15:49:26
/// @modify date 2025-09-11 15:49:26
/// @desc [BottomNavigation: Manages bottom navigation and page switching.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/views/history_page.dart';
import 'package:job_management_workshop/views/home_page.dart';
import 'package:job_management_workshop/views/profile_page.dart';
import 'package:job_management_workshop/widgets/navigation/bottom_nav_bar_widget.dart';

class BottomNavigation extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;
  final int initialIndex;

  const BottomNavigation({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    this.initialIndex = 0,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
      HistoryPage(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
      ProfilePage(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
