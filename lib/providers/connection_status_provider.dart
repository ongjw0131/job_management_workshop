/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-19 22:27:26
/// @modify date 2025-09-19 22:27:26
/// @desc [ConnectionStatusProvider: Monitors and provides the current network connection quality to the app.]
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/connection_helper.dart';

class ConnectionStatusProvider extends ChangeNotifier {
  ConnectionQuality _quality = ConnectionQuality.offline;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectionQuality get quality => _quality;

  ConnectionStatusProvider() {
    // Initial check
    ConnectionHelper.getCurrentConnectivity()
        .then((results) {
          _quality = ConnectionHelper.mapResultsToQuality(results);
          notifyListeners();
        })
        .catchError((_) {});

    // Listen to connectivity changes
    _subscription = ConnectionHelper.connectivityStream.listen((results) {
      final newQuality = ConnectionHelper.mapResultsToQuality(results);
      if (newQuality != _quality) {
        _quality = newQuality;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
