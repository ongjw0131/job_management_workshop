library;

import 'dart:collection';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/helpers/job_timer_helper.dart';
import 'package:job_management_workshop/services/timer_persistence_service.dart';

/// JobTimerManager: Central lifecycle & retrieval for JobTimers so dashboard can
/// still access active timers after leaving a details page.
class JobTimerManager {
  JobTimerManager._internal();
  static final JobTimerManager _instance = JobTimerManager._internal();
  factory JobTimerManager() => _instance;

  final Map<int, JobTimer> _timers = {}; // key: taskId

  UnmodifiableMapView<int, JobTimer> get activeTimers => UnmodifiableMapView(_timers);

  JobTimer? getTimer(int taskId) => _timers[taskId];

  Future<JobTimer> getOrCreateTimer({
    required int taskId,
    required String staffId,
  }) async {
    if (_timers.containsKey(taskId)) {
      return _timers[taskId]!;
    }
    // Try restore
    final restored = await TimerPersistenceService.restoreTimer(taskId);
    JobTimer timer;
    if (restored != null) {
      timer = restored;
      AppLogger.info('Manager restored timer for task $taskId');
    } else {
      timer = JobTimer(taskId: taskId, staffId: staffId);
      AppLogger.info('Manager created new timer for task $taskId');
    }
    // Attach persistence listener
    timer.addListener(() {
      TimerPersistenceService.saveTimerState(taskId, timer);
    });
    _timers[taskId] = timer;
    return timer;
  }

  void removeTimer(int taskId, {bool dispose = false}) {
    final timer = _timers.remove(taskId);
    if (timer != null && dispose) {
      timer.dispose();
    }
  }

  /// Clear all timers (e.g., logout)
  void clearAll({bool dispose = false}) {
    if (dispose) {
      for (final t in _timers.values) {
        t.dispose();
      }
    }
    _timers.clear();
  }
}
