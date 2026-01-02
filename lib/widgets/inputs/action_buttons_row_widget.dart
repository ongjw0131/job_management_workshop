/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:52:41
/// @modify date 2025-09-20 15:52:41
/// @desc [ActionButtonsRowWidget: A reusable row with Reset and Complete buttons.]
library;

import 'package:flutter/material.dart';

class ActionButtonsRowWidget extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onComplete;
  final bool resetDisabled;
  final bool completeDisabled;

  const ActionButtonsRowWidget({
    super.key,
    required this.onReset,
    required this.onComplete,
    this.resetDisabled = false,
    this.completeDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: resetDisabled ? null : onReset,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: completeDisabled ? null : onComplete,
            child: const Text('Complete'),
          ),
        ),
      ],
    );
  }
}
