/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21 11:25:07
/// @modify date 2025-09-21 11:25:07
/// @desc [JobTimerWidget: Comprehensive UI widget for job time tracking with start/pause/stop controls and detailed logs]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/job_timer_helper.dart';
import 'package:job_management_workshop/models/task.dart';

class JobTimerWidget extends StatefulWidget {
  final JobTimer timer;
  final bool showDetailedLog;
  final VoidCallback? onTimerUpdate;
  final Task task;

  const JobTimerWidget({
    super.key,
    required this.timer,
    required this.task,
    this.showDetailedLog = false,
    this.onTimerUpdate,
  });

  @override
  State<JobTimerWidget> createState() => _JobTimerWidgetState();
}

class _JobTimerWidgetState extends State<JobTimerWidget> {
  @override
  void initState() {
    super.initState();
    widget.timer.addListener(_onTimerChanged);
  }

  @override
  void dispose() {
    widget.timer.removeListener(_onTimerChanged);
    super.dispose();
  }

  void _onTimerChanged() {
    setState(() {});
    widget.onTimerUpdate?.call();
  }

  Color _getTimerColor() {
    if (widget.timer.isOvertime) return Colors.orange;
    if (widget.timer.isMaxTimeReached) return Colors.red;
    return Colors.green;
  }

  IconData _getTimerIcon() {
    switch (widget.timer.state) {
      case TimerState.running:
        return Icons.play_circle;
      case TimerState.paused:
        return Icons.pause_circle;
      case TimerState.stopped:
        return Icons.stop_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer Header
            Row(
              children: [
                Icon(Icons.timer, color: _getTimerColor(), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Job Timer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTimerColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getTimerColor()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTimerIcon(), size: 16, color: _getTimerColor()),
                      const SizedBox(width: 4),
                      Text(
                        widget.timer.state.name.toUpperCase(),
                        style: TextStyle(
                          color: _getTimerColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Time Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    widget.timer.formattedTotalTime,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(),
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (widget.timer.isRunning &&
                      widget.timer.currentSessionTime.inSeconds > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Session: ${widget.timer.formattedCurrentSession}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (widget.timer.isOvertime) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Overtime: ${widget.timer.formattedOvertimeTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status message for non-accepted tasks
            if (widget.task.status != TaskStatus.accepted) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Accept the task to start timer controls',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        widget.task.status == TaskStatus.accepted &&
                            !widget.timer.isRunning
                        ? widget.timer.startTimer
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 10),
                    label: Text(
                      widget.timer.isStopped ? 'Start' : 'Resume',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.task.status == TaskStatus.accepted
                          ? Colors.green
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        widget.task.status == TaskStatus.accepted &&
                            widget.timer.isRunning
                        ? widget.timer.pauseTimer
                        : null,
                    icon: const Icon(Icons.pause, size: 10),
                    label: const Text('Pause', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.task.status == TaskStatus.accepted
                          ? Colors.orange
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        widget.task.status == TaskStatus.accepted &&
                            !widget.timer.isStopped
                        ? widget.timer.stopTimer
                        : null,
                    icon: const Icon(Icons.stop, size: 10),
                    label: const Text('Stop', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.task.status == TaskStatus.accepted
                          ? Colors.red
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // Reset button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.task.status == TaskStatus.accepted
                    ? _showResetDialog
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Timer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.task.status == TaskStatus.accepted
                      ? Colors.grey
                      : Colors.grey[400],
                ),
              ),
            ),

            // Detailed Log Section
            if (widget.showDetailedLog &&
                widget.timer.timeEntries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Time Log',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.timer.timeEntries.length} entries',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.timer.timeEntries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = widget.timer.timeEntries.reversed
                        .toList()[index];
                    return _buildLogEntry(entry);
                  },
                ),
              ),
            ],

            // Warnings
            if (widget.timer.isOvertime) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Overtime detected!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (widget.timer.isMaxTimeReached) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Maximum work hours reached!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(TimeEntry entry) {
    IconData icon;
    Color color;

    switch (entry.type) {
      case TimeEntryType.start:
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case TimeEntryType.pause:
        icon = Icons.pause;
        color = Colors.orange;
        break;
      case TimeEntryType.resume:
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case TimeEntryType.stop:
        icon = Icons.stop;
        color = Colors.red;
        break;
      case TimeEntryType.overtime:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case TimeEntryType.reset:
        icon = Icons.refresh;
        color = Colors.blue;
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
                  entry.typeDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (entry.description.isNotEmpty)
                  Text(
                    entry.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.formattedTimestamp.split(' ').last, // Just show time
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
              if (entry.duration != null)
                Text(
                  'Total: ${entry.duration.toString().split('.').first}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Timer'),
          content: const Text(
            'Are you sure you want to reset the timer? All time data will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.timer.resetTimer();
                Navigator.of(context).pop();
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
