/// @author [Chong Jun Xiang, Liew Kai Quan]
/// @email [chongjx-wm22@student.tarc.edu.my, liewkq-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:10:37
/// @modify date 2025-09-20 15:10:37
/// @desc [StatusSummaryBar: A widget to display summary of job statuses like assigned and accepted counts.]
library;

import 'package:flutter/material.dart';

class StatusSummaryBarWidget extends StatelessWidget {
  final int assignedCount;
  final int acceptedCount;

  const StatusSummaryBarWidget({
    super.key,
    required this.assignedCount,
    required this.acceptedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Assigned: $assignedCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Accepted: $acceptedCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
