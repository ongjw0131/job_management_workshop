/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:15:33
/// @modify date 2025-09-17 13:15:33
/// @desc [Customer: Data model representing a customer in the job management system.]
class Customer {
  final int customerId;
  final String name;
  final String phone;
  final String email;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleRegistration;
  final String? equipmentType;
  final String? equipmentSerial;

  Customer({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleRegistration,
    this.equipmentType,
    this.equipmentSerial,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'] is int
          ? json['customer_id'] as int
          : int.tryParse(json['customer_id'].toString()) ?? 0,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleRegistration: json['vehicle_registration'] as String?,
      equipmentType: json['equipment_type'] as String?,
      equipmentSerial: json['equipment_serial'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'name': name,
      'phone': phone,
      'email': email,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_registration': vehicleRegistration,
      'equipment_type': equipmentType,
      'equipment_serial': equipmentSerial,
    };
  }
}
