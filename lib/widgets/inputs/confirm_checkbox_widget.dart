/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:52:35
/// @modify date 2025-09-20 15:52:35
/// @desc [ConfirmCheckboxWidget: A reusable checkbox widget for confirming task completion with error styling.]
library;

import 'package:flutter/material.dart';

class ConfirmCheckboxWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showError;
  final String label;

  const ConfirmCheckboxWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
    this.label = 'I confirm that the task is complete',
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = showError ? Colors.red : Colors.grey;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: borderColor, width: showError ? 2 : 1),
            ),
            side: BorderSide(color: borderColor, width: showError ? 2 : 1),
          ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: showError ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}
