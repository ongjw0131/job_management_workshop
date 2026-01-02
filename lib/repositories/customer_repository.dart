/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-18 02:08:35
/// @modify date 2025-09-18 02:08:35
/// @desc [CustomerRepository: Handles all customer-related data operations using SQLite.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/customer.dart';
import 'package:job_management_workshop/services/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class CustomerRepository {
  static const String _tableName = 'customer';

  Future<Customer> getCustomerById(int customerId) async {
    try {
      AppLogger.info('Fetching customer with id $customerId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );
      if (maps.isEmpty) {
        throw Exception('Customer with id $customerId not found');
      }
      return Customer.fromJson(maps.first);
    } catch (e) {
      AppLogger.error('Error fetching customer by id: $e', e);
      rethrow;
    }
  }

  Future<bool> batchInsertCustomerList(
    Batch batch,
    List<Customer> customerList,
  ) async {
    try {
      AppLogger.info('Batch inserting customers');
      for (final customer in customerList) {
        batch.insert(
          _tableName,
          customer.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return true;
    } catch (e) {
      AppLogger.error('Error in batch inserting customers: $e', e);
      return false;
    }
  }
}
