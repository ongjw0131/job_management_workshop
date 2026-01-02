/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:51:13
/// @modify date 2025-09-20 15:51:13
/// @desc [UploadButtonWidget: A reusable upload button with uploading state and error indication.]
library;

import 'package:flutter/material.dart';

class UploadButtonWidget extends StatelessWidget {
  final bool isUploading;
  final bool showError;
  final VoidCallback? onPressed;
  final String uploadingLabel;
  final String idleLabel;

  const UploadButtonWidget({
    super.key,
    required this.isUploading,
    required this.showError,
    required this.onPressed,
    this.uploadingLabel = 'Uploading...',
    this.idleLabel = 'Upload',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
          if (showError) return const BorderSide(color: Colors.red, width: 2);
          return null;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      onPressed: isUploading ? null : onPressed,
      icon: const Icon(Icons.upload),
      label: isUploading ? Text(uploadingLabel) : Text(idleLabel),
    );
  }
}
