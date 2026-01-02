/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-17 00:29:24
/// @modify date 2025-09-17 00:29:24
/// @desc [CustomerService: Service to handle customer-related operations using Supabase as the backend.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/customer.dart';
import 'package:job_management_workshop/services/supabase_service.dart';

class CustomerService {
  static const String _tableName = 'customer';

  Future<List<Customer>> getAllCustomers() async {
    try {
      AppLogger.info('Fetching all customers');
      final queryBuilder = await SupabaseService.from(_tableName);
      final customerData = await queryBuilder.select().order(
        'customer_id',
        ascending: true,
      );
      return (customerData as List)
          .map((json) => Customer.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching customers: $e');
      return [];
    }
  }
}
