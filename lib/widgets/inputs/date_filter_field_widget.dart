/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 16:07:55
/// @modify date 2025-09-20 16:07:55
/// @desc [DateFileterFieldWidget is a reusable widget that allows users to select a date from a date picker dialog.]
library;

import 'package:flutter/material.dart';

typedef DateChanged = void Function(DateTime? date);

class DateFilterFieldWidget extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateChanged onDateChanged;
  final VoidCallback? onClear;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateFilterFieldWidget({
    super.key,
    required this.label,
    required this.date,
    required this.onDateChanged,
    this.onClear,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final fd = firstDate ?? DateTime(2000);
    final ld = lastDate ?? DateTime(2100);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: fd,
                lastDate: ld,
              );
              onDateChanged(picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.date_range),
              ),
              child: Text(
                date == null
                    ? 'Select ${label.toLowerCase()}'
                    : date!.toLocal().toString().split(' ')[0],
              ),
            ),
          ),
        ),
        if (date != null)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear $label',
            onPressed: onClear,
          ),
      ],
    );
  }
}
