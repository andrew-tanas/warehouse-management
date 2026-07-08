import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../utils/pdf_generator.dart';
import '../widgets/app_navigation.dart';
import '../l10n/app_localizations.dart';
import '../db/database_helper.dart';
import '../models/bill_item.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../models/bill.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BillProvider>(context, listen: false).loadBills(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigation(
      selectedIndex: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).translate('bills_history'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/create_bill'),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).translate('create_bill')),
        ),
        body: Consumer<BillProvider>(
          builder: (context, provider, child) {
            if (provider.bills.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).translate('no_bills'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView.builder(
                itemCount: provider.bills.length,
                itemBuilder: (context, index) {
                  final bill = provider.bills[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.all(20.0),
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
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<int>(
                                    future: bill.customerBillNumber > 0
                                        ? Future.value(bill.customerBillNumber)
                                        : _getFallbackBillNumber(bill),
                                    builder: (context, snapshot) {
                                      final num = snapshot.data ?? bill.id;
                                      return Text(
                                        'Bill #$num',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Customer: ${bill.customerName}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.print),
                                  label: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('print_pdf'),
                                  ),
                                  onPressed: () {
                                    final customer =
                                        Provider.of<CustomerProvider>(
                                          context,
                                          listen: false,
                                        ).customers.firstWhere(
                                          (v) => v.id == bill.customerId,
                                          orElse: () => Customer(
                                            id: bill.customerId,
                                            name: bill.customerName,
                                            genre: '',
                                            totalDebt: bill.total,
                                          ),
                                        );
                                    PdfGenerator.printBill(
                                      context,
                                      bill,
                                      customer,
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
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/create_bill',
                                      arguments: bill,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: AppLocalizations.of(
                                    context,
                                  ).translate('edit'),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/create_bill',
                                      arguments: bill,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
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
                                          ).translate('delete_bill_confirm'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              ).translate('cancel'),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              provider.deleteBill(
                                                bill.id!,
                                                bill.customerId,
                                                bill.total,
                                              );
                                              Navigator.pop(ctx);
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
                                              DataCell(Text(item.itemName)),
                                              DataCell(Text(item.itemSize)),
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
                                                  item.total.toStringAsFixed(2),
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
            );
          },
        ),
      ),
    );
  }

  Future<int> _getFallbackBillNumber(Bill bill) async {
    final allBills = await DatabaseHelper.instance.getBills();
    final customerBills = allBills
        .where((b) => b.customerId == bill.customerId)
        .toList();
    return customerBills.indexWhere((b) => b.id == bill.id) + 1;
  }
}
