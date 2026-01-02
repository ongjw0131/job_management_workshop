import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/repositories/task_repository.dart';
import 'package:job_management_workshop/views/apps/bottom_navigation.dart';
import 'package:signature/signature.dart';

class SignaturePageController extends ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2,
    exportBackgroundColor: Colors.white,
  );

  bool isUploading = false;

  // Agreement state used by the UI.
  bool agreed = false;
  bool viewedTerms = false;

  SignaturePageController() {
    signatureController.addListener(_onSignatureChanged);
  }

  void _onSignatureChanged() => notifyListeners();

  void setAgreed(bool value) {
    agreed = value;
    notifyListeners();
  }

  void markViewedAndMaybeAccept(bool accepted) {
    viewedTerms = true;
    if (accepted) agreed = true;
    notifyListeners();
  }

  bool get hasSignature => signatureController.isNotEmpty;

  bool get canSubmit => !isUploading && agreed && hasSignature;

  void clearSignature() {
    signatureController.clear();
    notifyListeners();
  }

  Future<Uint8List?> exportSignature() async {
    if (signatureController.isNotEmpty) {
      return await signatureController.toPngBytes();
    }
    return null;
  }

  Future<void> submitSignature(BuildContext context, int taskId) async {
    isUploading = true;
    notifyListeners();
    try {
      final image = await exportSignature();
      if (image == null) throw Exception('No signature');
      AppLogger.info('SignaturePageController.submitSignature start');

      // 1) Cache signature locally under task cache dir
      final dir = await _taskRepository.createCacheDirForTask(taskId);
      final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(image, flush: true);

      // 2) Update local SQLite signature_path to point to cached file (so UI can show it)
      final localUpdated = await _taskRepository.updateSignaturePath(
        taskId,
        filePath,
      );
      if (!localUpdated) {
        AppLogger.error(
          'Failed to update local signature path for task $taskId',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature submitted and saved!')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => BottomNavigation(
            isDarkMode: false,
            onThemeToggle: (value) {},
            initialIndex: 1,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    signatureController.removeListener(_onSignatureChanged);
    signatureController.dispose();
    super.dispose();
  }
}
