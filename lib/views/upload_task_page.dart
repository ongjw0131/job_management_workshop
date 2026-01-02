/// @author [Woo Keng Keong, Chong Jun Xiang]
/// @email [wookk-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:53:47
/// @modify date 2025-09-20 15:53:47
/// @desc [UploadTaskPage: Page for uploading images and confirming task completion.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/job_details_controller.dart';
import 'package:job_management_workshop/widgets/display/image_grid_widget.dart';
import 'package:job_management_workshop/widgets/inputs/action_buttons_row_widget.dart';
import 'package:job_management_workshop/widgets/inputs/confirm_checkbox_widget.dart';
import 'package:job_management_workshop/widgets/inputs/upload_button_widget.dart';

class UploadTaskPage extends StatefulWidget {
  final int taskId;

  const UploadTaskPage({super.key, required this.taskId});

  @override
  State<UploadTaskPage> createState() => _UploadTaskPageState();
}

class _UploadTaskPageState extends State<UploadTaskPage> {
  late final JobDetailsController controller;

  @override
  void initState() {
    super.initState();
    controller = JobDetailsController();
    controller.addListener(_onControllerChanged);
    controller.loadTaskAndImages(widget.taskId);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.pickImages(widget.taskId, context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.pickImageFromCamera(widget.taskId, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final task = controller.task;
    if (task == null) {
      return const Scaffold(body: Center(child: Text('Task not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ImageGridWidget(
                images: controller.images,
                onRemove: (index) =>
                    controller.removeImage(index, widget.taskId, context),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UploadButtonWidget(
                    isUploading: controller.isUploading,
                    showError: controller.showImageError,
                    onPressed: _showImageSourceActionSheet,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(task.description ?? 'No description'),
              const SizedBox(height: 16),
              ConfirmCheckboxWidget(
                value: controller.isChecked,
                onChanged: (v) => controller.toggleCheckbox(v),
                showError: controller.showCheckboxError,
              ),
              const SizedBox(height: 16),
              ActionButtonsRowWidget(
                onReset: () =>
                    controller.resetImagesAndCheckbox(widget.taskId, context),
                onComplete: () => controller.onComplete(widget.taskId, context),
                resetDisabled: false,
                completeDisabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
