/// @author [Woo Keng Keong, Chong Jun Xiang]
/// @email [wookk-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 16:34:12
/// @modify date 2025-09-20 16:34:12
/// @desc [InfoTileWidgets: Widgets for displaying and editing information in a tile format.]
library;

import 'package:flutter/material.dart';

class InfoTileWidget extends StatelessWidget {
  final String label;
  final String? value;

  const InfoTileWidget({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), subtitle: Text(value ?? '—'));
  }
}

class EditableInfoTileWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final Future<void> Function() onSave;
  final String? hintText;
  final String? errorText;
  final Widget? prefix;
  final Widget? cancelButton;
  final TextInputType? keyboardType;

  const EditableInfoTileWidget({
    super.key,
    required this.label,
    required this.value,
    required this.isEditing,
    required this.controller,
    required this.onEdit,
    required this.onSave,
    this.hintText,
    this.errorText,
    this.prefix,
    this.cancelButton,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        onSubmitted: (_) => onSave(),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: hintText,
                          errorText: errorText,
                          prefix: prefix,
                        ),
                        keyboardType: keyboardType,
                      ),
                    ),
                    if (cancelButton != null) cancelButton!,
                  ],
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            )
          : Text(value.isNotEmpty ? value : '—'),
      trailing: IconButton(
        icon: Icon(isEditing ? Icons.check : Icons.edit),
        onPressed: isEditing ? onSave : onEdit,
      ),
    );
  }
}
