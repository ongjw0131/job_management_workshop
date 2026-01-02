/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:18:00
/// @modify date 2025-09-17 13:18:00
/// @desc [VehiclePart: Model class representing a vehicle part with JSON serialization/deserialization.]
library;

class VehiclePart {
  final String partId;
  final String barcode;
  final String partName;
  final String? partNumber;
  final String? description;
  final String? category;
  final int stockQuantity;
  final double? unitPrice;
  final String? supplier;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehiclePart({
    required this.partId,
    required this.barcode,
    required this.partName,
    this.partNumber,
    this.description,
    this.category,
    this.stockQuantity = 0,
    this.unitPrice,
    this.supplier,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehiclePart.fromJson(Map<String, dynamic> json) {
    return VehiclePart(
      partId: json['part_id'] as String,
      barcode: json['barcode'] as String,
      partName: json['part_name'] as String,
      partNumber: json['part_number'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : null,
      supplier: json['supplier'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_id': partId,
      'barcode': barcode,
      'part_name': partName,
      'part_number': partNumber,
      'description': description,
      'category': category,
      'stock_quantity': stockQuantity,
      'unit_price': unitPrice,
      'supplier': supplier,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VehiclePart copyWith({
    String? partId,
    String? barcode,
    String? partName,
    String? partNumber,
    String? description,
    String? category,
    int? stockQuantity,
    double? unitPrice,
    String? supplier,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehiclePart(
      partId: partId ?? this.partId,
      barcode: barcode ?? this.barcode,
      partName: partName ?? this.partName,
      partNumber: partNumber ?? this.partNumber,
      description: description ?? this.description,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'VehiclePart{partId: $partId, barcode: $barcode, partName: $partName, stockQuantity: $stockQuantity}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiclePart && other.partId == partId;
  }

  @override
  int get hashCode => partId.hashCode;
}
