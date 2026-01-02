/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:17:26
/// @modify date 2025-09-17 13:17:26
/// @desc [Task: Model class representing a task with various attributes and methods for JSON serialization/deserialization.]
enum TaskStatus {
  assigned('assigned'),
  accepted('accepted'),
  completed('completed');

  const TaskStatus(this.value);

  final String value;

  static TaskStatus? fromString(String? statusString) {
    if (statusString == null) return null;
    for (TaskStatus status in TaskStatus.values) {
      if (status.value == statusString) {
        return status;
      }
    }
    return null;
  }

  @override
  String toString() => value;
}

class Task {
  static const String cacheFolderName = 'job_image_cache';

  final int taskId;

  int get id => taskId;
  final String title;
  final String orderId;
  final int customerId;
  final String? description;
  final TaskStatus status;
  final DateTime deadline;
  final DateTime createdAt;
  final String staffId;
  final List<String> repairImagePath;
  final List<String> uploadImagePath;
  final String? signaturePath;

  Task({
    required this.taskId,
    required this.title,
    required this.orderId,
    required this.customerId,
    this.description,
    required this.status,
    required this.deadline,
    required this.createdAt,
    required this.staffId,
    List<String>? repairImagePath,
    List<String>? uploadImagePath,
    this.signaturePath,
  }) : repairImagePath = repairImagePath ?? const [],
       uploadImagePath = uploadImagePath ?? const [];

  factory Task.fromJson(Map<String, dynamic> json) {
    List<String> repairPaths = [];
    List<String> uploadPaths = [];
    if (json.containsKey('repair_image_path') &&
        json['repair_image_path'] != null) {
      final raw = json['repair_image_path'];
      if (raw is List) {
        repairPaths = raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (raw is String) {
        repairPaths = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    if (json.containsKey('upload_image_path') &&
        json['upload_image_path'] != null) {
      final raw = json['upload_image_path'];
      if (raw is List) {
        uploadPaths = raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (raw is String) {
        uploadPaths = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    if (repairPaths.isEmpty &&
        json.containsKey('image_paths') &&
        json['image_paths'] != null) {
      final raw = json['image_paths'];
      if (raw is List) {
        repairPaths = raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (raw is String) {
        repairPaths = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    if (repairPaths.isEmpty &&
        json.containsKey('image_path') &&
        json['image_path'] != null) {
      final single = json['image_path']?.toString();
      if (single != null && single.isNotEmpty) {
        repairPaths = [single];
      }
    }
    return Task(
      taskId: json['task_id'] is int
          ? json['task_id'] as int
          : int.tryParse(json['task_id'].toString()) ?? 0,
      title: json['title'] as String,
      orderId: json['order_id'] as String,
      customerId: json['customer_id'] is int
          ? json['customer_id'] as int
          : int.tryParse(json['customer_id'].toString()) ?? 0,
      description: json['description'] as String?,
      status:
          TaskStatus.fromString(json['status'] as String) ??
          TaskStatus.assigned,
      deadline: json['deadline'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.parse(json['deadline'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      staffId: json['staff_id'] as String,
      repairImagePath: repairPaths,
      uploadImagePath: uploadPaths,
      signaturePath: json['signature_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'title': title,
      'order_id': orderId,
      'customer_id': customerId,
      'description': description,
      'status': status.value,
      'deadline': deadline.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'staff_id': staffId,
      'repair_image_path': repairImagePath.join(','),
      'upload_image_path': uploadImagePath.join(','),
      'signature_path': signaturePath,
    };
  }

  bool get isAssigned => status == TaskStatus.assigned;

  bool get isAccepted => status == TaskStatus.accepted;

  bool get isCompleted => status == TaskStatus.completed;

  String get statusDisplayName {
    return status.value;
  }

  Task copyWithStatus(TaskStatus newStatus) {
    return Task(
      taskId: taskId,
      title: title,
      orderId: orderId,
      customerId: customerId,
      description: description,
      status: newStatus,
      deadline: deadline,
      createdAt: createdAt,
      staffId: staffId,
      repairImagePath: repairImagePath,
      uploadImagePath: uploadImagePath,
    );
  }

  factory Task.empty() {
    return Task(
      taskId: 0,
      title: 'Unknown',
      orderId: '',
      customerId: 0,
      description: null,
      status: TaskStatus.assigned,
      deadline: DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      staffId: '',
    );
  }
}
