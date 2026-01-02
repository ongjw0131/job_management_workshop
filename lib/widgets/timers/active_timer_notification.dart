/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 11:24:57
/// @modify date 2025-09-21 11:24:57
/// @desc [ActiveTimerNotification: Persistent notification widget that displays active timer information at the top of dashboard/home page]
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/job_timer_helper.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/services/session_service.dart';
import 'package:job_management_workshop/services/timer_persistence_service.dart';
import 'package:job_management_workshop/views/job_details_page.dart';
import 'package:job_management_workshop/services/job_timer_manager.dart';

class ActiveTimerNotification extends StatefulWidget {
  const ActiveTimerNotification({super.key});

  @override
  State<ActiveTimerNotification> createState() =>
      _ActiveTimerNotificationState();
}

class _ActiveTimerNotificationState extends State<ActiveTimerNotification>
    with WidgetsBindingObserver {
  JobTimer? _activeTimer;
  Task? _activeTask;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForActiveTimer();
    // Update every second to show live timer
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeTimer != null && _activeTimer!.isRunning) {
        setState(() {
          // Force rebuild to update displayed time
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _activeTimer?.removeListener(_onTimerChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh timer when app comes back into foreground
    if (state == AppLifecycleState.resumed) {
      _checkForActiveTimer();
    }
  }

  void _onTimerChanged() {
    setState(() {});
  }

  /// Refresh the active timer display - useful when returning from other screens
  void refreshActiveTimer() {
    _checkForActiveTimer();
  }

  /// Check for any active timers from persistence for current user
  Future<void> _checkForActiveTimer() async {
    try {
      // Get current logged-in staff ID
      final session = await SessionStorage.getStoredSession();
      final currentStaffId = session?['staff_id'] as String?;

      if (currentStaffId == null) {
        // No logged-in user, clear any active timer display
        setState(() {
          _activeTimer = null;
          _activeTask = null;
        });
        return;
      }

      // First check manager in-memory timers for quickest response
      final manager = JobTimerManager();
      final managerTimers = manager.activeTimers.values.where(
        (t) => (t.isRunning || t.isPaused) && t.staffId == currentStaffId,
      );

      Map<int, Map<String, dynamic>> activeTimers = {};
      if (managerTimers.isNotEmpty) {
        for (final t in managerTimers) {
          if (t.taskId != null) {
            activeTimers[t.taskId!] = {
              'timer': t,
              'task': null,
              'taskId': t.taskId!,
              'staffId': t.staffId,
            };
          }
        }
      } else {
        // Fallback to persisted timers
        activeTimers = await TimerPersistenceService.getAllActiveTimers(
          currentStaffId,
        );
      }

      if (activeTimers.isNotEmpty) {
        // Get the first active timer (most recent)
        final entry = activeTimers.entries.first;
        final timerData = entry.value;
        final timer = timerData['timer'] as JobTimer;
        final task = timerData['task'] as Task?;
        final taskId = timerData['taskId'] as int;
        final timerStaffId = timerData['staffId'] as String?;

        // Double-check that this timer belongs to the current user
        if (timerStaffId == currentStaffId &&
            (timer.isRunning || timer.isPaused)) {
          setState(() {
            _activeTimer = timer;
            _activeTask =
                task ??
                Task(
                  taskId: taskId,
                  title: 'Task #$taskId',
                  orderId: 'ORDER-$taskId',
                  description: '',
                  status: TaskStatus.accepted,
                  customerId: 0,
                  staffId: currentStaffId,
                  deadline: DateTime.now().add(const Duration(days: 1)),
                  createdAt: DateTime.now(),
                  repairImagePath: [],
                  uploadImagePath: [],
                );
          });

          _activeTimer!.addListener(_onTimerChanged);
        }
      } else {
        // No active timers for current user
        setState(() {
          _activeTimer = null;
          _activeTask = null;
        });
      }
    } catch (e) {
      // Silently handle errors
      print('Error checking for active timer: $e');
      setState(() {
        _activeTimer = null;
        _activeTask = null;
      });
    }
  }

  Color _getTimerColor() {
    if (_activeTimer == null) return Colors.grey;
    if (_activeTimer!.isOvertime) return Colors.orange;
    if (_activeTimer!.isMaxTimeReached) return Colors.red;
    if (_activeTimer!.isRunning) return Colors.green;
    if (_activeTimer!.isPaused) return Colors.blue;
    return Colors.grey;
  }

  IconData _getTimerIcon() {
    if (_activeTimer == null) return Icons.timer_off;
    switch (_activeTimer!.state) {
      case TimerState.running:
        return Icons.play_circle_filled;
      case TimerState.paused:
        return Icons.pause_circle_filled;
      case TimerState.stopped:
        return Icons.stop_circle;
    }
  }

  String _getStatusText() {
    if (_activeTimer == null) return 'No Active Timer';

    switch (_activeTimer!.state) {
      case TimerState.running:
        return _activeTimer!.isOvertime ? 'OVERTIME' : 'WORKING';
      case TimerState.paused:
        return 'PAUSED';
      case TimerState.stopped:
        return 'STOPPED';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if no active timer
    if (_activeTimer == null || _activeTimer!.isStopped) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_activeTask != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      JobDetailsPage(taskId: _activeTask!.taskId),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTimerColor().withOpacity(0.1),
                  _getTimerColor().withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getTimerColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with timer status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTimerColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTimerIcon(),
                        color: _getTimerColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ACTIVE TIMER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTimerColor(),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusText(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_activeTask != null)
                            Text(
                              'Task: ${_activeTask!.title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Navigate arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Timer display row
                Row(
                  children: [
                    // Main timer display
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _activeTimer!.formattedTotalTime,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getTimerColor(),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),

                            if (_activeTimer!.isRunning &&
                                _activeTimer!.currentSessionTime.inSeconds >
                                    0) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Session',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _activeTimer!.formattedCurrentSession,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Overtime warning
                if (_activeTimer!.isOvertime) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Overtime: ${_activeTimer!.formattedOvertimeTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],

                // Max time warning
                if (_activeTimer!.isMaxTimeReached) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.error, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      const Text(
                        'Maximum work hours reached!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
