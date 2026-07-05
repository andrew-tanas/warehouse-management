import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navigation.dart';
import '../l10n/app_localizations.dart';
import '../providers/customer_provider.dart';
import '../providers/item_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data asynchronously when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
      Provider.of<ItemProvider>(context, listen: false).loadItems();
      Provider.of<BillProvider>(context, listen: false).loadBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigation(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('dashboard'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Consumer3<CustomerProvider, ItemProvider, BillProvider>(
                  builder: (context, customerProvider, itemProvider, billProvider, child) {
                    int totalCustomers = customerProvider.customers.length;
                    int totalItemsCount = itemProvider.items.length;
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 2.5,
                            children: [
                              _InteractiveStatCard(
                                title: AppLocalizations.of(context).translate('customers'),
                                value: totalCustomers.toString(),
                                icon: Icons.people,
                                color: const Color(0xFF2196F3),
                              ),
                              _InteractiveStatCard(
                                title: AppLocalizations.of(context).translate('items'),
                                value: totalItemsCount.toString(),
                                icon: Icons.inventory,
                                color: const Color(0xFFFF9800),
                              ),
                              _InteractiveStatCard(
                                title: AppLocalizations.of(context).translate('bills'),
                                value: billProvider.bills.length.toString(),
                                icon: Icons.receipt,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(
                            AppLocalizations.of(context).translate('bills_history') + ' (Recent)',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildRecentBillsTable(billProvider.bills.reversed.take(5).toList(), context),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBillsTable(List<Bill> recentBills, BuildContext context) {
    if (recentBills.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).translate('no_bills')));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          columns: [
            DataColumn(label: Text('ID', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context).translate('customer_name'), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text(AppLocalizations.of(context).translate('total'), style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: recentBills.map((bill) {
            return DataRow(cells: [
              DataCell(Text(bill.id.toString())),
              DataCell(Text(bill.customerName)),
              DataCell(Text('${bill.date.year}-${bill.date.month.toString().padLeft(2, '0')}-${bill.date.day.toString().padLeft(2, '0')}')),
              DataCell(Text(bill.total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _InteractiveStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InteractiveStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  State<_InteractiveStatCard> createState() => _InteractiveStatCardState();
}

class _InteractiveStatCardState extends State<_InteractiveStatCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, _isHovering ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isHovering ? 0.3 : 0.05),
              blurRadius: _isHovering ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(_isHovering ? 20 : 16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 36),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: _isHovering ? 32 : 28,
                      color: const Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
