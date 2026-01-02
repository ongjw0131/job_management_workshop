/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 20:31:43
/// @modify date 2025-09-17 20:31:43
/// @desc [JobDetailsPage: Displays detailed information about a job task, including customer details, task status, images, and action buttons.]
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/job_details_controller.dart';
import 'package:job_management_workshop/helpers/date_helper.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/models/task_time_log.dart';
import 'package:job_management_workshop/views/customer_details_page.dart';
import 'package:job_management_workshop/views/sign_off_page.dart';
import 'package:job_management_workshop/views/upload_task_page.dart';
import 'package:job_management_workshop/widgets/display/customer_header_widget.dart';
import 'package:job_management_workshop/widgets/display/detail_row_widget.dart';
import 'package:job_management_workshop/widgets/display/image_grid_widget.dart';
import 'package:job_management_workshop/widgets/display/task_parts_requirement_widget.dart';
import 'package:job_management_workshop/widgets/timers/job_timer_widget.dart';

class JobDetailsPage extends StatefulWidget {
  final int taskId;

  const JobDetailsPage({super.key, required this.taskId});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late final JobDetailsController controller;

  @override
  void initState() {
    super.initState();
    controller = JobDetailsController();
    controller.addListener(_onControllerChanged);
    controller.loadTaskById(widget.taskId);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _onAcceptPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Accept this task?'),
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

    final success = await controller.acceptTaskById(
      widget.taskId,
      context: context,
    );
    if (!mounted) return;

    // Don't show the old SnackBar since the controller now handles the popup
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(success ? 'Task accepted' : 'Failed to accept task'),
    //     backgroundColor: success ? Colors.green : Colors.red,
    //   ),
    // );

    // Show error only if failed
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _loadImagesFromTask() {
    final task = controller.task;
    final isCompleted = task != null && task.status == TaskStatus.completed;
    final Future<List<String>> imageUrlsFuture = isCompleted
        ? Future.value(controller.getUploadImageFromStorage)
        : controller.getRepairImageFromStorage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCompleted ? 'Upload Images' : 'Repair Images',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<String>>(
            future: imageUrlsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final imageUrls = snapshot.data ?? [];
              if (imageUrls.isEmpty) {
                return const Center(child: Text('No images available'));
              }

              // Use the reusable ImageGridWidget in read-only mode. Use carousel
              // when there is exactly one image for nicer presentation, otherwise
              // use the horizontal list mode.
              return ImageGridWidget(
                images: imageUrls,
                mode: imageUrls.length == 1
                    ? ImageDisplayMode.carousel
                    : ImageDisplayMode.list,
                showRemove: false,
                emptyMessage: 'No images available',
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskId != -1 && controller.task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(
          child: Text(
            'Unable to load job details. Please select a valid task from the home page.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final task = controller.task;
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomerHeaderWidget(
                        customer: controller.customer,
                        onInfoPressed: () {
                          final customer = controller.customer;
                          if (customer != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerDetailsPage(customer: customer),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Customer details not available'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _loadImagesFromTask(),
                      const SizedBox(height: 12),
                      if (task != null) ...[
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DetailRowWidget(
                          label: 'Task ID',
                          value: task.taskId.toString(),
                        ),
                        DetailRowWidget(label: 'Order ID', value: task.orderId),
                        DetailRowWidget(
                          label: 'Description',
                          value: task.description,
                        ),
                        DetailRowWidget(
                          label: 'Assigned From',
                          value: DateHelper.toDateTimeString(task.createdAt),
                        ),
                        DetailRowWidget(
                          label: 'Status',
                          value: task.statusDisplayName,
                        ),

                        // Signature section for completed tasks
                        if (task.status == TaskStatus.completed &&
                            task.signaturePath != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Signature',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<String>(
                            future: controller.getSignatureImageFromStorage,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final imageUrl = snapshot.data ?? '';
                              if (imageUrl.isEmpty) {
                                return const Icon(Icons.broken_image, size: 50);
                              }
                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                height: 150,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ],
                      ] else
                        const Center(child: Text('Task not found')),

                      const SizedBox(height: 16),

                      // Timer widget for accepted/assigned tasks
                      if (task != null &&
                          (task.status == TaskStatus.accepted ||
                              task.status == TaskStatus.assigned) &&
                          controller.jobTimer != null) ...[
                        const Divider(),

                        // Required parts section
                        TaskPartsRequirementWidget(
                          requirements: controller.taskPartsRequirements,
                          task: task,
                          onRefresh: () =>
                              controller.refreshPartsRequirements(),
                        ),
                        const SizedBox(height: 16),

                        const Divider(),
                        const SizedBox(height: 16),
                        JobTimerWidget(
                          timer: controller.jobTimer!,
                          task: task,
                          showDetailedLog: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Time log and parts verification for completed tasks
                      if (task != null &&
                          task.status == TaskStatus.completed) ...[
                        const Divider(),

                        // Parts verification section for completed tasks
                        if (controller.taskPartsRequirements.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.verified, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Parts Verification',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TaskPartsRequirementWidget(
                            requirements: controller.taskPartsRequirements,
                            task: task,
                            onRefresh: () =>
                                controller.refreshPartsRequirements(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Time log section (always show on completed tasks)
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.history, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Time Log',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              controller.timeLog.isEmpty
                                  ? 'No entries'
                                  : '${controller.timeLog.length} entries',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: controller.timeLog.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      'No time log entries recorded.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                              : Scrollbar(
                                  thumbVisibility: true,
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: controller.timeLog.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final log = controller.timeLog.reversed
                                          .toList()[index];
                                      return _buildTimeLogEntry(log);
                                    },
                                  ),
                                ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Go Back'),
                            ),
                          ),
                          // only show Sign Off button if task is completed but not signed
                          if (task != null &&
                              task.status == TaskStatus.completed &&
                              task.signaturePath == null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SignOffPage(taskId: widget.taskId),
                                    ),
                                  );
                                },
                                child: const Text('Sign Off'),
                              ),
                            ),
                          ] else if (task != null &&
                              task.status == TaskStatus.accepted) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UploadTaskPage(taskId: widget.taskId),
                                    ),
                                  );
                                },
                                child: const Text('Submit'),
                              ),
                            ),
                          ] else if (task != null &&
                              !(task.status == TaskStatus.completed &&
                                  task.signaturePath != null)) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    controller.isAccepting ||
                                        (task.status == TaskStatus.accepted)
                                    ? null
                                    : _onAcceptPressed,
                                child: controller.isAccepting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Accept'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTimeLogEntry(TaskTimeLog log) {
    IconData icon;
    Color color;

    switch (log.action.toLowerCase()) {
      case 'start':
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case 'pause':
        icon = Icons.pause;
        color = Colors.orange;
        break;
      case 'resume':
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case 'stop':
      case 'complete':
        icon = Icons.stop;
        color = Colors.red;
        break;
      case 'reset':
        icon = Icons.refresh;
        color = Colors.blue;
        break;
      default:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action.substring(0, 1).toUpperCase() +
                      log.action.substring(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (log.duration != null)
                  Text(
                    'Duration: ${_formatDuration(log.duration!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateHelper.toDateTimeString(log.timestamp).split(' ').last,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
              Text(
                DateHelper.toDateTimeString(log.timestamp).split(' ').first,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
