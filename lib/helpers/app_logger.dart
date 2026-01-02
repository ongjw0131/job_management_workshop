/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-18 18:02:38
/// @modify date 2025-09-18 18:02:38
/// @desc [AppLogger: A centralized logging utility using the 'logger' package for consistent and detailed logging across the application.]
library;

import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void info(String message) {
    final caller = _getCallerInfo();
    _logger.i('[$caller] $message');
  }

  static void warning(String message) {
    final caller = _getCallerInfo();
    _logger.w('[$caller] $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final caller = _getCallerInfo();
    _logger.e('[$caller] $message', error: error, stackTrace: stackTrace);
  }

  static void debug(String message) {
    final caller = _getCallerInfo();
    _logger.d('[$caller] $message');
  }

  static void verbose(String message) {
    final caller = _getCallerInfo();
    _logger.v('[$caller] $message');
  }

  static String _getCallerInfo() {
    // Skip 2 frames: this method + log method
    final stack = StackTrace.current.toString().split('\n');
    if (stack.length > 2) {
      final frame = stack[2];
      final regExp = RegExp(r'#2\s+(.+)\s+\((.+)\)');
      final match = regExp.firstMatch(frame);
      if (match != null) {
        final fullMethod = match.group(1) ?? '';
        // Dart format: ClassName.methodName (file.dart:line:col)
        final parts = fullMethod.split('.');
        if (parts.length >= 2) {
          final className = parts[0].replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
          final methodName = parts[1].replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
          return '$className.$methodName';
        }
        return fullMethod;
      }
    }
    return 'Unknown.Unknown';
  }
}
