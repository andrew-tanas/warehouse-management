import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = join(Directory.current.path, '.dart_tool', 'sqflite_common_ffi', 'databases', 'warehouse.db');
  
  print('Checking DB at $dbPath');
  if (!await File(dbPath).exists()) {
    print('DB does not exist here!');
    return;
  }
  
  final db = await databaseFactory.openDatabase(dbPath);
  final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'items']);
  for (var table in tables) {
    print(table['sql']);
  }
  
  var result = await db.rawQuery('PRAGMA table_info(items)');
  print(result);
  
  await db.close();
}
