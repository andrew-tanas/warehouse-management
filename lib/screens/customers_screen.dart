import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/bill_provider.dart';
import '../widgets/app_navigation.dart';
import '../l10n/app_localizations.dart';
import 'customer_history_screen.dart';
import 'package:flutter/services.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  void _showAddEditDialog(BuildContext context, [Customer? customer]) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    String genre = customer?.genre ?? 'wholesaler';
    final debtController = TextEditingController(
      text: customer?.totalDebt.toString() ?? '0.0',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                customer == null
                    ? AppLocalizations.of(context).translate('add_customer')
                    : AppLocalizations.of(context).translate('edit'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('customer_name'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: genre,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('genre'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'wholesaler',
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('wholesaler'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'retail trader',
                          child: Text(
                            AppLocalizations.of(context).translate('retail'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text(
                            AppLocalizations.of(context).translate('normal'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => genre = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: debtController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('total_debt'),
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
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final cName = nameController.text.trim();
                    if (cName.isEmpty) return;

                    final provider = Provider.of<CustomerProvider>(context, listen: false);
                    final exists = provider.customers.any((c) => 
                      c.name.trim().toLowerCase() == cName.toLowerCase() && c.id != customer?.id
                    );

                    if (exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context).translate('customer_name') + ' already exists'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newCustomer = Customer(
                      id: customer?.id,
                      name: cName,
                      genre: genre,
                      totalDebt: double.tryParse(debtController.text.trim()) ?? 0.0,
                    );
                    if (customer == null) {
                      provider.addCustomer(newCustomer);
                    } else {
                      provider.updateCustomer(newCustomer);
                    }
                    Navigator.pop(context);
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

  void _showPayDialog(BuildContext context, Customer customer) {
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
                              : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
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
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (amount > 0) {
                      Provider.of<CustomerProvider>(
                        context,
                        listen: false,
                      ).addPayment(
                        customer.id!,
                        amount,
                        noteController.text.trim(),
                        selectedDate,
                      );
                      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return AppNavigation(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(context),
          backgroundColor: const Color(0xFF6C63FF),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            AppLocalizations.of(context).translate('add_customer'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('customers_management'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<CustomerProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.customers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).translate('no_customers'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    List<Customer> filteredCustomers = provider.customers.where(
                      (customer) {
                        return customer.name.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            customer.id.toString().contains(_searchQuery);
                      },
                    ).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        String localizedGenre = customer.genre;
                        if (customer.genre == 'wholesaler') {
                          localizedGenre = AppLocalizations.of(
                            context,
                          ).translate('wholesaler');
                        } else if (customer.genre == 'normal')
                          localizedGenre = AppLocalizations.of(
                            context,
                          ).translate('normal');
                        else
                          localizedGenre = AppLocalizations.of(
                            context,
                          ).translate('retail');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerHistoryScreen(customer: customer),
                                ),
                              );
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.1),
                                child: const Icon(
                                  Icons.business_center,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  localizedGenre.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('total_debt'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        customer.totalDebt > 0
                                            ? '-${customer.totalDebt.abs().toStringAsFixed(2)}'
                                            : '+${customer.totalDebt.abs().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: customer.totalDebt > 0
                                              ? Colors.redAccent
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.payment,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _showPayDialog(context, customer),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    ).translate('pay'),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showAddEditDialog(context, customer),
                                    tooltip: 'Edit Customer',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      if (customer.id != null) {
                                        _confirmDelete(
                                          context,
                                          provider,
                                          customer,
                                        );
                                      }
                                    },
                                    tooltip: 'Delete Customer',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CustomerProvider provider,
    Customer customer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete')),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteCustomer(customer.id!);
              if (context.mounted) {
                Provider.of<BillProvider>(context, listen: false).loadBills();
                Navigator.pop(context);
              }
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
}
