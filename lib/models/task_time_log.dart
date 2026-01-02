/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:17:49
/// @modify date 2025-09-17 13:17:49
/// @desc [TaskTimeLog: Model class representing a log entry for task time tracking with JSON serialization/deserialization.]
class TaskTimeLog {
  final int logId;
  final int taskId;
  final String staffId;
  final String action;
  final DateTime timestamp;
  final Duration? duration;

  TaskTimeLog({
    required this.logId,
    required this.taskId,
    required this.staffId,
    required this.action,
    required this.timestamp,
    this.duration,
  });

  factory TaskTimeLog.fromJson(Map<String, dynamic> json) {
    return TaskTimeLog(
      logId: json['log_id'] as int,
      taskId: json['task_id'] as int,
      staffId: json['staff_id'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: json['duration'] != null
          ? _parseInterval(json['duration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'task_id': taskId,
      'staff_id': staffId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration != null
          ? 'PT${duration!.inHours}H${duration!.inMinutes.remainder(60)}M'
          : null,
    };
  }

  static Duration? _parseInterval(dynamic interval) {
    if (interval is String) {
      final value = interval.trim();
      // ISO8601 pattern PT#H#M#S
      // ISO8601 basic duration form: PT#H#M#S (each optional)
      final iso = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$');
      final isoMatch = iso.firstMatch(value);
      if (isoMatch != null) {
        final hours = int.tryParse(isoMatch.group(1) ?? '0') ?? 0;
        final minutes = int.tryParse(isoMatch.group(2) ?? '0') ?? 0;
        final seconds = int.tryParse(isoMatch.group(3) ?? '0') ?? 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
      // Legacy textual patterns like "2 hour 15 minute"
      final legacy = RegExp(r'(?:(\d+)\s*hour)?[^\d]*(?:(\d+)\s*minute)?');
      final legacyMatch = legacy.firstMatch(value);
      if (legacyMatch != null) {
        final hours = int.tryParse(legacyMatch.group(1) ?? '0') ?? 0;
        final minutes = int.tryParse(legacyMatch.group(2) ?? '0') ?? 0;
        if (hours > 0 || minutes > 0) {
          return Duration(hours: hours, minutes: minutes);
        }
      }
    }
    return null;
  }
}
