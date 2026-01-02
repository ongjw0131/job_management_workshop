/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 21:58:04
/// @modify date 2025-09-17 10:45:00
/// @desc [AppNotification: Model class representing a notification record from the database. Renamed to avoid conflict with Flutter's Notification class.]
library;

class AppNotification {
  final int? id;

  final String staffId;
  final int? taskId;
  final String title;
  final String? subtitle;
  final String? description;
  final String? iconType;
  final String? iconColor;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppNotification({
    this.id, // optional
    required this.staffId,
    this.taskId,
    required this.title,
    this.subtitle,
    this.description,
    this.iconType,
    this.iconColor,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] == null
          ? null
          : (json['id'] is int
                ? json['id'] as int
                : int.tryParse(json['id'].toString())),
      staffId: json['staff_id']?.toString() ?? '',
      taskId: json['task_id'] == null
          ? null
          : (json['task_id'] is int
                ? json['task_id'] as int
                : int.tryParse(json['task_id'].toString())),
      title: json['title']?.toString() ?? 'Notification',
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      iconType: json['icon_type']?.toString(),
      iconColor: json['icon_color']?.toString(),
      isRead: (json['is_read'] is bool)
          ? json['is_read'] as bool
          : (json['is_read'] is int
                ? (json['is_read'] as int) == 1
                : (json['is_read']?.toString() == 'true' ||
                      json['is_read']?.toString() == '1')),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _maybeParseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'task_id': taskId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'icon_type': iconType,
      'icon_color': iconColor,
      'is_read': isRead,
      // omit created_at, updated_at → let DB manage
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

DateTime _parseDateTime(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _maybeParseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
