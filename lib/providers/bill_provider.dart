import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/item_history.dart';
import '../db/database_helper.dart';

class BillProvider with ChangeNotifier {
  List<Bill> _bills = [];

  List<Bill> get bills => _bills;

  Future<void> loadBills() async {
    _bills = await DatabaseHelper.instance.getBills();
    notifyListeners();
  }

  Future<void> addBill(Bill bill, List<BillItem> billItems) async {
    int billId = await DatabaseHelper.instance.insertBill(bill);
    bill.id = billId;
    
    for (var item in billItems) {
      item.billId = billId;
      await DatabaseHelper.instance.insertBillItem(item);
      await DatabaseHelper.instance.updateItemStock(item.itemId, -(item.quantityDozens));
      await DatabaseHelper.instance.insertItemHistory(ItemHistory(
        itemId: item.itemId,
        date: bill.date,
        amountChange: -(item.quantityDozens),
        note: 'bill - ${bill.customerName} - ${bill.date.year}-${bill.date.month.toString().padLeft(2, '0')}-${bill.date.day.toString().padLeft(2, '0')}',
        billId: billId,
      ));
    }
    
    // Update customer total debt
    await DatabaseHelper.instance.updateCustomerDebt(bill.customerId, bill.total);
    
    await loadBills();
  }

  Future<void> updateExistingBill(Bill bill, List<BillItem> newBillItems, Bill oldBill) async {
    // Revert old bill effects
    final oldItems = await DatabaseHelper.instance.getBillItems(oldBill.id!);
    for (var item in oldItems) {
      await DatabaseHelper.instance.updateItemStock(item.itemId, (item.quantityDozens));
    }
    await DatabaseHelper.instance.updateCustomerDebt(oldBill.customerId, -oldBill.total);
    await DatabaseHelper.instance.deleteBillItems(oldBill.id!);
    await DatabaseHelper.instance.deleteItemHistoryByBillId(oldBill.id!);

    // Apply new bill effects
    await DatabaseHelper.instance.updateBill(bill);
    for (var item in newBillItems) {
      item.billId = bill.id!;
      await DatabaseHelper.instance.insertBillItem(item);
      await DatabaseHelper.instance.updateItemStock(item.itemId, -(item.quantityDozens));
      await DatabaseHelper.instance.insertItemHistory(ItemHistory(
        itemId: item.itemId,
        date: bill.date,
        amountChange: -(item.quantityDozens),
        note: 'bill - ${bill.customerName} - ${bill.date.year}-${bill.date.month.toString().padLeft(2, '0')}-${bill.date.day.toString().padLeft(2, '0')}',
        billId: bill.id,
      ));
    }
    await DatabaseHelper.instance.updateCustomerDebt(bill.customerId, bill.total);
    
    await loadBills();
  }

  Future<void> deleteBill(int billId, int customerId, double total) async {
    final oldItems = await DatabaseHelper.instance.getBillItems(billId);
    for (var item in oldItems) {
      await DatabaseHelper.instance.updateItemStock(item.itemId, (item.quantityDozens));
    }
    await DatabaseHelper.instance.deleteItemHistoryByBillId(billId);
    await DatabaseHelper.instance.deleteBill(billId);
    // Reverse the customer debt
    await DatabaseHelper.instance.updateCustomerDebt(customerId, -total);
    await loadBills();
  }
}
