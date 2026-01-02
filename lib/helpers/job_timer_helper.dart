/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 11:23:29
/// @modify date 2025-09-21 11:23:29
/// @desc [JobTimerHelper: A helper class to manage job timers with start, pause, resume, stop, and reset functionalities.]
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:job_management_workshop/services/task_time_log_service.dart';

enum TimerState { stopped, running, paused }

enum TimeEntryType { start, pause, resume, stop, overtime, reset }

class TimeEntry {
  final DateTime timestamp;
  final TimeEntryType type;
  final String description;
  final Duration? duration; // Total duration up to this point

  TimeEntry({
    required this.timestamp,
    required this.type,
    required this.description,
    this.duration,
  });

  String get formattedTimestamp =>
      '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  String get typeDisplayName {
    switch (type) {
      case TimeEntryType.start:
        return 'Started';
      case TimeEntryType.pause:
        return 'Paused';
      case TimeEntryType.resume:
        return 'Resumed';
      case TimeEntryType.stop:
        return 'Stopped';
      case TimeEntryType.overtime:
        return 'Overtime';
      case TimeEntryType.reset:
        return 'Reset';
    }
  }
}

class JobTimer extends ChangeNotifier {
  Timer? _timer;
  TimerState _state = TimerState.stopped;
  DateTime? _startTime;
  Duration _totalWorkTime = Duration.zero;
  Duration _currentSessionTime = Duration.zero;

  final List<TimeEntry> _timeEntries = [];

  // Supabase integration properties
  final int? taskId;
  final String? staffId;
  final TaskTimeLogService _timeLogService = TaskTimeLogService();

  // Configuration
  final Duration normalWorkHours = const Duration(hours: 8);
  final Duration maxWorkHours = const Duration(hours: 12);

  void Function(JobTimer timer)? onTick; // optional external tick callback

  JobTimer({this.taskId, this.staffId, this.onTick});

  // Getters
  TimerState get state => _state;

  Duration get totalWorkTime => _totalWorkTime + _currentSessionTime;

  Duration get currentSessionTime => _currentSessionTime;

  List<TimeEntry> get timeEntries => List.unmodifiable(_timeEntries);

  // Expose private fields for persistence (internal use only)
  DateTime? get startTimeInternal => _startTime;

  List<TimeEntry> get timeEntriesInternal => _timeEntries;

  bool get isRunning => _state == TimerState.running;

  bool get isPaused => _state == TimerState.paused;

  bool get isStopped => _state == TimerState.stopped;

  bool get isOvertime => totalWorkTime > normalWorkHours;

  bool get isMaxTimeReached => totalWorkTime >= maxWorkHours;

  String get formattedTotalTime => _formatDuration(totalWorkTime);

  String get formattedCurrentSession => _formatDuration(currentSessionTime);

  Duration get overtimeDuration => totalWorkTime > normalWorkHours
      ? totalWorkTime - normalWorkHours
      : Duration.zero;

  String get formattedOvertimeTime => _formatDuration(overtimeDuration);

  // Setters for persistence (internal use only)
  set totalWorkTimeInternal(Duration duration) => _totalWorkTime = duration;

  set startTimeInternal(DateTime? time) => _startTime = time;

  set stateInternal(TimerState state) => _state = state;

  void clearTimeEntriesInternal() => _timeEntries.clear();

  void addTimeEntryInternal(TimeEntry entry) => _timeEntries.add(entry);

  void startTimer() {
    if (_state == TimerState.running) return;

    final now = DateTime.now();

    if (_state == TimerState.stopped) {
      _startTime = now;
      _addTimeEntry(TimeEntryType.start, 'Work started');
      // Log to Supabase
      _logToSupabase('start');
    } else if (_state == TimerState.paused) {
      // Reset start time to now so current session starts fresh
      _startTime = now;
      _addTimeEntry(TimeEntryType.resume, 'Work resumed');
      // Log to Supabase
      _logToSupabase('resume');
    }

    _state = TimerState.running;
    _currentSessionTime = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentSessionTime = DateTime.now().difference(_startTime!);

      // Check for overtime
      if (!isOvertime && totalWorkTime > normalWorkHours) {
        _addTimeEntry(TimeEntryType.overtime, 'Overtime started');
      }

      // Auto-stop at max hours (safety feature)
      if (totalWorkTime >= maxWorkHours) {
        stopTimer();
        return;
      }

      onTick?.call(this);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Resume internal ticker after a restore if state is running.
  /// Call this after manually setting internal fields from persistence.
  void resumeTickerIfNeeded() {
    if (_state == TimerState.running) {
      // Ensure start time exists; if missing, set to now so session time counts forward
      _startTime ??= DateTime.now();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_startTime != null) {
          _currentSessionTime = DateTime.now().difference(_startTime!);
          if (!isOvertime && totalWorkTime > normalWorkHours) {
            // Avoid duplicating overtime entry if one already exists
            final hasOvertimeEntry = _timeEntries.any(
              (e) => e.type == TimeEntryType.overtime,
            );
            if (!hasOvertimeEntry) {
              _addTimeEntry(TimeEntryType.overtime, 'Overtime started');
            }
          }
          if (totalWorkTime >= maxWorkHours) {
            stopTimer();
            return;
          }
          onTick?.call(this);
          notifyListeners();
        }
      });
    }
  }

  void pauseTimer() {
    if (_state != TimerState.running) return;

    _timer?.cancel();
    _timer = null;
    _state = TimerState.paused;

    // Add current session to total work time
    _totalWorkTime += _currentSessionTime;
    final workDuration = _totalWorkTime;
    _currentSessionTime = Duration.zero;

    _addTimeEntry(TimeEntryType.pause, 'Work paused', workDuration);
    // Log to Supabase with work duration
    _logToSupabase('pause', workDuration);
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;

    if (_state == TimerState.running) {
      _totalWorkTime += _currentSessionTime;
    }

    _state = TimerState.stopped;
    _currentSessionTime = Duration.zero;

    _addTimeEntry(TimeEntryType.stop, 'Work completed', _totalWorkTime);
    // Log completion to Supabase
    _logToSupabase('complete', _totalWorkTime);
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;

    // Add reset entry to local log before resetting
    final currentTotalTime = _totalWorkTime + _currentSessionTime;
    _addTimeEntry(TimeEntryType.reset, 'Timer reset', currentTotalTime);

    // Log reset to Supabase
    _logToSupabase('reset', currentTotalTime);

    _state = TimerState.stopped;
    _startTime = null;
    _totalWorkTime = Duration.zero;
    _currentSessionTime = Duration.zero;
    // Note: _timeEntries.clear() removed - keeping log history
    notifyListeners();
  }

  void _addTimeEntry(
    TimeEntryType type,
    String description, [
    Duration? duration,
  ]) {
    _timeEntries.add(
      TimeEntry(
        timestamp: DateTime.now(),
        type: type,
        description: description,
        duration: duration ?? totalWorkTime,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    final seconds = (duration.inSeconds % 60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }

  String getTimeBreakdown() {
    final buffer = StringBuffer();
    buffer.writeln('=== TIME BREAKDOWN ===');
    buffer.writeln('Total Work Time: $formattedTotalTime');

    if (isOvertime) {
      buffer.writeln('Overtime: $formattedOvertimeTime');
    }

    buffer.writeln('\n=== SESSION LOG ===');
    for (final entry in _timeEntries) {
      buffer.writeln('${entry.formattedTimestamp}: ${entry.typeDisplayName}');
      if (entry.description.isNotEmpty) {
        buffer.writeln('  ${entry.description}');
      }
      if (entry.duration != null) {
        buffer.writeln('  Total: ${_formatDuration(entry.duration!)}');
      }
    }

    return buffer.toString();
  }

  // Log timer actions to Supabase database
  Future<void> _logToSupabase(String action, [Duration? duration]) async {
    if (taskId == null || staffId == null) return;

    try {
      switch (action) {
        case 'start':
          await _timeLogService.logTimerStart(taskId!, staffId!);
          break;
        case 'pause':
          await _timeLogService.logTimerPause(
            taskId!,
            staffId!,
            duration ?? Duration.zero,
          );
          break;
        case 'resume':
          await _timeLogService.logTimerResume(taskId!, staffId!);
          break;
        case 'stop':
          await _timeLogService.logTimerComplete(
            taskId!,
            staffId!,
            duration ?? totalWorkTime,
          );
          break;
        case 'reset':
          await _timeLogService.logTimerReset(
            taskId!,
            staffId!,
            duration ?? Duration.zero,
          );
          break;
        default:
          // For generic timer actions
          await _timeLogService.logTimerAction(
            taskId: taskId!,
            staffId: staffId!,
            action: action,
            duration: duration,
          );
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting timer functionality
      print('Error logging timer action to Supabase: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
