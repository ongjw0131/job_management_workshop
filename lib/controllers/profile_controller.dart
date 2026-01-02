/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:10:59
/// @modify date 2025-09-17 13:10:59
/// @desc [ProfileController: Manages user profile state and editing logic]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/repositories/staff_repository.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

class ProfileController extends ChangeNotifier {
  final StaffRepository _staffRepository = StaffRepository();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  bool isEditingFirstName = false;
  bool isEditingLastName = false;
  bool isEditingPhone = false;
  bool isEditingAddress = false;
  Staff? profile;

  Future<Staff?> fetchProfile(String staffId) async {
    profile = await _staffRepository.getStaffById(staffId);
    return profile;
  }

  void startEdit(String field, String value) {
    // Reset all editing states and controllers to default values
    isEditingFirstName = false;
    isEditingLastName = false;
    isEditingPhone = false;
    isEditingAddress = false;
    if (profile != null) {
      firstNameController.text = profile!.firstName;
      lastNameController.text = profile!.lastName;
      // For phone, strip leading zero for UI
      final rawPhone = profile!.phoneNumber ?? '';
      phoneController.text = rawPhone.startsWith('0')
          ? rawPhone.substring(1)
          : rawPhone;
      addressController.text = profile!.address ?? '';
    }
    // Activate only the selected field
    if (field == 'first') {
      isEditingFirstName = true;
      firstNameController.text = value;
    } else if (field == 'last') {
      isEditingLastName = true;
      lastNameController.text = value;
    } else if (field == 'phone') {
      isEditingPhone = true;
      // Also strip leading zero from value for UI
      phoneController.text = value.startsWith('0') ? value.substring(1) : value;
    } else if (field == 'address') {
      isEditingAddress = true;
      addressController.text = value;
    }
    notifyListeners();
  }

  // Malaysia phone number validation
  bool isValidMalaysiaPhone(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'\s|-'), '');
    // Only accept numbers starting with '1' and with 9 or 10 digits
    final regex = RegExp(r'^(1\d{8,9})$');
    return regex.hasMatch(cleaned);
  }

  // First name validation: cannot exceed 5 words
  bool isValidFirstName(String firstName) {
    return firstName.length <= 5;
  }

  Future<bool> saveEdit(String staffId, String field) async {
    final updateData = <String, dynamic>{};
    if (field == 'first') {
      final firstName = firstNameController.text.trim();
      if (!isValidFirstName(firstName)) {
        AppLogger.warning('First name cannot exceed 5 words');
        return false;
      }
      updateData['first_name'] = firstName;
      isEditingFirstName = false;
    } else if (field == 'last') {
      updateData['last_name'] = lastNameController.text.trim();
      isEditingLastName = false;
    } else if (field == 'phone') {
      var phone = phoneController.text.trim();
      // Add leading zero for backend storage
      if (!phone.startsWith('0')) {
        phone = '0$phone';
      }
      final phoneRegex = RegExp(r'^0?1\d{8,9}$');
      if (!phoneRegex.hasMatch(phone)) {
        AppLogger.warning(
          'Invalid phone number: must be 0 followed by 1 and 8-9 digits',
        );
        return false;
      }
      updateData['phone_number'] = phone;
      isEditingPhone = false;
    } else if (field == 'address') {
      updateData['address'] = addressController.text.trim();
      isEditingAddress = false;
    } else {
      AppLogger.warning('saveEdit called with unknown field: $field');
      return false;
    }
    try {
      final updatedStaffData = profile?.copyWith(
        firstName: field == 'first' ? updateData['first_name'] : null,
        lastName: field == 'last' ? updateData['last_name'] : null,
        phoneNumber: field == 'phone' ? updateData['phone_number'] : null,
        address: field == 'address' ? updateData['address'] : null,
      );
      if (updatedStaffData == null) {
        AppLogger.error('No profile loaded to update');
        return false;
      }
      final response = await _staffRepository.updateStaff(updatedStaffData);
      profile = response;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error("Error updating profile: $e");
      return false;
    }
  }

  // Reset all editing states and controllers
  void resetEditing() {
    isEditingFirstName = false;
    isEditingLastName = false;
    isEditingPhone = false;
    isEditingAddress = false;
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    addressController.clear();
    notifyListeners();
  }

  void cancelEdit(String field) {
    if (field == 'first') {
      isEditingFirstName = false;
      if (profile != null) firstNameController.text = profile!.firstName;
    } else if (field == 'last') {
      isEditingLastName = false;
      if (profile != null) lastNameController.text = profile!.lastName;
    } else if (field == 'phone') {
      isEditingPhone = false;
      if (profile != null) phoneController.text = profile!.phoneNumber ?? '';
    } else if (field == 'address') {
      isEditingAddress = false;
      if (profile != null) addressController.text = profile!.address ?? '';
    }
    notifyListeners();
  }

  Future<String> getProfileImage() async {
    if (profile == null || profile!.profileImage == null) return '';
    final client = await SupabaseService.getSafeClient();
    return client.storage
        .from('ImageBucket')
        .getPublicUrl(profile!.profileImage!);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
