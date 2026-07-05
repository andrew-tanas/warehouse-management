import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  // Try default sqflite location
  String dbPath = join(await databaseFactory.getDatabasesPath(), 'warehouse.db');
  print('Trying to open database at: $dbPath');
  
  if (!File(dbPath).existsSync()) {
    print('Database not found there.');
    // Check in the project directory
    dbPath = 'warehouse.db';
  }
  
  var db = await databaseFactory.openDatabase(dbPath);
  await db.delete('bills');
  await db.delete('bill_items');
  await db.delete('payments');
  print('Success! All bills, bill items, and payments have been removed.');
  exit(0);
}
