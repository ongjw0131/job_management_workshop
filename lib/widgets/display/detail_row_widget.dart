/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 14:49:46
/// @modify date 2025-09-20 14:49:46
/// @desc [DetailRowWidget: A small reusable detail row widget used across pages.]
library;

import 'package:flutter/material.dart';

class DetailRowWidget extends StatelessWidget {
  final String label;
  final String? value;
  final double labelWidth;

  const DetailRowWidget({
    super.key,
    required this.label,
    this.value,
    this.labelWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
