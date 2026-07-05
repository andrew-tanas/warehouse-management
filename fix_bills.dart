import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = await databaseFactory.getDatabasesPath();
  final path = join(dbPath, 'warehouse.db');

  final db = await databaseFactory.openDatabase(path);

  // Fetch all vendors
  final vendors = await db.query('vendors');

  for (var vendor in vendors) {
    int vendorId = vendor['id'] as int;
    final bills = await db.query('bills', where: 'vendorId = ?', whereArgs: [vendorId], orderBy: 'id ASC');

    int billNum = 1;
    for (var bill in bills) {
      if ((bill['customerBillNumber'] as int?) == 0 || (bill['customerBillNumber'] as int?) == null) {
        await db.update(
          'bills',
          {'customerBillNumber': billNum},
          where: 'id = ?',
          whereArgs: [bill['id']],
        );
      }
      billNum++;
    }
  }

  print("Database migration completed successfully.");
  exit(0);
}
