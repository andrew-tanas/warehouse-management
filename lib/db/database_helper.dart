import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/payment.dart';
import '../models/item_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('warehouse.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final appDocsDir = await getApplicationDocumentsDirectory();
    final dbDir = join(appDocsDir.path, 'El Mohandes Warehouse');
    await Directory(dbDir).create(recursive: true);
    final path = join(dbDir, filePath);

    final dbExists = await File(path).exists();
    if (!dbExists) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final prePopulatedDbPath = join(exeDir, '.dart_tool', 'sqflite_common_ffi', 'databases', 'warehouse.db');
      
      if (await File(prePopulatedDbPath).exists()) {
        await File(prePopulatedDbPath).copy(path);
      } else {
        final devDbPath = join(Directory.current.path, '.dart_tool', 'sqflite_common_ffi', 'databases', 'warehouse.db');
        if (await File(devDbPath).exists()) {
           await File(devDbPath).copy(path);
        }
      }
    }

    return await openDatabase(
      path, 
      version: 7, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN customPrice REAL');
      await db.execute('ALTER TABLE bill_items ADD COLUMN itemSize TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE bill_items ADD COLUMN itemPrice REAL NOT NULL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerId INTEGER NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT NOT NULL
)
''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE bills ADD COLUMN customerBillNumber INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE item_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  itemId INTEGER NOT NULL,
  date TEXT NOT NULL,
  amountChange REAL NOT NULL,
  note TEXT NOT NULL,
  billId INTEGER
)
''');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE bill_items ADD COLUMN note TEXT');
    }
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE vendors RENAME TO customers'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorId TO customerId'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorName TO customerName'); } catch (_) {}
      try { await db.execute('ALTER TABLE payments RENAME COLUMN vendorId TO customerId'); } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE items (
  id $idType,
  name $textType,
  size $textType,
  retailPrice $realType,
  wholesalePrice $realType,
  customPrice REAL,
  stockAmount $intType
)
''');

    await db.execute('''
CREATE TABLE customers (
  id $idType,
  name $textType,
  genre $textType,
  totalDebt $realType
)
''');

    await db.execute('''
CREATE TABLE bills (
  id $idType,
  date $textType,
  customerId $intType,
  customerName $textType,
  total $realType,
  discountApplied $realType,
  customerBillNumber $intType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE bill_items (
  id $idType,
  billId $intType,
  itemId $intType,
  itemName $textType,
  itemSize $textType,
  itemPrice $realType,
  quantityDozens $realType,
  total $realType,
  note TEXT
)
''');

    await db.execute('''
CREATE TABLE payments (
  id $idType,
  customerId $intType,
  amount $realType,
  date $textType,
  note $textType
)
''');

    await db.execute('''
CREATE TABLE item_history (
  id $idType,
  itemId $intType,
  date $textType,
  amountChange $realType,
  note $textType,
  billId INTEGER
)
''');
  }

  // --- CRUD for Items ---
  Future<int> insertItem(Item item) async {
    final db = await instance.database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getItems() async {
    final db = await instance.database;
    final result = await db.query('items');
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await instance.database;
    return db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemStock(int itemId, double quantityChange) async {
    final db = await instance.database;
    final result = await db.query('items', columns: ['stockAmount'], where: 'id = ?', whereArgs: [itemId]);
    if (result.isNotEmpty) {
      double currentStock = (result.first['stockAmount'] as num).toDouble();
      return await db.update(
        'items',
        {'stockAmount': currentStock + quantityChange},
        where: 'id = ?',
        whereArgs: [itemId],
      );
    }
    return 0;
  }

  Future<int> insertItemHistory(ItemHistory history) async {
    final db = await instance.database;
    try {
      return await db.insert('item_history', history.toMap());
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS item_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  itemId INTEGER NOT NULL,
  date TEXT NOT NULL,
  amountChange REAL NOT NULL,
  note TEXT NOT NULL,
  billId INTEGER
)
''');
        return await db.insert('item_history', history.toMap());
      }
      rethrow;
    }
  }

  Future<List<ItemHistory>> getItemHistories(int itemId) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'item_history',
        where: 'itemId = ?',
        whereArgs: [itemId],
        orderBy: 'date DESC',
      );
      return result.map((json) => ItemHistory.fromMap(json)).toList();
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS item_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  itemId INTEGER NOT NULL,
  date TEXT NOT NULL,
  amountChange REAL NOT NULL,
  note TEXT NOT NULL,
  billId INTEGER
)
''');
        return [];
      }
      rethrow;
    }
  }

  Future<void> deleteItemHistoryByBillId(int billId) async {
    final db = await instance.database;
    await db.delete('item_history', where: 'billId = ?', whereArgs: [billId]);
  }

  // --- CRUD for Customers ---
  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    final db = await instance.database;
    try {
      final result = await db.query('customers');
      return result.map((json) => Customer.fromMap(json)).toList();
    } catch (_) {
      try { await db.execute('ALTER TABLE vendors RENAME TO customers'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorId TO customerId'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorName TO customerName'); } catch (_) {}
      try { await db.execute('ALTER TABLE payments RENAME COLUMN vendorId TO customerId'); } catch (_) {}
      
      final result = await db.query('customers');
      return result.map((json) => Customer.fromMap(json)).toList();
    }
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    
    // Get all bills for this customer
    List<Map<String, dynamic>> bills = [];
    try {
      bills = await db.query('bills', where: 'customerId = ?', whereArgs: [id]);
    } catch (_) {
      try { bills = await db.query('bills', where: 'vendorId = ?', whereArgs: [id]); } catch (_) {}
    }
    
    // Delete all bill_items for each bill
    for (var b in bills) {
      await db.delete('bill_items', where: 'billId = ?', whereArgs: [b['id']]);
    }

    // Delete all bills for this customer
    try {
      await db.delete('bills', where: 'customerId = ?', whereArgs: [id]);
    } catch (_) {
      try { await db.delete('bills', where: 'vendorId = ?', whereArgs: [id]); } catch (_) {}
    }
    
    // Delete all payments for this customer
    try {
      await db.delete('payments', where: 'customerId = ?', whereArgs: [id]);
    } catch (_) {
      try { await db.delete('payments', where: 'vendorId = ?', whereArgs: [id]); } catch (_) {}
    }

    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> updateCustomerDebt(int customerId, double amountToAdd) async {
    final db = await instance.database;
    final result = await db.query(
      'customers',
      columns: ['totalDebt'],
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (result.isNotEmpty) {
      double currentDebt = result.first['totalDebt'] as double;
      return await db.update(
        'customers',
        {'totalDebt': currentDebt + amountToAdd},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    }
    return 0;
  }

  // --- CRUD for Bills and Bill Items ---
  Future<int> insertBill(Bill bill) async {
    final db = await instance.database;
    try {
      await db.execute('ALTER TABLE bills ADD COLUMN customerBillNumber INTEGER NOT NULL DEFAULT 0');
    } catch (_) {}
    
    List<Map<String, Object?>> result;
    try {
      result = await db.rawQuery('SELECT MAX(customerBillNumber) as max_num FROM bills WHERE customerId = ?', [bill.customerId]);
    } catch (_) {
      try { await db.execute('ALTER TABLE vendors RENAME TO customers'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorId TO customerId'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorName TO customerName'); } catch (_) {}
      try { await db.execute('ALTER TABLE payments RENAME COLUMN vendorId TO customerId'); } catch (_) {}
      result = await db.rawQuery('SELECT MAX(customerBillNumber) as max_num FROM bills WHERE customerId = ?', [bill.customerId]);
    }
    int maxNum = 0;
    if (result.isNotEmpty && result.first['max_num'] != null) {
      maxNum = result.first['max_num'] as int;
    }
    bill.customerBillNumber = maxNum + 1;
    return await db.insert('bills', bill.toMap());
  }

  Future<int> insertBillItem(BillItem billItem) async {
    final db = await instance.database;
    try {
      return await db.insert('bill_items', billItem.toMap());
    } catch (e) {
      if (e.toString().contains('has no column named note')) {
        await db.execute('ALTER TABLE bill_items ADD COLUMN note TEXT');
        return await db.insert('bill_items', billItem.toMap());
      }
      rethrow;
    }
  }

  Future<List<Bill>> getBills() async {
    final db = await instance.database;
    try {
      await db.execute('ALTER TABLE bills ADD COLUMN customerBillNumber INTEGER NOT NULL DEFAULT 0');
    } catch (_) {}
    try {
      await db.query('bills', columns: ['customerId'], limit: 1);
    } catch (_) {
      try { await db.execute('ALTER TABLE vendors RENAME TO customers'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorId TO customerId'); } catch (_) {}
      try { await db.execute('ALTER TABLE bills RENAME COLUMN vendorName TO customerName'); } catch (_) {}
      try { await db.execute('ALTER TABLE payments RENAME COLUMN vendorId TO customerId'); } catch (_) {}
    }
    final result = await db.query('bills');
    return result.map((json) => Bill.fromMap(json)).toList();
  }

  Future<List<BillItem>> getBillItems(int billId) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'bill_items',
        where: 'billId = ?',
        whereArgs: [billId],
      );
      return result.map((json) => BillItem.fromMap(json)).toList();
    } catch (e) {
      if (e.toString().contains('has no column named note') || e.toString().contains('no such column')) {
        await db.execute('ALTER TABLE bill_items ADD COLUMN note TEXT');
        final result = await db.query(
          'bill_items',
          where: 'billId = ?',
          whereArgs: [billId],
        );
        return result.map((json) => BillItem.fromMap(json)).toList();
      }
      rethrow;
    }
  }

  Future<int> updateBill(Bill bill) async {
    final db = await instance.database;
    return await db.update('bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<void> deleteBillItems(int billId) async {
    final db = await instance.database;
    await db.delete('bill_items', where: 'billId = ?', whereArgs: [billId]);
  }

  Future<int> deleteBill(int id) async {
    final db = await instance.database;
    await db.delete('bill_items', where: 'billId = ?', whereArgs: [id]);
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD for Payments ---
  Future<int> insertPayment(Payment payment) async {
    final db = await instance.database;
    try {
      return await db.insert('payments', payment.toMap());
    } catch (e) {
      if (e.toString().contains('no such table: payments')) {
        await db.execute('''
CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerId INTEGER NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT NOT NULL
)
''');
        return await db.insert('payments', payment.toMap());
      }
      rethrow;
    }
  }

  Future<List<Payment>> getPaymentsForCustomer(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date ASC',
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await instance.database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
