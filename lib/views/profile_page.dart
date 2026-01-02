/// @author [Liew Kai Quan, Chong Jun Xiang]
/// @email [liewkq-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 13:13:09
/// @modify date 2025-09-17 13:13:09
/// @desc [ProfilePage: Staff profile page with editable fields and profile picture display.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/profile_controller.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/widgets/profile/info_tile_widgets.dart';
import 'package:job_management_workshop/widgets/profile/profile_avatar_widget.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../views/apps/sidebar.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeToggle;

  const ProfilePage({super.key, this.isDarkMode = false, this.onThemeToggle});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController profileController;

  @override
  void initState() {
    super.initState();
    profileController = ProfileController();
  }

  @override
  void dispose() {
    profileController.resetEditing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("👤 Profile"),
      ),
      drawer: AppSidebar(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle ?? (_) {},
        staffId: sessionProvider.staffId ?? '',
        staffName: sessionProvider.staffName ?? '',
      ),
      body: sessionProvider.staffId == null
          ? const Center(child: Text("⚠ No staff ID found"))
          : FutureBuilder<Staff?>(
              future: profileController.fetchProfile(sessionProvider.staffId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("❌ Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("⚠ Profile not found"));
                }
                final Staff staff = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    (staff.profileImage != null &&
                            staff.profileImage!.trim().isNotEmpty)
                        ? FutureBuilder<String>(
                            future: profileController.getProfileImage(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ProfileAvatarWidget();
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const ProfileAvatarWidget();
                              }
                              return ProfileAvatarWidget(
                                imageUrl: snapshot.data!,
                              );
                            },
                          )
                        : const ProfileAvatarWidget(),
                    const SizedBox(height: 16),
                    // Use EditableInfoTileWidget for editable fields, InfoTileWidget for static fields
                    EditableInfoTileWidget(
                      label: "First Name",
                      value: staff.firstName,
                      isEditing: profileController.isEditingFirstName,
                      controller: profileController.firstNameController,
                      onEdit: () {
                        profileController.startEdit('first', staff.firstName);
                        setState(() {});
                      },
                      onSave: () async {
                        final firstName = profileController
                            .firstNameController
                            .text
                            .trim();
                        final isValid = profileController.isValidFirstName(
                          firstName,
                        );
                        if (!isValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '❌ First name cannot exceed 5 words.',
                              ),
                            ),
                          );
                          setState(() {});
                          return;
                        }
                        final success = await profileController.saveEdit(
                          staff.staffId,
                          'first',
                        );
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ First name update failed'),
                            ),
                          );
                        } else {
                          // Refresh session provider so sidebar and other consumers
                          // of SessionProvider reflect the updated name.
                          await sessionProvider.refreshStaffFromLocal();
                        }
                        setState(() {});
                      },
                      hintText: 'Up to 5 words',
                      errorText:
                          profileController.isEditingFirstName &&
                              profileController
                                  .firstNameController
                                  .text
                                  .isNotEmpty &&
                              !profileController.isValidFirstName(
                                profileController.firstNameController.text,
                              )
                          ? 'First name cannot exceed 5 words'
                          : null,
                      cancelButton: profileController.isEditingFirstName
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Cancel edit',
                              onPressed: () {
                                profileController.cancelEdit('first');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    EditableInfoTileWidget(
                      label: "Last Name",
                      value: staff.lastName,
                      isEditing: profileController.isEditingLastName,
                      controller: profileController.lastNameController,
                      onEdit: () {
                        profileController.startEdit('last', staff.lastName);
                        setState(() {});
                      },
                      onSave: () async {
                        final success = await profileController.saveEdit(
                          staff.staffId,
                          'last',
                        );
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Last name update failed'),
                            ),
                          );
                        } else {
                          await sessionProvider.refreshStaffFromLocal();
                        }
                        setState(() {});
                      },
                      hintText: 'Enter last name',
                      cancelButton: profileController.isEditingLastName
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Cancel edit',
                              onPressed: () {
                                profileController.cancelEdit('last');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    InfoTileWidget(label: "Role", value: staff.role),
                    InfoTileWidget(label: "Email", value: staff.email),
                    EditableInfoTileWidget(
                      label: "Phone",
                      value: staff.phoneNumber ?? '',
                      isEditing: profileController.isEditingPhone,
                      controller: profileController.phoneController,
                      onEdit: () {
                        profileController.startEdit(
                          'phone',
                          staff.phoneNumber ?? '',
                        );
                        setState(() {});
                      },
                      onSave: () async {
                        final phone = profileController.phoneController.text
                            .trim();
                        final isValid = profileController.isValidMalaysiaPhone(
                          phone,
                        );
                        if (!isValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '❌ Invalid Malaysia phone number. Must start with 1 and be 8-9 digits.',
                              ),
                            ),
                          );
                          setState(() {});
                          return;
                        }
                        final success = await profileController.saveEdit(
                          staff.staffId,
                          'phone',
                        );
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Phone number update failed'),
                            ),
                          );
                        } else {
                          await sessionProvider.refreshStaffFromLocal();
                        }
                        setState(() {});
                      },
                      hintText: 'e.g. 123456789 (start with 1, 8-9 digits)',
                      errorText:
                          profileController.isEditingPhone &&
                              profileController
                                  .phoneController
                                  .text
                                  .isNotEmpty &&
                              !profileController.isValidMalaysiaPhone(
                                profileController.phoneController.text,
                              )
                          ? 'Phone number must start with 1 and be 8-9 digits'
                          : null,
                      prefix: const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: Text(
                          '+60',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      cancelButton: profileController.isEditingPhone
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Cancel edit',
                              onPressed: () {
                                profileController.cancelEdit('phone');
                                setState(() {});
                              },
                            )
                          : null,
                      keyboardType: TextInputType.phone,
                    ),
                    EditableInfoTileWidget(
                      label: "Address",
                      value: staff.address ?? '',
                      isEditing: profileController.isEditingAddress,
                      controller: profileController.addressController,
                      onEdit: () {
                        profileController.startEdit(
                          'address',
                          staff.address ?? '',
                        );
                        setState(() {});
                      },
                      onSave: () async {
                        final success = await profileController.saveEdit(
                          staff.staffId,
                          'address',
                        );
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Address update failed'),
                            ),
                          );
                        } else {
                          await sessionProvider.refreshStaffFromLocal();
                        }
                        setState(() {});
                      },
                      hintText: 'Enter address',
                      cancelButton: profileController.isEditingAddress
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Cancel edit',
                              onPressed: () {
                                profileController.cancelEdit('address');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
