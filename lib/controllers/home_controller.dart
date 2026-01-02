/// @author [Chong Jun Xiang, Liew Kai Quan]
/// @email [chongjx-wm22@student.tarc.edu.my, liewkq-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 16:00:17
/// @modify date 2025-09-11 16:00:17
/// @desc [HomeController: Handles business logic for the Home page, including fetching, filtering, searching, and sorting tasks.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart'; // Added for logging
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/repositories/task_repository.dart';

class HomeController {
  final TaskRepository _taskRepository = TaskRepository();

  Future<List<Task>> fetchAssignedTasks(String staffId) async {
    try {
      return await _taskRepository.getAssignedTask(staffId);
    } catch (e) {
      // Log error and return empty list
      AppLogger.error('Error fetching tasks: $e');
      return [];
    }
  }

  List<Task> filterTasks(
    List<Task> tasks, {
    String search = '',
    String status = 'All',
    DateTime? dueDate,
    String sort = 'Default',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Filter by search query (title)
    var filtered = tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(
        search.toLowerCase(),
      );
      final matchesStatus = (status == 'All') || (task.status.value == status);
      final matchesDueDate =
          (dueDate == null) ||
          ((task.deadline.year == dueDate.year) &&
              (task.deadline.month == dueDate.month) &&
              (task.deadline.day == dueDate.day));
      // New: Date range filter
      final matchesStartDate =
          (startDate == null) || !task.deadline.isBefore(startDate);
      final matchesEndDate =
          (endDate == null) || !task.deadline.isAfter(endDate);
      return matchesSearch &&
          matchesStatus &&
          matchesDueDate &&
          matchesStartDate &&
          matchesEndDate;
    }).toList();

    // Sort filtered tasks by selected option
    switch (sort) {
      case 'Title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Deadline':
        filtered.sort((a, b) {
          return a.deadline.compareTo(b.deadline);
        });
        break;
      default:
        // Default: keep order from Supabase (by deadline ascending)
        break;
    }

    return filtered;
  }

  int getAssignedCount(List<Task> tasks) {
    return tasks.where((t) => t.status == TaskStatus.assigned).length;
  }

  int getAcceptedCount(List<Task> tasks) {
    return tasks.where((t) => t.status == TaskStatus.accepted).length;
  }
}
