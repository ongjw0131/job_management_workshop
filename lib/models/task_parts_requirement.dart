/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21
/// @modify date 2025-09-21
/// @desc [TaskPartsRequirement: Model for tracking parts requirements for specific tasks]
library;

class TaskPartsRequirement {
  final String requirementId;
  final int taskId;
  final String partId;
  final String barcode;
  final String partName;
  final int requiredQuantity;
  final int? verifiedQuantity; // How much has been verified/used
  final bool isVerified;
  final DateTime? verifiedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskPartsRequirement({
    required this.requirementId,
    required this.taskId,
    required this.partId,
    required this.barcode,
    required this.partName,
    required this.requiredQuantity,
    this.verifiedQuantity,
    this.isVerified = false,
    this.verifiedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskPartsRequirement.fromJson(Map<String, dynamic> json) {
    return TaskPartsRequirement(
      requirementId: json['requirement_id'] as String,
      taskId: json['task_id'] is String
          ? int.parse(json['task_id'] as String)
          : json['task_id'] as int,
      partId: json['part_id'] as String,
      barcode: json['barcode'] as String,
      partName: json['part_name'] as String,
      requiredQuantity: json['required_quantity'] as int? ?? 0,
      verifiedQuantity: json['verified_quantity'] as int?,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedDate: json['verified_date'] != null
          ? DateTime.parse(json['verified_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requirement_id': requirementId,
      'task_id': taskId,
      'part_id': partId,
      'barcode': barcode,
      'part_name': partName,
      'required_quantity': requiredQuantity,
      'verified_quantity': verifiedQuantity,
      'is_verified': isVerified,
      'verified_date': verifiedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskPartsRequirement copyWith({
    String? requirementId,
    int? taskId,
    String? partId,
    String? barcode,
    String? partName,
    int? requiredQuantity,
    int? verifiedQuantity,
    bool? isVerified,
    DateTime? verifiedDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskPartsRequirement(
      requirementId: requirementId ?? this.requirementId,
      taskId: taskId ?? this.taskId,
      partId: partId ?? this.partId,
      barcode: barcode ?? this.barcode,
      partName: partName ?? this.partName,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      verifiedQuantity: verifiedQuantity ?? this.verifiedQuantity,
      isVerified: isVerified ?? this.isVerified,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get remaining quantity that needs to be verified
  int get remainingQuantity => requiredQuantity - (verifiedQuantity ?? 0);

  /// Check if all required quantity has been verified
  bool get isFullyVerified => remainingQuantity <= 0;

  /// Get verification progress as percentage
  double get verificationProgress {
    if (requiredQuantity == 0) return 1.0;
    return ((verifiedQuantity ?? 0) / requiredQuantity).clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'TaskPartsRequirement{partName: $partName, required: $requiredQuantity, verified: $verifiedQuantity, isVerified: $isVerified}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPartsRequirement &&
          runtimeType == other.runtimeType &&
          requirementId == other.requirementId;

  @override
  int get hashCode => requirementId.hashCode;
}
