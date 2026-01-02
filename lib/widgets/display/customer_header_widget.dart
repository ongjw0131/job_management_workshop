/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 14:49:31
/// @modify date 2025-09-20 14:49:31
/// @desc [CustomerHeaderWidget: A reusable widget to display customer information with an avatar, name, phone number, and an info button.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/models/customer.dart';

class CustomerHeaderWidget extends StatelessWidget {
  final Customer? customer;
  final VoidCallback? onInfoPressed;

  const CustomerHeaderWidget({
    super.key,
    required this.customer,
    this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = customer == null
        ? const CircleAvatar(child: Icon(Icons.person))
        : CircleAvatar(
            child: Text(customer!.name.isNotEmpty ? customer!.name[0] : '?'),
          );

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer?.name ?? 'Unknown Customer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                customer?.phone ?? 'No phone',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        if (onInfoPressed != null)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'More options',
            onPressed: onInfoPressed,
          ),
      ],
    );
  }
}
