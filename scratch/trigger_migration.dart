import 'package:warehouse_management/db/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await DatabaseHelper.instance.database;
  print('Migration triggered successfully!');
}
