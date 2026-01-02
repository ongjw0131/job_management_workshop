/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-18 02:08:39
/// @modify date 2025-09-18 02:08:39
/// @desc [StaffRepository: Handles all staff-related data operations using SQLite.]
library;

import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/staff.dart';
import 'package:job_management_workshop/services/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class StaffRepository {
  static const String _tableName = 'staff';

  Future<Staff> getStaffById(String staffId) async {
    try {
      AppLogger.info('[getStaffById] Fetching staff with id $staffId');
      final db = await DatabaseProvider.getDatabase();
      final maps = await db.query(
        _tableName,
        where: 'staff_id = ?',
        whereArgs: [staffId],
      );
      if (maps.isEmpty) {
        throw Exception('Staff with id $staffId not found');
      }
      return Staff.fromJson(maps.first);
    } catch (e) {
      AppLogger.error('[getStaffById] Error fetching staff by id: $e', e);
      rethrow;
    }
  }

  Future<bool> insertStaff(Staff staff) async {
    try {
      AppLogger.info('[insertStaff] Inserting staff with id ${staff.staffId}');
      final db = await DatabaseProvider.getDatabase();
      await db.insert(
        _tableName,
        staff.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      AppLogger.error('[insertStaff] Error inserting staff: $e', e);
      return false;
    }
  }

  Future<bool> batchInsertStaff(Batch batch, Staff staff) async {
    try {
      AppLogger.info(
        '[batchInsertStaff] Inserting staff with id ${staff.staffId}',
      );
      batch.insert(
        _tableName,
        staff.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      AppLogger.error(
        '[batchInsertStaff] Error in batch inserting staff: $e',
        e,
      );
      return false;
    }
  }

  Future<Staff> updateStaff(Staff staff) async {
    try {
      AppLogger.info('[updateStaff] Updating staff with id ${staff.staffId}');
      final db = await DatabaseProvider.getDatabase();
      await db.update(
        _tableName,
        staff.toJson(),
        where: 'staff_id = ?',
        whereArgs: [staff.staffId],
      );
      return staff;
    } catch (e) {
      AppLogger.error('[updateStaff] Error updating staff: $e', e);
      rethrow;
    }
  }
}
