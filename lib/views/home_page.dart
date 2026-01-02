/// @author [Chong Jun Xiang, Liew Kai Quan]
/// @email [chongjx-wm22@student.tarc.edu.my, liewkq-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 14:54:32
/// @modify date 2025-09-21 14:54:32
/// @desc [HomePage: Displays assigned tasks with filtering, sorting, and search functionality.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/home_controller.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/views/apps/sidebar.dart';
import 'package:job_management_workshop/views/job_details_page.dart';
import 'package:job_management_workshop/widgets/display/status_summary_bar_widget.dart';
import 'package:job_management_workshop/widgets/display/task_list_item_widget.dart';
import 'package:job_management_workshop/widgets/inputs/date_filter_field_widget.dart';
import 'package:job_management_workshop/widgets/timers/active_timer_notification.dart';
import 'package:job_management_workshop/widgets/utils/quick_test_widget.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeToggle;

  const HomePage({super.key, this.isDarkMode = false, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TaskProvider>(
      create: (_) => TaskProvider(),
      child: MyHomePage(
        title: 'JM Workshop',
        isDarkMode: isDarkMode,
        onThemeToggle: onThemeToggle,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    this.onThemeToggle,
  });

  final String title;
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeToggle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _staffId = '';
  String _staffName = '';
  bool _loadingStaff = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final sessionProvider = Provider.of<SessionProvider>(
        context,
        listen: false,
      );
      setState(() {
        _staffId = sessionProvider.staffId ?? 'Unknown ID';
        _staffName = sessionProvider.staffName ?? 'Unknown Name';
      });
      if (_staffId.isNotEmpty && _staffId != 'Unknown ID') {
        if (mounted) {
          Provider.of<TaskProvider>(
            context,
            listen: false,
          ).fetchAssignedTasks(_staffId);
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching user data: $e');
    } finally {
      setState(() {
        _loadingStaff = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStaff) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: AppSidebar(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle ?? (_) {},
        staffId: _staffId,
        staffName: _staffName,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ActiveTimerNotification(),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) => StatusSummaryBarWidget(
                assignedCount: taskProvider.assignedCount,
                acceptedCount: taskProvider.acceptedCount,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) => Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search tasks by title',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      taskProvider.updateSearchQuery(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: taskProvider.statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'All',
                              child: Text('All'),
                            ),
                            DropdownMenuItem(
                              value: TaskStatus.assigned.value,
                              child: const Text('Assigned'),
                            ),
                            DropdownMenuItem(
                              value: TaskStatus.accepted.value,
                              child: const Text('Accepted'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              taskProvider.updateStatusFilter(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: taskProvider.sortOption,
                          decoration: const InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Default',
                              child: Text('Default'),
                            ),
                            DropdownMenuItem(
                              value: 'Title',
                              child: Text('Title'),
                            ),
                            DropdownMenuItem(
                              value: 'Deadline',
                              child: Text('Deadline'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              taskProvider.updateSortOption(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DateFilterFieldWidget(
                          label: 'Start Date',
                          date: taskProvider.startDateFilter,
                          onDateChanged: (picked) {
                            taskProvider.updateStartDateFilter(picked);
                          },
                          onClear: taskProvider.startDateFilter != null
                              ? () => taskProvider.updateStartDateFilter(null)
                              : null,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DateFilterFieldWidget(
                          label: 'End Date',
                          date: taskProvider.endDateFilter,
                          onDateChanged: (picked) {
                            taskProvider.updateEndDateFilter(picked);
                          },
                          onClear: taskProvider.endDateFilter != null
                              ? () => taskProvider.updateEndDateFilter(null)
                              : null,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, _) {
                  if (taskProvider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tasks = taskProvider.filteredTasks;
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text('No assigned tasks found.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskListItemWidget(
                        task: task,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JobDetailsPage(taskId: task.id),
                            ),
                          );
                          final sessionProvider = Provider.of<SessionProvider>(
                            context,
                            listen: false,
                          );
                          final staffId =
                              sessionProvider.staffId ?? 'Unknown ID';
                          if (staffId.isNotEmpty && staffId != 'Unknown ID') {
                            if (mounted) {
                              Provider.of<TaskProvider>(
                                context,
                                listen: false,
                              ).fetchAssignedTasks(staffId);
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            QuickTestButtonsWidget(),
          ],
        ),
      ),
    );
  }
}

class TaskProvider extends ChangeNotifier {
  final HomeController _controller = HomeController();
  List<Task> _tasks = [];
  bool _loading = false;
  String _searchQuery = '';
  String _statusFilter = 'All';
  DateTime? _dueDateFilter;
  String _sortOption = 'Default';
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  bool _disposed = false;

  List<Task> get tasks => _tasks;

  bool get loading => _loading;

  String get searchQuery => _searchQuery;

  String get statusFilter => _statusFilter;

  DateTime? get dueDateFilter => _dueDateFilter;

  String get sortOption => _sortOption;

  DateTime? get startDateFilter => _startDateFilter;

  DateTime? get endDateFilter => _endDateFilter;

  int get assignedCount => _controller.getAssignedCount(filteredTasks);

  int get acceptedCount => _controller.getAcceptedCount(filteredTasks);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchAssignedTasks(String staffId) async {
    if (_disposed) {
      return;
    }
    _loading = true;
    _tasks = await _controller.fetchAssignedTasks(staffId);
    _loading = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void updateDueDateFilter(DateTime? date) {
    _dueDateFilter = date;
    notifyListeners();
  }

  void updateSortOption(String option) {
    _sortOption = option;
    notifyListeners();
  }

  void updateStartDateFilter(DateTime? date) {
    _startDateFilter = date;
    notifyListeners();
  }

  void updateEndDateFilter(DateTime? date) {
    _endDateFilter = date;
    notifyListeners();
  }

  List<Task> get filteredTasks {
    return _controller.filterTasks(
      _tasks,
      search: _searchQuery,
      status: _statusFilter,
      dueDate: _dueDateFilter,
      sort: _sortOption,
      startDate: _startDateFilter,
      endDate: _endDateFilter,
    );
  }
}
