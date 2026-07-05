import 'package:flutter/material.dart';
import '../models/item.dart';
import '../db/database_helper.dart';
import '../models/item_history.dart';

class ItemProvider with ChangeNotifier {
  List<Item> _items = [];

  List<Item> get items => _items;

  Future<void> loadItems() async {
    _items = await DatabaseHelper.instance.getItems();
    notifyListeners();
  }

  Future<void> addItem(Item item) async {
    await DatabaseHelper.instance.insertItem(item);
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    await DatabaseHelper.instance.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await DatabaseHelper.instance.deleteItem(id);
    await loadItems();
  }

  Future<void> updateStock(int id, double amount, {DateTime? date, String note = ''}) async {
    await DatabaseHelper.instance.updateItemStock(id, amount);
    await DatabaseHelper.instance.insertItemHistory(ItemHistory(
      itemId: id,
      date: date ?? DateTime.now(),
      amountChange: amount,
      note: note,
    ));
    await loadItems();
  }
}
