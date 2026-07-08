import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../providers/bill_provider.dart';
import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/draft_service.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  List<Customer> _customers = [];
  List<Item> _items = [];

  Customer? _selectedCustomer;
  List<BillItem> _billItems = [];
  double _discountPercent = 0.0;
  final TextEditingController _discountController = TextEditingController();
  DateTime? _selectedDate;

  String _priceTier = 'wholesale';

  Bill? _editingBill;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Bill) {
        _editingBill = args;
      } else if (args is Customer) {
        _selectedCustomer = args;
      } else if (args is DraftBill) {
        _selectedCustomer = args.customer;
        _billItems = List.from(args.items);
        _discountPercent = args.discountPercent;
        _discountController.text = _discountPercent.toStringAsFixed(2);
      }
      _isInit = true;
    }
  }

  Future<void> _loadData() async {
    final customers = await DatabaseHelper.instance.getCustomers();
    final items = await DatabaseHelper.instance.getItems();
    items.sort((a, b) {
      int cmp = a.name.compareTo(b.name);
      if (cmp == 0) {
        return a.size.compareTo(b.size);
      }
      return cmp;
    });

    if (_editingBill != null) {
      final billItems = await DatabaseHelper.instance.getBillItems(
        _editingBill!.id!,
      );
      setState(() {
        _customers = customers;
        _items = items;
        try {
          _selectedCustomer = customers.firstWhere(
            (v) => v.id == _editingBill!.customerId,
          );
        } catch (e) {}
        _selectedDate = _editingBill!.date;
        _billItems = billItems;
        double sub = _editingBill!.total + _editingBill!.discountApplied;
        _discountPercent = sub > 0
            ? (_editingBill!.discountApplied / sub) * 100
            : 0.0;
        _discountController.text = _discountPercent.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _customers = customers;
        _items = items;
        if (_selectedCustomer != null) {
          try {
            _selectedCustomer = customers.firstWhere(
              (v) => v.id == _selectedCustomer!.id,
            );
          } catch (e) {}
        }
      });
    }
  }

  double get _subtotal {
    return _billItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _discountAmount {
    return _subtotal * (_discountPercent / 100);
  }

  double get _total {
    return _subtotal - _discountAmount;
  }

  void _showAddItemDialog() {
    final formKey = GlobalKey<FormState>();
    Item? selectedItem;
    double quantityDozens = 1.0;
    String itemNote = '';

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
                AppLocalizations.of(context).translate('add_item'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Autocomplete<Item>(
                          displayStringForOption: (Item option) =>
                              '${option.name} - ${option.size}',
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _items;
                            }
                            return _items.where(
                              (item) => ('${item.name} - ${item.size}')
                                  .toLowerCase()
                                  .contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                            );
                          },
                          onSelected: (Item selection) {
                            setDialogState(() {
                              selectedItem = selection;
                            });
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(
                                      context,
                                    ).translate('select_item'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    suffixIcon: const Icon(Icons.search),
                                  ),
                                  validator: (val) => selectedItem == null
                                      ? 'Please select an item'
                                      : null,
                                  onChanged: (val) {
                                    if (selectedItem != null &&
                                        '${selectedItem!.name} - ${selectedItem!.size}' !=
                                            val) {
                                      setDialogState(() {
                                        selectedItem = null;
                                      });
                                    }
                                  },
                                );
                              },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: '1.0',
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('quantity_dozens'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*'),
                            ),
                          ],
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (double.tryParse(val) == null)
                              return 'Invalid number';
                            return null;
                          },
                          onSaved: (val) => quantityDozens = double.parse(val!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText:
                                '${AppLocalizations.of(context).translate('note')} (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onSaved: (val) => itemNote = val?.trim() ?? '',
                        ),
                        if (selectedItem != null &&
                            _selectedCustomer != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      double price = 0;
                                      if (_selectedCustomer!.genre ==
                                          'wholesaler') {
                                        price = selectedItem!.wholesalePrice;
                                      } else if (_selectedCustomer!.genre ==
                                              'retail' ||
                                          _selectedCustomer!.genre ==
                                              'retail trader') {
                                        price = selectedItem!.retailPrice;
                                      } else {
                                        if (_priceTier == 'wholesale') {
                                          price = selectedItem!.wholesalePrice;
                                        } else if (_priceTier == 'retail')
                                          price = selectedItem!.retailPrice;
                                        else if (_priceTier == 'custom')
                                          price =
                                              selectedItem!.customPrice ??
                                              selectedItem!.retailPrice;
                                      }
                                      return Text(
                                        '${AppLocalizations.of(context).translate('price_applied')}: ${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        _selectedCustomer != null) {
                      formKey.currentState!.save();

                      double price = 0;
                      if (_selectedCustomer!.genre == 'wholesaler') {
                        price = selectedItem!.wholesalePrice;
                      } else if (_selectedCustomer!.genre == 'retail' ||
                          _selectedCustomer!.genre == 'retail trader') {
                        price = selectedItem!.retailPrice;
                      } else {
                        if (_priceTier == 'wholesale') {
                          price = selectedItem!.wholesalePrice;
                        } else if (_priceTier == 'retail')
                          price = selectedItem!.retailPrice;
                        else if (_priceTier == 'custom')
                          price =
                              selectedItem!.customPrice ??
                              selectedItem!.retailPrice;
                      }

                      setState(() {
                        _billItems.add(
                          BillItem(
                            billId: _editingBill?.id ?? 0,
                            itemId: selectedItem!.id!,
                            itemName: selectedItem!.name,
                            itemSize: selectedItem!.size,
                            itemPrice: price,
                            quantityDozens: quantityDozens,
                            total: price * quantityDozens,
                            note: itemNote.isEmpty ? null : itemNote,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context).translate('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditItemDialog(int index) {
    final item = _billItems[index];
    final formKey = GlobalKey<FormState>();
    double quantityDozens = item.quantityDozens;
    String itemNote = item.note ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.of(context).translate('edit'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: quantityDozens.toString(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('quantity_dozens'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d*'),
                        ),
                      ],
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null)
                          return 'Invalid number';
                        return null;
                      },
                      onSaved: (val) => quantityDozens = double.parse(val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: itemNote,
                      decoration: InputDecoration(
                        labelText:
                            '${AppLocalizations.of(context).translate('note')} (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onSaved: (val) => itemNote = val?.trim() ?? '',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).translate('cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  setState(() {
                    _billItems[index].quantityDozens = quantityDozens;
                    _billItems[index].total =
                        _billItems[index].itemPrice * quantityDozens;
                    _billItems[index].note = itemNote.isEmpty ? null : itemNote;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context).translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _saveBill() async {
    if (_selectedCustomer == null || _billItems.isEmpty) return;

    final bill = Bill(
      id: _editingBill?.id,
      date: _selectedDate ?? DateTime.now(),
      customerId: _selectedCustomer!.id!,
      customerName: _selectedCustomer!.name,
      total: _total,
      discountApplied: _discountAmount,
    );

    if (_editingBill != null) {
      await Provider.of<BillProvider>(
        context,
        listen: false,
      ).updateExistingBill(bill, _billItems, _editingBill!);
    } else {
      await Provider.of<BillProvider>(
        context,
        listen: false,
      ).addBill(bill, _billItems);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('bill_created')),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWholesalerOrNormal =
        _selectedCustomer?.genre == 'wholesaler' ||
        _selectedCustomer?.genre == 'normal';
    bool isNormal = _selectedCustomer?.genre == 'normal';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && _editingBill == null && result != true) {
          if (_billItems.isNotEmpty || _selectedCustomer != null) {
            final draftId = (ModalRoute.of(context)?.settings.arguments is DraftBill)
                ? (ModalRoute.of(context)!.settings.arguments as DraftBill).id
                : DateTime.now().millisecondsSinceEpoch.toString();
                
            DraftService.saveDraft(DraftBill(
              id: draftId,
              customer: _selectedCustomer,
              items: _billItems,
              discountPercent: _discountPercent,
              dateCreated: DateTime.now(),
            ));
          }
        } else if (didPop && result == true) {
           // If saved successfully, and we were editing a draft, delete the draft
           if (ModalRoute.of(context)?.settings.arguments is DraftBill) {
             DraftService.deleteDraft((ModalRoute.of(context)!.settings.arguments as DraftBill).id);
           }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('create_bill'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Details & Items list
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('customer_info'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Customer>(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).translate('select_customer'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            initialValue: _selectedCustomer,
                            items: _customers.map((v) {
                              String localizedGenre = v.genre;
                              if (v.genre == 'wholesaler') {
                                localizedGenre = AppLocalizations.of(
                                  context,
                                ).translate('wholesaler');
                              } else if (v.genre == 'normal')
                                localizedGenre = AppLocalizations.of(
                                  context,
                                ).translate('normal');
                              else
                                localizedGenre = AppLocalizations.of(
                                  context,
                                ).translate('retail');

                              return DropdownMenuItem<Customer>(
                                value: v,
                                child: Text('${v.name} ($localizedGenre)'),
                              );
                            }).toList(),
                            onChanged: null,
                          ),
                          if (isNormal) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                ).translate('price_tier'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              initialValue: _priceTier,
                              items: [
                                DropdownMenuItem(
                                  value: 'wholesale',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('wholesaler'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'retail',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('retail'),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'custom',
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('custom_price'),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _priceTier = val;
                                    _billItems
                                        .clear(); // Clear because pricing changed
                                  });
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    _selectedDate ?? DateTime.now(),
                                  ),
                                );
                                if (time != null) {
                                  setState(() {
                                    _selectedDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                } else {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Select Date (Defaults to Now)'
                                    : DateFormat(
                                        'yyyy-MM-dd HH:mm',
                                      ).format(_selectedDate!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('bill_items'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _selectedCustomer == null
                                    ? null
                                    : _showAddItemDialog,
                                icon: const Icon(Icons.add),
                                label: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('add_item'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_billItems.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('no_items_added'),
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _billItems.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final item = _billItems[index];
                                return ListTile(
                                  title: Text(
                                    '${item.itemName} - ${item.itemSize}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.quantityDozens} Dozens @ ${item.itemPrice.toStringAsFixed(2)}',
                                      ),
                                      if (item.note != null &&
                                          item.note!.isNotEmpty)
                                        Text(
                                          '${AppLocalizations.of(context).translate('note')}: ${item.note}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.total.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _showEditItemDialog(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).translate('delete'),
                                              ),
                                              content: Text(
                                                'Are you sure you want to remove ${item.itemName} from the bill?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    ).translate('cancel'),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _billItems.removeAt(
                                                        index,
                                                      );
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    ).translate('delete'),
                                                    style: const TextStyle(
                                                      color: Colors.white,
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
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Summary & Checkout
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('summary'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('subtotal'),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        _subtotal.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('discount_percent'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _discountController,
                          decoration: const InputDecoration(
                            prefixText: '% ',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _discountPercent = double.tryParse(val) ?? 0.0;
                              if (_discountPercent > 100)
                                _discountPercent = 100;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_discountPercent > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('discount'),
                          style: const TextStyle(color: Colors.red),
                        ),
                        Text(
                          '-${_discountAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('total'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _total.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          (_selectedCustomer == null || _billItems.isEmpty)
                          ? null
                          : _saveBill,
                      child: Text(
                        AppLocalizations.of(context).translate('save'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
