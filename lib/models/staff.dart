/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:12:34
/// @modify date 2025-09-17 13:12:34
/// @desc [Staff: Data model representing a staff member in the job management system.]
class Staff {
  final String staffId;
  final String password;
  final String firstName;
  final String lastName;
  final String? role;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Staff({
    required this.staffId,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.role,
    this.email,
    this.phoneNumber,
    this.address,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      staffId: json['staff_id'] as String,
      password: json['password'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      role: json['role'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
      profileImage: json['profile_image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'profile_image': profileImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Staff copyWith({
    String? staffId,
    String? password,
    String? firstName,
    String? lastName,
    String? role,
    String? email,
    String? phoneNumber,
    String? address,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      staffId: staffId ?? this.staffId,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
