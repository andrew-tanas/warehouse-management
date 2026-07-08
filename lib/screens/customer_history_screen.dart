import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/payment.dart';
import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../utils/pdf_generator.dart';
import '../providers/customer_provider.dart';
import '../providers/bill_provider.dart';

class CustomerHistoryScreen extends StatefulWidget {
  final Customer customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  List<Bill> _bills = [];
  List<Payment> _payments = [];
  bool _isLoading = true;
  Customer? _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final customers = await DatabaseHelper.instance.getCustomers();
      final currentCustomer = customers.firstWhere(
        (v) => v.id == widget.customer.id,
        orElse: () => widget.customer,
      );

      final allBills = await DatabaseHelper.instance.getBills();
      final bills = allBills
          .where((b) => b.customerId == widget.customer.id)
          .toList();
      final payments = await DatabaseHelper.instance.getPaymentsForCustomer(
        widget.customer.id!,
      );

      setState(() {
        _currentCustomer = currentCustomer;
        _bills = bills;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading history: $e");
      if (e.toString().contains('no such table: payments')) {
        final db = await DatabaseHelper.instance.database;
        await db.execute('''
CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customerId INTEGER NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT NOT NULL
)
''');
        _loadHistory();
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editPayment(Payment payment) {
    final amountController = TextEditingController(
      text: payment.amount.toString(),
    );
    final noteController = TextEditingController(text: payment.note);
    DateTime selectedDate = payment.date;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).translate('edit')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).translate('amount'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).translate('note'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date (Optional)',
                      ),
                      child: Text(
                        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newAmount =
                        double.tryParse(amountController.text) ?? 0.0;
                    if (newAmount > 0) {
                      final newPayment = Payment(
                        id: payment.id,
                        customerId: payment.customerId,
                        amount: newAmount,
                        date: selectedDate,
                        note: noteController.text,
                      );
                      await Provider.of<CustomerProvider>(
                        context,
                        listen: false,
                      ).editPayment(payment, newPayment);
                      Navigator.pop(ctx);
                      _loadHistory();
                    }
                  },
                  child: Text(AppLocalizations.of(context).translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deletePayment(Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete')),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Provider.of<CustomerProvider>(
                context,
                listen: false,
              ).deletePayment(payment);
              Navigator.pop(ctx);
              _loadHistory();
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                AppLocalizations.of(context).translate('pay'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('amount'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('note'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          selectedDate == null
                              ? 'Select Date (Defaults to Now)'
                              : "${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount > 0 && _currentCustomer != null) {
                      await Provider.of<CustomerProvider>(
                        context,
                        listen: false,
                      ).addPayment(
                        _currentCustomer!.id!,
                        amount,
                        noteController.text.trim(),
                        selectedDate,
                      );
                      Navigator.pop(context);
                      _loadHistory();
                    }
                  },
                  child: Text(AppLocalizations.of(context).translate('pay')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrintStatementDialog() {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).translate('statement')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('select_date_range'),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('start_date'),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        startDate == null
                            ? AppLocalizations.of(
                                context,
                              ).translate('not_selected')
                            : "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('end_date'),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        endDate == null
                            ? AppLocalizations.of(
                                context,
                              ).translate('not_selected')
                            : "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_currentCustomer != null) {
                      PdfGenerator.printCustomerStatement(
                        context,
                        _currentCustomer!,
                        _bills,
                        _payments,
                        startDate: startDate,
                        endDate: endDate,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppLocalizations.of(context).translate('print_pdf'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          '${_currentCustomer?.name ?? ''} - ${AppLocalizations.of(context).translate('history')}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Current Balance: ${(_currentCustomer?.totalDebt ?? 0) > 0 ? '-' : '+'}${(_currentCustomer?.totalDebt ?? 0).abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (_currentCustomer?.totalDebt ?? 0) > 0
                      ? Colors.redAccent
                      : Colors.green,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _showPrintStatementDialog,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(AppLocalizations.of(context).translate('statement')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _showAddPaymentDialog,
              icon: const Icon(Icons.payment),
              label: Text(AppLocalizations.of(context).translate('pay')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  '/create_bill',
                  arguments: _currentCustomer,
                );
                _loadHistory();
              },
              icon: const Icon(Icons.add),
              label: Text(
                AppLocalizations.of(context).translate('create_bill'),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSection(
                    title: AppLocalizations.of(
                      context,
                    ).translate('bills_history'),
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    isEmpty: _bills.isEmpty,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _bills.length,
                      itemBuilder: (context, index) {
                        final bill = _bills[index];
                        final billNumber = bill.customerBillNumber > 0
                            ? bill.customerBillNumber
                            : (index + 1);
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.all(16.0),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.receipt,
                                      color: Colors.blue.shade700,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bill #$billNumber',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'MMM dd, yyyy - hh:mm a',
                                          ).format(bill.date),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (bill.discountApplied > 0) ...[
                                        Text(
                                          '${AppLocalizations.of(context).translate('subtotal')}: ${(bill.total + bill.discountApplied).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${AppLocalizations.of(context).translate('discount')}: ${bill.discountApplied.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        bill.total.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.print,
                                          color: Colors.black87,
                                        ),
                                        tooltip: AppLocalizations.of(
                                          context,
                                        ).translate('print_pdf'),
                                        onPressed: () {
                                          PdfGenerator.printBill(
                                            context,
                                            bill,
                                            _currentCustomer,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.orange,
                                        ),
                                        tooltip: AppLocalizations.of(
                                          context,
                                        ).translate('edit'),
                                        onPressed: () async {
                                          await Navigator.pushNamed(
                                            context,
                                            '/create_bill',
                                            arguments: bill,
                                          );
                                          _loadHistory();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: AppLocalizations.of(
                                          context,
                                        ).translate('delete'),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('delete'),
                                              ),
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate(
                                                  'delete_bill_confirm',
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    ).translate('cancel'),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await Provider.of<
                                                          BillProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        )
                                                        .deleteBill(
                                                          bill.id!,
                                                          bill.customerId,
                                                          bill.total,
                                                        );
                                                    Navigator.pop(ctx);
                                                    _loadHistory();
                                                  },
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    ).translate('delete'),
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                FutureBuilder<List<BillItem>>(
                                  future: DatabaseHelper.instance.getBillItems(
                                    bill.id!,
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData)
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    if (snapshot.data!.isEmpty)
                                      return const SizedBox.shrink();
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0,
                                          vertical: 8.0,
                                        ),
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.resolveWith(
                                                (states) => Colors.grey.shade50,
                                              ),
                                          columns: [
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('name'),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('item_size'),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('item_price'),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('quantity_dozens'),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('total'),
                                              ),
                                            ),
                                          ],
                                          rows: snapshot.data!
                                              .map(
                                                (item) => DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(item.itemName),
                                                    ),
                                                    DataCell(
                                                      Text(item.itemSize),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item.itemPrice
                                                            .toStringAsFixed(2),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item.quantityDozens
                                                            .toString(),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item.total
                                                            .toStringAsFixed(2),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 2,
                  child: _buildSection(
                    title: AppLocalizations.of(context).translate('payments'),
                    icon: Icons.payment,
                    color: Colors.green,
                    isEmpty: _payments.isEmpty,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(
                                  Icons.money,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                payment.amount.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'yyyy-MM-dd HH:mm',
                                    ).format(payment.date),
                                  ),
                                  if (payment.note.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '${AppLocalizations.of(context).translate('note')}: ${payment.note}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _editPayment(payment),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    ).translate('edit'),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deletePayment(payment),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    ).translate('delete'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isEmpty,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
          )
        else
          Expanded(child: child),
      ],
    );
  }
}
