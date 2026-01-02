/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 14:42:06
/// @modify date 2025-09-17 14:42:06
/// @desc [ConnectionHelper: A helper class to manage and monitor network connectivity status using the connectivity_plus package.]
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionQuality { online, weak, offline }

class ConnectionHelper {
  static final Connectivity _connectivity = Connectivity();

  // connectivity_plus emits a List<ConnectivityResult> on some platforms
  static Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  // Check current connectivity (may return a list on some platforms)
  static Future<List<ConnectivityResult>> getCurrentConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  // Map a list of ConnectivityResult to our ConnectionQuality enum
  static ConnectionQuality mapResultsToQuality(
    List<ConnectivityResult> results,
  ) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn)) {
      return ConnectionQuality.online;
    }
    return ConnectionQuality.offline;
  }
}
