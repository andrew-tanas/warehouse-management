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

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  String _searchQuery = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;

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

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final provider = Provider.of<ItemProvider>(context, listen: false);
                  final exists = provider.items.any((i) => 
                    i.name.trim().toLowerCase() == name.trim().toLowerCase() && 
                    i.size.trim().toLowerCase() == size.trim().toLowerCase() && 
                    i.id != item?.id
                  );

                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Item with this Name and Size already exists'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newItem = Item(
                    id: item?.id,
                    name: name,
                    size: size,
                    retailPrice: retailPrice,
                    wholesalePrice: wholesalePrice,
                    customPrice: customPrice,
                    stockAmount: stockAmount,
                  );
                  if (item == null) {
                    provider.addItem(newItem);
                  } else {
                    provider.updateItem(newItem);
                  }
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
    List<String> availableColumns = [
      'id',
      'name',
      'size',
      'retail_price',
      'wholesale_price',
      'custom_price',
      'stock_amount',
    ];
    List<String> selectedColumns = ['id', 'name', 'size', 'stock_amount'];
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
                        if (textEditingValue.text.isEmpty) {
                          return items;
                        }
                        return items.where(
                          (item) => ('${item.name} - ${item.size}')
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()),
                        );
                      },
                      onSelected: (Item selection) {
                        setState(() {
                          if (!selectedItemsForPrint.any(
                            (i) => i.id == selection.id,
                          )) {
                            selectedItemsForPrint.add(selection);
                          }
                          // Clear the text field after a tiny delay so Autocomplete finishes its internal update
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
                                  onPressed: () =>
                                      textEditingController.clear(),
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
                    ...availableColumns.map((col) {
                      return CheckboxListTile(
                        title: Text(
                          col == 'id'
                              ? 'ID'
                              : AppLocalizations.of(context).translate(col),
                        ),
                        value: selectedColumns.contains(col),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedColumns.add(col);
                              // Sort based on original order
                              selectedColumns.sort(
                                (a, b) => availableColumns
                                    .indexOf(a)
                                    .compareTo(availableColumns.indexOf(b)),
                              );
                            } else {
                              if (selectedColumns.length > 1) {
                                selectedColumns.remove(col);
                              }
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    List<Item> finalItemsToPrint =
                        selectedItemsForPrint.isNotEmpty
                        ? selectedItemsForPrint
                        : items;
                    await PdfGenerator.printItemsList(
                      context,
                      finalItemsToPrint,
                      selectedColumns,
                    );
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
                              AppLocalizations.of(context).translate('name'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(
                              AppLocalizations.of(context).translate('size'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('retail_price'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('wholesale_price'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('custom_price'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 6,
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
                              cmp = a.name.compareTo(b.name);
                              break;
                            case 2:
                              cmp = a.size.compareTo(b.size);
                              break;
                            case 3:
                              cmp = a.retailPrice.compareTo(b.retailPrice);
                              break;
                            case 4:
                              cmp = a.wholesalePrice.compareTo(
                                b.wholesalePrice,
                              );
                              break;
                            case 5:
                              cmp = (a.customPrice ?? 0).compareTo(
                                b.customPrice ?? 0,
                              );
                              break;
                            case 6:
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
                          cmp = a.name.compareTo(b.name);
                          break;
                        case 2:
                          cmp = a.size.compareTo(b.size);
                          break;
                        case 3:
                          cmp = a.retailPrice.compareTo(b.retailPrice);
                          break;
                        case 4:
                          cmp = a.wholesalePrice.compareTo(b.wholesalePrice);
                          break;
                        case 5:
                          cmp = (a.customPrice ?? 0).compareTo(
                            b.customPrice ?? 0,
                          );
                          break;
                        case 6:
                          cmp = a.stockAmount.compareTo(b.stockAmount);
                          break;
                      }
                      return _sortAscending ? cmp : -cmp;
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
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.minWidth),
                                  child: DataTable(
                                    showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.resolveWith(
                                (states) => Colors.grey.shade50,
                              ),
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
                              rows: filteredItems.map((item) {
                                return DataRow(
                                  onSelectChanged: (_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ItemHistoryScreen(item: item),
                                      ),
                                    );
                                  },
                                  cells: [
                                    DataCell(Text(item.id.toString())),
                                    DataCell(
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(item.size)),
                                    DataCell(
                                      _buildPriceCell(
                                        item,
                                        'retail',
                                        item.retailPrice,
                                        Colors.green,
                                      ),
                                    ),
                                    DataCell(
                                      _buildPriceCell(
                                        item,
                                        'wholesale',
                                        item.wholesalePrice,
                                        Colors.blue,
                                      ),
                                    ),
                                    DataCell(
                                      _buildPriceCell(
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
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.green,
                                            ),
                                            tooltip: 'Add Stock',
                                            onPressed: () =>
                                                _showStockDialog(item, true),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.orange,
                                            ),
                                            tooltip: 'Reduce Stock',
                                            onPressed: () =>
                                                _showStockDialog(item, false),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.indigo,
                                            ),
                                            tooltip: 'Edit',
                                            onPressed: () =>
                                                _showItemDialog(item),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Delete',
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
                                                    'Are you sure you want to delete ${item.name}?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
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
                                                        provider.deleteItem(
                                                          item.id!,
                                                        );
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
                                    ),
                                  ],
                                );
                              }).toList(),
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
