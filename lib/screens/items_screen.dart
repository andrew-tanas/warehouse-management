import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../widgets/app_navigation.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'item_history_screen.dart';
import '../providers/locale_provider.dart';
import '../utils/pdf_generator.dart';
import '../utils/sort_utils.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  String _searchQuery = '';
  String? _filterCategory;
  int? _sortColumnIndex = 1;
  bool _sortAscending = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  int? _editingItemId;
  String? _editingPriceType;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<ItemProvider>(context, listen: false).loadItems(),
    );
  }

  void _showItemDialog([Item? item]) {
    final formKey = GlobalKey<FormState>();
    String name = item?.name ?? '';
    String size = item?.size ?? '';
    double retailPrice = item?.retailPrice ?? 0.0;
    double wholesalePrice = item?.wholesalePrice ?? 0.0;
    double? customPrice = item?.customPrice;
    double stockAmount = item?.stockAmount ?? 0.0;
    String category = item?.category ?? 'men';

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
                item == null
                    ? AppLocalizations.of(context).translate('add_item')
                    : AppLocalizations.of(context).translate('edit'),
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
                    TextFormField(
                      initialValue: name,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('name'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => name = val!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: size,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('size'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => size = val!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('category'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: ['men', 'women', 'boys', 'girls'].map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(
                            AppLocalizations.of(context).translate(val),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            category = val;
                          });
                        }
                      },
                      onSaved: (val) => category = val ?? 'men',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: retailPrice.toString(),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).translate('retail_price'),
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
                            onSaved: (val) =>
                                retailPrice = double.tryParse(val!) ?? 0.0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: wholesalePrice.toString(),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).translate('wholesale_price'),
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
                            onSaved: (val) =>
                                wholesalePrice = double.tryParse(val!) ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: customPrice?.toString() ?? '',
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('custom_price'),
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
                      onSaved: (val) =>
                          customPrice = (val == null || val.isEmpty)
                          ? null
                          : double.tryParse(val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: stockAmount.toString(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('stock_amount'),
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
                      onSaved: (val) =>
                          stockAmount = double.tryParse(val!) ?? 0.0,
                    ),
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final provider = Provider.of<ItemProvider>(
                    context,
                    listen: false,
                  );
                  final exists = provider.items.any(
                    (i) =>
                        i.name.trim().toLowerCase() ==
                            name.trim().toLowerCase() &&
                        i.size.trim().toLowerCase() ==
                            size.trim().toLowerCase() &&
                        i.id != item?.id,
                  );

                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Item with this Name and Size already exists',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newItem = Item(
                    id: item?.id,
                    name: name,
                    size: size,
                    category: category,
                    retailPrice: retailPrice,
                    wholesalePrice: wholesalePrice,
                    customPrice: customPrice,
                    stockAmount: stockAmount,
                  );
                  
                  try {
                    if (item == null) {
                      await provider.addItem(newItem);
                    } else {
                      await provider.updateItem(newItem);
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save item: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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

  void _showStockDialog(Item item, bool isAdding) {
    final formKey = GlobalKey<FormState>();
    double amount = 0.0;
    DateTime? selectedDate;
    String note = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isAdding ? '+' : '-'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('stock_amount'),
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
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => amount = double.tryParse(val!) ?? 0.0,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (val) => note = val ?? '',
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
                        decoration: const InputDecoration(
                          labelText: 'Date (Optional)',
                          border: OutlineInputBorder(),
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
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      double change = isAdding ? amount : -amount;
                      Provider.of<ItemProvider>(
                        context,
                        listen: false,
                      ).updateStock(
                        item.id!,
                        change,
                        date: selectedDate,
                        note: note.isEmpty
                            ? (isAdding ? 'Added manually' : 'Reduced manually')
                            : note,
                      );
                      Navigator.pop(context);
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

  Widget _buildPriceCell(
    Item item,
    String priceType,
    double? price,
    Color color,
  ) {
    if (_editingItemId == item.id && _editingPriceType == priceType) {
      return SizedBox(
        width: 80,
        child: TextFormField(
          initialValue: price?.toStringAsFixed(2) ?? '',
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
          ],
          onFieldSubmitted: (val) {
            _updateInlinePrice(item, priceType, val);
          },
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );
    }

    return InkWell(
      onDoubleTap: () {
        setState(() {
          _editingItemId = item.id;
          _editingPriceType = priceType;
        });
      },
      child: Text(
        price != null ? price.toStringAsFixed(2) : '-',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _updateInlinePrice(Item item, String priceType, String val) {
    double newPrice = double.tryParse(val) ?? 0.0;
    final updatedItem = Item(
      id: item.id,
      name: item.name,
      size: item.size,
      category: item.category,
      retailPrice: priceType == 'retail' ? newPrice : item.retailPrice,
      wholesalePrice: priceType == 'wholesale' ? newPrice : item.wholesalePrice,
      customPrice: priceType == 'custom'
          ? (val.isEmpty ? null : newPrice)
          : item.customPrice,
      stockAmount: item.stockAmount,
    );
    Provider.of<ItemProvider>(context, listen: false).updateItem(updatedItem);
    setState(() {
      _editingItemId = null;
      _editingPriceType = null;
    });
  }

  void _onSortChanged(int? newIndex) {
    if (newIndex != null) {
      setState(() {
        _sortColumnIndex = newIndex;
      });
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  void _showPrintDialog(List<Item> items) {
    List<String> priceColumns = [
      'retail_price',
      'wholesale_price',
      'custom_price',
    ];
    List<String> selectedPrices = ['retail_price'];
    List<String> categories = ['men', 'women', 'boys', 'girls'];
    List<String> selectedCategories = List.from(categories);
    List<Item> selectedItemsForPrint = [];
    TextEditingController? autocompleteController;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).translate('print_pdf')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<Item>(
                      displayStringForOption: (Item option) =>
                          '${option.name} - ${option.size}',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        var filtered = items.where((item) {
                          if (!selectedCategories.contains(item.category)) return false;
                          if (selectedItemsForPrint.any((i) => i.id == item.id)) return false;
                          if (textEditingValue.text.isEmpty) return true;
                          return ('${item.name} - ${item.size}')
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        }).toList();
                        return filtered;
                      },
                      onSelected: (Item selection) {
                        setState(() {
                          if (!selectedItemsForPrint.any(
                            (i) => i.id == selection.id,
                          )) {
                            selectedItemsForPrint.add(selection);
                          }
                          Future.delayed(const Duration(milliseconds: 50), () {
                            autocompleteController?.clear();
                          });
                        });
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            autocompleteController = textEditingController;
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onTap: () {
                                if (textEditingController.text.isEmpty) {
                                  // Trigger the autocomplete options by setting and clearing text
                                  textEditingController.text = ' ';
                                  textEditingController.selection =
                                      TextSelection.collapsed(offset: 0);
                                  Future.microtask(() {
                                    textEditingController.text = '';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText:
                                    '${AppLocalizations.of(context).translate('select_item')} (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textEditingController.clear();
                                  },
                                ),
                              ),
                            );
                          },
                    ),
                    if (selectedItemsForPrint.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Wrap(
                          spacing: 8,
                          children: selectedItemsForPrint.map((item) {
                            return Chip(
                              label: Text('${item.name} - ${item.size}'),
                              onDeleted: () {
                                setState(() {
                                  selectedItemsForPrint.removeWhere(
                                    (i) => i.id == item.id,
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Select Prices to Print:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...priceColumns.map((col) {
                      return CheckboxListTile(
                        title: Text(
                          AppLocalizations.of(context).translate(col),
                        ),
                        value: selectedPrices.contains(col),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedPrices.add(col);
                              selectedPrices.sort(
                                (a, b) => priceColumns
                                    .indexOf(a)
                                    .compareTo(priceColumns.indexOf(b)),
                              );
                            } else {
                              if (selectedPrices.length > 1) {
                                selectedPrices.remove(col);
                              }
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context).translate('category')}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          children: categories.map((cat) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: selectedCategories.contains(cat),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedCategories.add(cat);
                                      } else {
                                        selectedCategories.remove(cat);
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  AppLocalizations.of(context).translate(cat),
                                ),
                                const SizedBox(width: 8),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
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
                  onPressed: () {
                    List<Item> itemsToPrint = selectedItemsForPrint.isNotEmpty
                        ? selectedItemsForPrint
                        : items;
                    itemsToPrint = itemsToPrint
                        .where(
                          (item) => selectedCategories.contains(item.category),
                        )
                        .toList();
                    if (itemsToPrint.isEmpty) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context).translate('no_items'),
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    PdfGenerator.printItemsList(context, itemsToPrint, [
                      'name',
                      'size',
                      ...selectedPrices,
                    ]);
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
    return AppNavigation(
      selectedIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).translate('items_management'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showItemDialog(),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).translate('add_item')),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _filterCategory,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('category'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.filter_list),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...['men', 'women', 'boys', 'girls'].map((String val) {
                          return DropdownMenuItem<String?>(
                            value: val,
                            child: Text(
                              AppLocalizations.of(context).translate(val),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterCategory = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search items...',
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
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _sortColumnIndex,
                        hint: const Text('Sort by...'),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('ID')),
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              '${AppLocalizations.of(context).translate('category')} > ${AppLocalizations.of(context).translate('name')} > ${AppLocalizations.of(context).translate('size')}',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(
                              AppLocalizations.of(context).translate('name'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text(
                              AppLocalizations.of(context).translate('size'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('retail_price'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('wholesale_price'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 6,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('custom_price'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('stock_amount'),
                            ),
                          ),
                        ],
                        onChanged: _onSortChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      onPressed: _toggleSortOrder,
                      tooltip: 'Toggle Sort Order',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ItemProvider>(
                    builder: (context, provider, child) {
                      List<Item> itemsToPrint = provider.items.where((item) {
                        return item.name.toLowerCase().contains(_searchQuery) ||
                            item.size.toLowerCase().contains(_searchQuery) ||
                            item.id.toString().contains(_searchQuery);
                      }).toList();

                      if (_sortColumnIndex != null) {
                        itemsToPrint.sort((a, b) {
                          int cmp = 0;
                          switch (_sortColumnIndex) {
                            case 0:
                              cmp = a.id!.compareTo(b.id!);
                              break;
                            case 1:
                              cmp = compareCategories(a.category, b.category);
                              if (cmp == 0) {
                                cmp = a.name.compareTo(b.name);
                                if (cmp == 0) {
                                  cmp = compareSizes(a.size, b.size);
                                }
                              }
                              break;
                            case 2:
                              cmp = a.name.compareTo(b.name);
                              break;
                            case 3:
                              cmp = compareSizes(a.size, b.size);
                              break;
                            case 4:
                              cmp = a.retailPrice.compareTo(b.retailPrice);
                              break;
                            case 5:
                              cmp = a.wholesalePrice.compareTo(b.wholesalePrice);
                              break;
                            case 6:
                              cmp = (a.customPrice ?? 0).compareTo(
                                b.customPrice ?? 0,
                              );
                              break;
                            case 7:
                              cmp = a.stockAmount.compareTo(b.stockAmount);
                              break;
                          }
                          return _sortAscending ? cmp : -cmp;
                        });
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: itemsToPrint.isEmpty
                              ? null
                              : () => _showPrintDialog(itemsToPrint),
                          tooltip: AppLocalizations.of(
                            context,
                          ).translate('print_pdf'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ItemProvider>(
                builder: (context, provider, child) {
                  if (provider.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).translate('no_items'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  List<Item> filteredItems = provider.items.where((item) {
                    if (_filterCategory != null &&
                        item.category != _filterCategory)
                      return false;
                    return item.name.toLowerCase().contains(_searchQuery) ||
                        item.size.toLowerCase().contains(_searchQuery) ||
                        item.id.toString().contains(_searchQuery);
                  }).toList();

                  if (_sortColumnIndex != null) {
                    filteredItems.sort((a, b) {
                      int cmp = 0;
                      switch (_sortColumnIndex) {
                        case 0:
                          cmp = a.id!.compareTo(b.id!);
                          break;
                        case 1:
                          cmp = compareCategories(a.category, b.category);
                          if (cmp == 0) {
                            cmp = a.name.compareTo(b.name);
                            if (cmp == 0) {
                              cmp = compareSizes(a.size, b.size);
                            }
                          }
                          break;
                        case 2:
                          cmp = a.name.compareTo(b.name);
                          break;
                        case 3:
                          cmp = compareSizes(a.size, b.size);
                          break;
                        case 4:
                          cmp = a.retailPrice.compareTo(b.retailPrice);
                          break;
                        case 5:
                          cmp = a.wholesalePrice.compareTo(b.wholesalePrice);
                          break;
                        case 6:
                          cmp = (a.customPrice ?? 0).compareTo(
                            b.customPrice ?? 0,
                          );
                          break;
                        case 7:
                          cmp = a.stockAmount.compareTo(b.stockAmount);
                          break;
                      }
                      return _sortAscending ? cmp : -cmp;
                    });
                  } else {
                    filteredItems.sort((a, b) {
                      int cmp = compareCategories(a.category, b.category);
                      if (cmp == 0) cmp = a.name.compareTo(b.name);
                      return cmp;
                    });
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 0.0,
                    ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 80.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                    cardColor: Colors.transparent,
                                    cardTheme: const CardThemeData(
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  child: PaginatedDataTable(
                                    key: ValueKey('$_searchQuery-$_filterCategory-$_sortColumnIndex'),
                                    showCheckboxColumn: false,
                                    rowsPerPage: _rowsPerPage,
                                    availableRowsPerPage: const [10, 20, 50, 100],
                                    onRowsPerPageChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _rowsPerPage = val;
                                        });
                                      }
                                    },
                                    columns: [
                                      const DataColumn(
                                        label: Text(
                                          'ID',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('category'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('name'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('size'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('retail_price'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('wholesale_price'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('custom_price'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('stock_amount'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).translate('actions'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    source: ItemDataSource(
                                      filteredItems,
                                      context,
                                      this,
                                      provider,
                                    ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemDataSource extends DataTableSource {
  final List<Item> items;
  final BuildContext context;
  final _ItemsScreenState state;
  final ItemProvider provider;

  ItemDataSource(this.items, this.context, this.state, this.provider);

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final item = items[index];
    return DataRow(
      onSelectChanged: (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemHistoryScreen(item: item)),
        );
      },
      cells: [
        DataCell(Text(item.id.toString())),
        DataCell(Text(AppLocalizations.of(context).translate(item.category))),
        DataCell(
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        DataCell(Text(item.size)),
        DataCell(
          state._buildPriceCell(item, 'retail', item.retailPrice, Colors.green),
        ),
        DataCell(
          state._buildPriceCell(
            item,
            'wholesale',
            item.wholesalePrice,
            Colors.blue,
          ),
        ),
        DataCell(
          state._buildPriceCell(
            item,
            'custom',
            item.customPrice,
            Colors.orange,
          ),
        ),
        DataCell(Text(item.stockAmount.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                tooltip: 'Add Stock',
                onPressed: () => state._showStockDialog(item, true),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.orange,
                ),
                tooltip: 'Reduce Stock',
                onPressed: () => state._showStockDialog(item, false),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                tooltip: 'Edit',
                onPressed: () => state._showItemDialog(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        AppLocalizations.of(context).translate('delete'),
                      ),
                      content: Text(
                        'Are you sure you want to delete ${item.name}?',
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
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            provider.deleteItem(item.id!);
                            Navigator.pop(context);
                          },
                          child: Text(
                            AppLocalizations.of(context).translate('delete'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => items.length;
  @override
  int get selectedRowCount => 0;
}
