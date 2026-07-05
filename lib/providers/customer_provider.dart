import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/customer.dart';
import '../models/payment.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _customers = await DatabaseHelper.instance.getCustomers();
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await DatabaseHelper.instance.insertCustomer(customer);
    await fetchCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseHelper.instance.updateCustomer(customer);
    await fetchCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await DatabaseHelper.instance.deleteCustomer(id);
    await fetchCustomers();
  }

  Future<void> addPayment(int customerId, double amount, String note, [DateTime? date]) async {
    final payment = Payment(
      customerId: customerId,
      amount: amount,
      date: date ?? DateTime.now(),
      note: note,
    );
    await DatabaseHelper.instance.insertPayment(payment);
    await DatabaseHelper.instance.updateCustomerDebt(customerId, -amount);
    await fetchCustomers();
  }

  Future<void> editPayment(Payment oldPayment, Payment newPayment) async {
    await DatabaseHelper.instance.updatePayment(newPayment);
    double difference = oldPayment.amount - newPayment.amount; // if old was 10, new is 15. diff is -5. we need to reduce debt by 5. so difference is added to debt? wait.
    // oldAmount: 10 (debt was reduced by 10)
    // newAmount: 15 (debt should be reduced by 15)
    // so we must subtract 5 from debt. So we ADD (oldAmount - newAmount) to debt!
    if (difference != 0) {
      await DatabaseHelper.instance.updateCustomerDebt(newPayment.customerId, difference);
    }
    await fetchCustomers();
  }

  Future<void> deletePayment(Payment payment) async {
    await DatabaseHelper.instance.deletePayment(payment.id!);
    // since we delete the payment, the debt goes back up by the payment amount!
    await DatabaseHelper.instance.updateCustomerDebt(payment.customerId, payment.amount);
    await fetchCustomers();
  }
}
