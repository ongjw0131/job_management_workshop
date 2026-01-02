/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-19 22:28:18
/// @modify date 2025-09-19 22:28:18
/// @desc [ConnectionStatusBar: A widget that displays the current network connection quality as a colored status bar at the top of the screen.]
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/connection_helper.dart';

class ConnectionStatusBarWidget extends StatefulWidget {
  final ConnectionQuality quality;

  const ConnectionStatusBarWidget({super.key, required this.quality});

  @override
  State<ConnectionStatusBarWidget> createState() =>
      _ConnectionStatusBarWidgetState();
}

class _ConnectionStatusBarWidgetState extends State<ConnectionStatusBarWidget> {
  Timer? _hideTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _updateVisibilityForQuality(widget.quality);
  }

  @override
  void didUpdateWidget(covariant ConnectionStatusBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quality != widget.quality) {
      _updateVisibilityForQuality(widget.quality);
    }
  }

  void _updateVisibilityForQuality(ConnectionQuality quality) {
    _hideTimer?.cancel();
    if (quality == ConnectionQuality.online) {
      // show immediately then hide after 5 seconds
      setState(() => _visible = true);
      _hideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _visible = false);
      });
    } else {
      // weak or offline -> always visible
      setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    String message;
    Color color;
    switch (widget.quality) {
      case ConnectionQuality.online:
        message = 'You are online';
        color = Colors.green;
        break;
      case ConnectionQuality.weak:
        message = 'You have a weak connection';
        color = Colors.orange;
        break;
      case ConnectionQuality.offline:
        message = 'You are offline';
        color = Colors.red;
        break;
    }

    return Material(
      color: color,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
