/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 14:53:45
/// @modify date 2025-09-21 14:53:45
/// @desc [HistoryPage: Displays completed tasks with filtering, sorting, and PDF export functionality.]]
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/history_controller.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/views/apps/sidebar.dart';
import 'package:job_management_workshop/views/job_details_page.dart';
import 'package:job_management_workshop/widgets/display/task_list_item_widget.dart';
import 'package:job_management_workshop/widgets/inputs/date_filter_field_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeToggle;

  const HistoryPage({super.key, this.isDarkMode = false, this.onThemeToggle});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController();
  }

  void _handleSortToggle() {
    setState(() {
      _controller.toggleSortOrder();
    });
  }

  void _handleShowUnsignedToggle() {
    setState(() {
      _controller.toggleShowOnlyUnsigned();
    });
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
        title: const Text("History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: () async {
              final tasks = await _controller.fetchCompletedTasks(
                sessionProvider.staffId!,
              );
              final pdf = await _controller.generateSignedHistoryPdf(tasks);
              final bytes = await pdf.save();
              String downloadsPath;
              if (Platform.isWindows) {
                final userProfile = Platform.environment['USERPROFILE'];
                downloadsPath = userProfile != null
                    ? '$userProfile\\Downloads'
                    : (await getApplicationDocumentsDirectory()).path;
              } else if (Platform.isAndroid) {
                downloadsPath = '/storage/emulated/0/Download';
              } else {
                downloadsPath = (await getApplicationDocumentsDirectory()).path;
              }
              final filePath =
                  '$downloadsPath/history_tasks_${DateTime.now().millisecondsSinceEpoch}.pdf';
              final file = File(filePath);
              await file.writeAsBytes(bytes);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF downloaded: $filePath')),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              _controller.ascending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _controller.ascending
                ? 'Sort Descending'
                : 'Sort Ascending',
            onPressed: _handleSortToggle,
          ),
          IconButton(
            icon: Icon(
              _controller.showOnlyUnsigned
                  ? Icons.edit_outlined
                  : Icons.edit_off_outlined,
            ),
            tooltip: _controller.showOnlyUnsigned
                ? 'Show All Tasks'
                : 'Show Only Unsigned Tasks',
            onPressed: _handleShowUnsignedToggle,
          ),
        ],
      ),
      drawer: AppSidebar(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle ?? (_) {},
        staffId: sessionProvider.staffId ?? '',
        staffName: sessionProvider.staffName ?? '',
      ),
      body: sessionProvider.staffId == null
          ? const Center(child: Text("⚠ No staff ID found"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DateFilterFieldWidget(
                          label: 'Start Date',
                          date: _controller.startDateFilter,
                          onDateChanged: (picked) {
                            setState(() {
                              _controller.updateStartDateFilter(picked);
                            });
                          },
                          onClear: () {
                            setState(() {
                              _controller.updateStartDateFilter(null);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateFilterFieldWidget(
                          label: 'End Date',
                          date: _controller.endDateFilter,
                          onDateChanged: (picked) {
                            setState(() {
                              _controller.updateEndDateFilter(picked);
                            });
                          },
                          onClear: () {
                            setState(() {
                              _controller.updateEndDateFilter(null);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Task>>(
                    future: _controller.fetchCompletedTasks(
                      sessionProvider.staffId!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("❌ Error: ${snapshot.error}"),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("No completed tasks yet."),
                        );
                      }
                      final tasks = snapshot.data!;
                      return ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskListItemWidget(
                            task: task,
                            leadingIcon: Icons.assignment_turned_in,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JobDetailsPage(taskId: task.taskId),
                                ),
                              );
                              setState(() {});
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
