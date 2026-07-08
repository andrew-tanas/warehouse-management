import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'warehouse.db');
  var db = await databaseFactory.openDatabase(path);
  try {
    await db.execute(
      "INSERT INTO bill_items (billId, itemId, itemName, itemSize, itemPrice, quantityDozens, total, note) VALUES (1, 1, 'Test', 'M', 10, 1, 10, 'note')",
    );
    print("Success!");
  } catch (e) {
    print("DB ERROR: $e");
  }
}
