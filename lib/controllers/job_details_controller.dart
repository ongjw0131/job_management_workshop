/// @author [Chong Jun Xiang, Woo Keng Keong, Ong Jun Wei]
/// @email [chongjx-wm22@student.tarc.edu.my, wookk-wm22@student.tarc.edu.my, ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 00:32:18
/// @modify date 2025-09-17 00:32:18
/// @desc [JobDetailsController: Controller to manage job details, including loading task data, handling image uploads, and updating task status.]
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/helpers/job_timer_helper.dart';
import 'package:job_management_workshop/helpers/notification_display_helper.dart';
import 'package:job_management_workshop/models/customer.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/models/task_parts_requirement.dart';
import 'package:job_management_workshop/models/task_time_log.dart';
import 'package:job_management_workshop/repositories/customer_repository.dart';
import 'package:job_management_workshop/repositories/staff_repository.dart';
import 'package:job_management_workshop/repositories/task_repository.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:job_management_workshop/services/task_parts_requirement_service.dart';
import 'package:job_management_workshop/services/task_time_log_service.dart';
import 'package:job_management_workshop/services/timer_persistence_service.dart';
import 'package:job_management_workshop/services/job_timer_manager.dart';
import 'package:job_management_workshop/views/apps/bottom_navigation.dart';
import 'package:path_provider/path_provider.dart';

Future<Uint8List> _compressAndEncode(Map args) async {
  final Uint8List bytes = args['bytes'];
  final int maxWidth = args['maxWidth'];
  final int quality = args['quality'];
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  img.Image processed = decoded;
  if (processed.width > maxWidth) {
    processed = img.copyResize(processed, width: maxWidth);
  }
  final encoded = img.encodeJpg(processed, quality: quality);
  return Uint8List.fromList(encoded);
}

class JobDetailsController extends ChangeNotifier {
  final TaskTimeLogService _taskTimeLogService = TaskTimeLogService();

  final TaskPartsRequirementService _partsRequirementService =
      TaskPartsRequirementService();
  final TaskRepository _taskRepository = TaskRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final StaffRepository _staffRepository = StaffRepository();

  int? _lastLoadedTaskId;
  JobTimer? _jobTimer;

  JobDetailsController() {
    AppLogger.info('Created instance');
  }

  Task? task;
  Customer? customer;
  Staff? staff;
  List<TaskPartsRequirement> taskPartsRequirements = [];
  List<TaskTimeLog> timeLog = [];
  bool isLoading = false;
  bool isAccepting = false;
  bool isUploading = false;
  bool showImageError = false;
  bool showCheckboxError = false;
  bool isChecked = false;
  List<String> images = [];

  // Parts verification helpers
  int get totalRequiredPartsQuantity => taskPartsRequirements.fold(
        0,
        (sum, r) => sum + r.requiredQuantity,
      );

  int get totalVerifiedPartsQuantity => taskPartsRequirements.fold(
        0,
        (sum, r) => sum + (r.verifiedQuantity ?? 0),
      );

  double get partsVerificationProgress => totalRequiredPartsQuantity == 0
      ? 1.0
      : totalVerifiedPartsQuantity / totalRequiredPartsQuantity;

  bool get areAllPartsVerified => partsVerificationProgress >= 1.0;

  // Timer management
  JobTimer? get jobTimer => _jobTimer;

  void initializeTimer() async {
    if (_jobTimer == null && task != null) {
      final manager = JobTimerManager();
      _jobTimer = await manager.getOrCreateTimer(
        taskId: task!.taskId,
        staffId: task!.staffId,
      );
      _jobTimer!.onTick = (t) {
        // persistence handled by manager listener already
      };
      if (kDebugMode) {
        AppLogger.info('Timer ready via manager for task ${task!.taskId}');
      }
      // Ensure external listener added only once
      _jobTimer!.removeListener(_onTimerChanged);
      _jobTimer!.addListener(_onTimerChanged);
      _jobTimer!.resumeTickerIfNeeded();
      notifyListeners();
    }
  }

  void _onTimerChanged() {
    // Save timer state whenever it changes
    if (_jobTimer != null && task != null) {
      TimerPersistenceService.saveTimerState(task!.taskId, _jobTimer!);
    }
    notifyListeners();
  }

  void disposeTimer() {
    // Do NOT dispose underlying timer to allow dashboard continuity
    _jobTimer?.removeListener(_onTimerChanged);
    _jobTimer = null; // Manager retains ownership
  }

  Future<void> loadTaskById(int taskId) async {
    if (kDebugMode) {
      AppLogger.debug('loadTaskById called with taskId: $taskId');
    }
    _lastLoadedTaskId = taskId;
    isLoading = true;
    notifyListeners();
    try {
      // Load task details
      final taskData = await _taskRepository.getTaskById(taskId);
      if (_lastLoadedTaskId != taskId) return;
      if (kDebugMode) {
        AppLogger.debug('Ignoring stale load for taskId: $taskId');
      }
      task = taskData;
      if (kDebugMode) {
        AppLogger.info('Loaded task: ${task?.taskId}, status: ${task?.status}');
      }

      // Initialize timer for accepted/assigned tasks
      if (task != null &&
          (task!.status == TaskStatus.accepted ||
              task!.status == TaskStatus.assigned)) {
        initializeTimer();
        if (kDebugMode) {
          AppLogger.info('Timer initialized for task ${task!.taskId}');
        }
      } else {
        disposeTimer();
      }

      // Load customer details
      final customerData = await _customerRepository.getCustomerById(
        taskData.customerId,
      );
      if (_lastLoadedTaskId != taskId) return;
      customer = customerData;
      if (kDebugMode) {
        AppLogger.info('Loaded customer: ${customer?.name}');
      }
      // Load staff details
      final staffData = await _staffRepository.getStaffById(task!.staffId);
      if (_lastLoadedTaskId != taskId) return;
      staff = staffData;
      if (kDebugMode) {
        AppLogger.info('Loaded staff: ${staff?.email}');
      }
      if (_lastLoadedTaskId != taskId) return;

      // Load task parts requirements
      final partsRequirementsData = await _partsRequirementService
          .getTaskPartsRequirementsByTaskId(task!.taskId);
      if (_lastLoadedTaskId != taskId) return;
      taskPartsRequirements = partsRequirementsData;
      if (kDebugMode) {
        AppLogger.info(
          'Loaded ${taskPartsRequirements.length} parts requirements',
        );
      }

      // Load task time logs via TaskTimeLogService
      await _loadMergedTimeLogs();
      if (kDebugMode) {
        AppLogger.info('timeLog loaded: ${timeLog.length} entries');
        for (final log in timeLog) {
          AppLogger.debug(
            'log: ${log.action} at ${log.timestamp} (${log.duration})',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading job details: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMergedTimeLogs() async {
    if (task == null) return;
    try {
      final remote = await _taskTimeLogService.getTaskTimeLogsByTaskId(
        task!.taskId,
      );
      final local = await _taskTimeLogService.getLocalTaskTimeLogsByTaskId(
        task!.taskId,
      );
      // Merge by composite key (action + timestamp ISO second) to avoid duplicates
      final map = <String, TaskTimeLog>{};
      for (final log in [...remote, ...local]) {
        final key = '${log.action}_${log.timestamp.toIso8601String()}';
        map[key] = log; // local may overwrite remote identical entry, fine
      }
      final merged = map.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      timeLog = merged;
    } catch (e) {
      AppLogger.error('Failed merging time logs: $e');
    }
  }

  /// Refresh parts requirements data
  Future<void> refreshPartsRequirements() async {
    if (task == null) return;
    try {
      final partsRequirementsData = await _partsRequirementService
          .getTaskPartsRequirementsByTaskId(task!.taskId);
      taskPartsRequirements = partsRequirementsData;
      notifyListeners();
      if (kDebugMode) {
        AppLogger.info(
          'Refreshed ${taskPartsRequirements.length} parts requirements',
        );
      }
    } catch (e) {
      AppLogger.error('Error refreshing parts requirements: $e');
    }
  }

  Future<List<String>> get getRepairImageFromStorage async {
    if (task == null || task!.repairImagePath.isEmpty) return [];
    final client = await SupabaseService.getSafeClient();
    return task!.repairImagePath
        .where((p) => p.trim().isNotEmpty)
        .map((p) => client.storage.from('ImageBucket').getPublicUrl(p))
        .toList();
  }

  Future<List<String>> get getUploadImageFromStorage async {
    if (task == null || task!.uploadImagePath.isEmpty) return [];
    final client = await SupabaseService.getSafeClient();
    return task!.uploadImagePath
        .where((p) => p.trim().isNotEmpty)
        .map((p) => client.storage.from('ImageBucket').getPublicUrl(p))
        .toList();
  }

  Future<String> get getSignatureImageFromStorage async {
    if (task == null || task!.signaturePath == null) return '';
    final client = await SupabaseService.getSafeClient();
    return client.storage
        .from('SignatureBucket')
        .getPublicUrl(task!.signaturePath!);
  }

  Future<bool> acceptTaskById(int taskId, {BuildContext? context}) async {
    isAccepting = true;
    notifyListeners();
    try {
      final result = await _taskRepository.updateTaskStatus(
        taskId,
        TaskStatus.accepted,
      );
      if (result) {
        await loadTaskById(taskId);

        // Start the timer when job is accepted
        await _startTimerForAcceptedTask();

        // Show pop-up notification
        if (context != null && context.mounted) {
          _showJobAcceptedPopup(context);
        }

        return true;
      } else {
        if (kDebugMode) {
          AppLogger.error('Error accepting task');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Unexpected error in acceptTaskById: $e');
      }
      return false;
    } finally {
      isAccepting = false;
      notifyListeners();
    }
  }

  /// Start timer for accepted task
  Future<void> _startTimerForAcceptedTask() async {
    if (task == null) return;
    final manager = JobTimerManager();
    _jobTimer ??= await manager.getOrCreateTimer(
      taskId: task!.taskId,
      staffId: task!.staffId,
    );
    if (!_jobTimer!.isRunning) {
      AppLogger.info('Starting timer for accepted task: ${task!.taskId}');
      _jobTimer!.startTimer();
    }
    await TimerPersistenceService.saveTimerState(task!.taskId, _jobTimer!);
    notifyListeners();
  }

  /// Show pop-up notification when job is accepted
  void _showJobAcceptedPopup(BuildContext context) {
    if (task == null) return;

    NotificationDisplayHelper.showJobAcceptedNotification(context, task!.title);
  }

  void loadImagesFromTask() {
    loadImagesFromTaskAsync(_lastLoadedTaskId);
  }

  Future<void> loadImagesFromTaskAsync(int? taskId) async {
    images = [];
    final uploadImages = await getUploadImageFromStorage;
    images.addAll(uploadImages);
    if (taskId != null) {
      final cached = await _listCachedImagesForTask(taskId);
      images.addAll(cached);
    }
    notifyListeners();
  }

  Future<String> _cachePickedFile(XFile picked, int taskId) async {
    final dir = await _taskRepository.createCacheDirForTask(taskId);
    final original = File(picked.path);
    final filename = picked.path.split(Platform.pathSeparator).last;
    final targetPath =
        '${dir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$filename';
    try {
      final bytes = await original.readAsBytes();
      final compressed = await compute(_compressAndEncode, {
        'bytes': bytes,
        'maxWidth': 1920,
        'quality': 80,
      });
      final out = File(targetPath);
      await out.writeAsBytes(compressed, flush: true);
      try {
        if (await original.exists() && original.path != out.path) {
          await original.delete();
        }
      } catch (_) {}

      return out.path;
    } catch (_) {
      final copied = await original.copy(targetPath);
      try {
        if (await original.exists() && original.path != copied.path) {
          await original.delete();
        }
      } catch (_) {}

      return copied.path;
    }
  }

  Future<List<String>> _listCachedImagesForTask(int taskId) async {
    final dir = await _taskRepository.createCacheDirForTask(taskId);
    if (!await dir.exists()) return [];
    final entries = await dir.list().toList();
    return entries.whereType<File>().map((f) => f.path).toList();
  }

  Future<void> _cleanupPickerCache() async {
    try {
      final base = await getTemporaryDirectory();
      final entries = base.listSync();
      for (final e in entries) {
        final path = e.path;
        if (path.contains(Task.cacheFolderName)) continue;
        try {
          if (e is File) {
            final p = path.toLowerCase();
            if (p.endsWith('.jpg') ||
                p.endsWith('.jpeg') ||
                p.endsWith('.png') ||
                p.endsWith('.webp')) {
              try {
                await e.delete();
              } catch (_) {}
            }
          } else if (e is Directory) {
            final children = e.listSync();
            var containsImage = false;
            for (final c in children) {
              final cp = c.path.toLowerCase();
              if (cp.endsWith('.jpg') ||
                  cp.endsWith('.jpeg') ||
                  cp.endsWith('.png') ||
                  cp.endsWith('.webp')) {
                containsImage = true;
                break;
              }
            }
            if (containsImage || children.isEmpty) {
              try {
                await e.delete(recursive: true);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> uploadImages(List<XFile> pickedFiles, int taskId) async {
    isUploading = true;
    showImageError = false;
    notifyListeners();
    try {
      for (final picked in pickedFiles) {
        final cachedPath = await _cachePickedFile(picked, taskId);
        images.add(cachedPath);
        notifyListeners();
      }
      await loadImagesFromTaskAsync(taskId);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> pickImages(int taskId, BuildContext context) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;
    await uploadImages(pickedFiles, taskId);
    if (!isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images uploaded successfully.')),
      );
    }
  }

  Future<void> pickImageFromCamera(int taskId, BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    await uploadImages([pickedFile], taskId);
    if (!isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully.')),
      );
    }
  }

  Future<void> removeImage(int index, int taskId, BuildContext context) async {
    isUploading = true;
    notifyListeners();
    final imgPath = images[index];
    try {
      if (!imgPath.startsWith('http')) {
        final f = File(imgPath);
        if (await f.exists()) {
          await f.delete();
        }
      }
      images.removeAt(index);
      await _cleanupPickerCache();

      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image removed successfully.')),
      );
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> resetImagesAndCheckbox(int taskId, BuildContext context) async {
    isChecked = false;
    isUploading = true;
    notifyListeners();
    for (final imgPath in List<String>.from(images)) {
      if (!imgPath.startsWith('http')) {
        final f = File(imgPath);
        if (await f.exists()) await f.delete();
      }
    }
    try {
      final dir = await _taskRepository.createCacheDirForTask(taskId);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}

    await _cleanupPickerCache();
    await loadTaskById(taskId);
    await loadImagesFromTaskAsync(taskId);
    isUploading = false;
    notifyListeners();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All images deleted and checkbox reset.')),
    );
  }

  Future<void> _uploadCachedImagesAndSave(int taskId) async {
    // Logging start of method
    AppLogger.info('Start for taskId $taskId');
    if (task == null || task!.taskId != taskId) {
      await loadTaskById(taskId);
    }
    final cachedImageList = await _listCachedImagesForTask(taskId);
    if (cachedImageList.isEmpty) return;

    final existing = task?.uploadImagePath ?? [];
    final merged = List<String>.from(existing)..addAll(cachedImageList);
    final response = await _taskRepository.updateUploadImagePath(
      taskId,
      merged,
    );
    if (response) {
      AppLogger.info('Updated uploadImagePath for task $taskId in Supabase');
    } else {
      AppLogger.error(
        'Failed to update uploadImagePath for task $taskId in Supabase',
      );
    }
    AppLogger.info('Completed for taskId $taskId');
  }

  Future<bool> completeTask(int taskId) async {
    bool hasError = false;
    // Enforce parts verification for tasks that have requirements
    if (taskPartsRequirements.isNotEmpty && !areAllPartsVerified) {
      hasError = true;
      AppLogger.warning('Completion blocked: parts not fully verified');
    }
    if (images.isEmpty) {
      showImageError = true;
      hasError = true;
    }
    if (!isChecked) {
      showCheckboxError = true;
      hasError = true;
    }
    notifyListeners();
    if (hasError) return false;
    isUploading = true;
    notifyListeners();
    try {
      // Stop the timer if it's running
      if (_jobTimer != null && _jobTimer!.isRunning) {
        _jobTimer!.stopTimer(); // Completion logic still allowed
      }

      await _taskRepository.updateTaskStatus(taskId, TaskStatus.completed);
      await _uploadCachedImagesAndSave(taskId);

      // Clear timer persistence after task completion to remove active timer notification
      if (task != null) {
        await TimerPersistenceService.clearTimerState(taskId, task!.staffId);
        if (kDebugMode) {
          AppLogger.info(
            'Cleared timer persistence for completed task $taskId (staff: ${task!.staffId})',
          );
        }
      }

      await loadTaskById(taskId);
      await loadImagesFromTaskAsync(taskId);
      return true;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  void toggleCheckbox(bool? value) {
    isChecked = value ?? false;
    if (isChecked) showCheckboxError = false;
    notifyListeners();
  }

  void clearImageError() {
    showImageError = false;
    notifyListeners();
  }

  Future<void> onComplete(int taskId, BuildContext context) async {
    if (taskPartsRequirements.isNotEmpty && !areAllPartsVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please verify all required parts before completing (Progress: ${totalVerifiedPartsQuantity}/${totalRequiredPartsQuantity}).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Mark this task as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await completeTask(taskId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task marked as completed!')),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Required: Ensure an image is uploaded and confirmation box is checked.',
          ),
        ),
      );
    }
  }

  Future<void> loadTaskAndImages(int taskId) async {
    await loadTaskById(taskId);
    await loadImagesFromTaskAsync(taskId);
  }

  @override
  void dispose() {
    disposeTimer();
    super.dispose();
  }
}
