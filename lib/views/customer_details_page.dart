/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-15 17:11:57
/// @modify date 2025-09-15 17:11:57
/// @desc [CustomerDetailsPage: Displays detailed information about a customer.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/models/customer.dart';
import 'package:job_management_workshop/widgets/display/customer_header_widget.dart';
import 'package:job_management_workshop/widgets/display/detail_row_widget.dart';

class CustomerDetailsPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerHeaderWidget(customer: customer),
            const SizedBox(height: 18),
            DetailRowWidget(label: 'Phone', value: customer.phone),
            DetailRowWidget(label: 'Email', value: customer.email),
            DetailRowWidget(label: 'Make', value: customer.vehicleMake),
            DetailRowWidget(label: 'Model', value: customer.vehicleModel),
            DetailRowWidget(
              label: 'Registration',
              value: customer.vehicleRegistration,
            ),
            DetailRowWidget(label: 'Type', value: customer.equipmentType),
            DetailRowWidget(label: 'Serial', value: customer.equipmentSerial),
          ],
        ),
      ),
    );
  }
}
