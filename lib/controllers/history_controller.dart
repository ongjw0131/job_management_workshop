/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-16 14:52:16
/// @modify date 2025-09-16 14:52:16
/// @desc [HistoryController: Manages fetching and sorting of completed tasks for staff members.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart'; // Added for logging
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/repositories/task_repository.dart';
import 'package:pdf/widgets.dart' as pw;

class HistoryController {
  final TaskRepository _taskRepository = TaskRepository();

  bool _ascending = true;
  bool _showOnlyUnsigned = false;

  // Date range filters
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  bool get ascending => _ascending;

  bool get showOnlyUnsigned => _showOnlyUnsigned;

  DateTime? get startDateFilter => _startDateFilter;

  DateTime? get endDateFilter => _endDateFilter;

  void toggleSortOrder() {
    _ascending = !_ascending;
  }

  void toggleShowOnlyUnsigned() {
    _showOnlyUnsigned = !_showOnlyUnsigned;
  }

  // Update start date filter
  void updateStartDateFilter(DateTime? date) {
    _startDateFilter = date;
  }

  // Update end date filter
  void updateEndDateFilter(DateTime? date) {
    _endDateFilter = date;
  }

  Future<List<Task>> fetchCompletedTasks(String staffId) async {
    List<Task> completedTasks = await _taskRepository.getCompletedTask(
      staffId: staffId,
      ascending: _ascending,
    );
    if (_showOnlyUnsigned) {
      completedTasks = completedTasks
          .where((t) => t.signaturePath == null)
          .toList();
    }
    // Date range filter
    if (_startDateFilter != null) {
      completedTasks = completedTasks
          .where((t) => !t.deadline.isBefore(_startDateFilter!))
          .toList();
    }
    if (_endDateFilter != null) {
      completedTasks = completedTasks
          .where((t) => !t.deadline.isAfter(_endDateFilter!))
          .toList();
    }
    AppLogger.info('Done getting data from data provider: $completedTasks');
    return completedTasks;
  }

  Future<pw.Document> generateSignedHistoryPdf(List<Task> tasks) async {
    final pdf = pw.Document();
    final signedTasks = tasks
        .where((task) => task.signaturePath != null)
        .toList();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Signed History Tasks',
              style: pw.TextStyle(fontSize: 24),
            ),
          ),
          pw.Table.fromTextArray(
            headers: ['Title', 'Status', 'Deadline', 'Signed'],
            data: signedTasks
                .map(
                  (task) => [
                    task.title,
                    task.status.value,
                    task.deadline.toLocal().toString().split(' ')[0],
                    'Yes',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return pdf;
  }
}
