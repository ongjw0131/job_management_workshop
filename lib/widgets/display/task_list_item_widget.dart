/// @author [Chong Jun Xiang, Liew Kai Quan]
/// @email [chongjx-wm22@student.tarc.edu.my, liewkq-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:10:56
/// @modify date 2025-09-20 15:10:56
/// @desc [TaskListItem: A widget to display a single task item in the task list.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/models/task.dart';

class TaskListItemWidget extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool isThreeLine;

  const TaskListItemWidget({
    super.key,
    required this.task,
    this.onTap,
    this.leadingIcon,
    this.trailing,
    this.isThreeLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text(
        'Status: ${task.statusDisplayName}\nDeadline: ${task.deadline.toLocal().toString().split(' ')[0]}',
      ),
      leading: Icon(leadingIcon ?? Icons.assignment),
      isThreeLine: isThreeLine,
      trailing:
          trailing ??
          (() {
            if (!task.isCompleted) return null;
            final bool unsigned = task.signaturePath == null;
            if (unsigned) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Unsigned',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }
            return const Text(
              'Signed',
              style: TextStyle(fontWeight: FontWeight.w600),
            );
          })(),
      onTap: onTap,
    );
  }
}
