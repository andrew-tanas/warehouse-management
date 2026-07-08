import re

def find_matching_brace(text, start_index, open_brace='{', close_brace='}'):
    count = 0
    for i in range(start_index, len(text)):
        if text[i] == open_brace:
            count += 1
        elif text[i] == close_brace:
            count -= 1
            if count == 0:
                return i
    return -1

with open('lib/screens/items_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add Category Filter UI
search_bar_regex = r"(Expanded\(\s*child: TextField\(\s*onChanged: \(value\) \{\s*setState\(\(\) \{\s*_searchQuery = value.toLowerCase\(\);\s*\}\);\s*\},\s*decoration: InputDecoration\(.*?\),\s*\),\s*\),)"
category_filter_ui = """Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _filterCategory,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).translate('category'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.filter_list),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All')),
                                ...['men', 'women', 'kids'].map((String val) {
                                  return DropdownMenuItem<String?>(
                                    value: val,
                                    child: Text(AppLocalizations.of(context).translate(val)),
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
                          """
if '_filterCategory' not in content:
    content = re.sub(r"String _searchQuery = '';", r"String _searchQuery = '';\n  String? _filterCategory;", content, count=1)
    content = re.sub(search_bar_regex, category_filter_ui + r"\1", content, flags=re.DOTALL)

# 2. Update _showItemDialog with category field
dialog_match = re.search(r"void _showItemDialog\(\[Item\? item\]\) \{.*?(?=showDialog\()", content, re.DOTALL)
if dialog_match and 'String category =' not in dialog_match.group(0):
    dialog_code = dialog_match.group(0)
    dialog_code_new = dialog_code.replace("double stockAmount = item?.stockAmount ?? 0.0;", "double stockAmount = item?.stockAmount ?? 0.0;\n    String category = item?.category ?? 'men';")
    content = content.replace(dialog_code, dialog_code_new)

form_match = re.search(r"onSaved: \(val\) => size = val!,\n\s*\),", content, re.DOTALL)
if form_match and 'DropdownButtonFormField' not in form_match.group(0):
    form_insert = form_match.group(0) + """
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).translate('category'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: ['men', 'women', 'kids'].map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(AppLocalizations.of(context).translate(val)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) category = val;
                      },
                      onSaved: (val) => category = val ?? 'men',
                    ),"""
    content = content.replace(form_match.group(0), form_insert)

new_item_match = re.search(r"final newItem = Item\(\s*id: item\?\.id,\s*name: name,\s*size: size,", content)
if new_item_match and 'category: category' not in new_item_match.group(0):
    content = content.replace(new_item_match.group(0), new_item_match.group(0) + "\n                    category: category,")

# 3. Add filter by category in filteredItems
filtered_items_regex = r"(List<Item> filteredItems = provider.items.where\(\(item\) \{)(.*?)(return item.name.toLowerCase\(\).contains\(_searchQuery\))(.*?\n\s*\}\).toList\(\);)"
def replace_filter(match):
    return match.group(1) + "\n                    if (_filterCategory != null && item.category != _filterCategory) return false;\n                    " + match.group(3) + match.group(4)
if 'item.category != _filterCategory' not in content:
    content = re.sub(filtered_items_regex, replace_filter, content, flags=re.DOTALL)

# 4. Default sort logic
default_sorting = """
                  if (_sortColumnIndex != null) {
                    filteredItems.sort((a, b) {
                      int cmp = 0;
                      switch (_sortColumnIndex) {
                        case 0:
                          cmp = a.id!.compareTo(b.id!);
                          break;
                        case 1:
                          cmp = a.category.compareTo(b.category);
                          break;
                        case 2:
                          cmp = a.name.compareTo(b.name);
                          break;
                        case 3:
                          cmp = a.size.compareTo(b.size);
                          break;
                        case 4:
                          cmp = a.retailPrice.compareTo(b.retailPrice);
                          break;
                        case 5:
                          cmp = a.wholesalePrice.compareTo(b.wholesalePrice);
                          break;
                        case 6:
                          cmp = (a.customPrice ?? 0).compareTo(b.customPrice ?? 0);
                          break;
                        case 7:
                          cmp = a.stockAmount.compareTo(b.stockAmount);
                          break;
                      }
                      return _sortAscending ? cmp : -cmp;
                    });
                  } else {
                    filteredItems.sort((a, b) {
                      int cmp = a.category.compareTo(b.category);
                      if (cmp == 0) cmp = a.name.compareTo(b.name);
                      return cmp;
                    });
                  }"""
content = re.sub(r"if \(_sortColumnIndex != null\) \{.*?(?=^\s*return Padding\()", default_sorting + "\n\n", content, flags=re.DOTALL | re.MULTILINE)

# 5. Replace LayoutBuilder containing DataTable with PaginatedDataTable
start_str = "child: LayoutBuilder("
start_idx = content.find(start_str)
if start_idx != -1:
    end_idx = find_matching_brace(content, start_idx + len(start_str) - 1, '(', ')')
    if end_idx != -1:
        replacement = """child: LayoutBuilder(builder: (context, constraints) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.minWidth),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    cardColor: Colors.transparent,
                                    cardTheme: const CardTheme(elevation: 0, margin: EdgeInsets.zero, color: Colors.transparent),
                                  ),
                                  child: PaginatedDataTable(
                                    showCheckboxColumn: false,
                                    rowsPerPage: filteredItems.length > 10 ? 10 : (filteredItems.isEmpty ? 1 : filteredItems.length),
                                    availableRowsPerPage: const [10, 20, 50, 100],
                                    onRowsPerPageChanged: (val) {},
                                    columns: [
                                      const DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('category'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('size'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('retail_price'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('wholesale_price'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('custom_price'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('stock_amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text(AppLocalizations.of(context).translate('actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    source: ItemDataSource(filteredItems, context, this, provider),
                                  ),
                                ),
                              );
                            })"""
        content = content[:start_idx] + replacement + content[end_idx+1:]

# 6. Add ItemDataSource class at the end
data_source = """
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
      cells: [
        DataCell(Text(item.id.toString())),
        DataCell(Text(AppLocalizations.of(context).translate(item.category))),
        DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(item.size)),
        DataCell(state._buildPriceCell(item, 'retail', item.retailPrice, Colors.green)),
        DataCell(state._buildPriceCell(item, 'wholesale', item.wholesalePrice, Colors.blue)),
        DataCell(state._buildPriceCell(item, 'custom', item.customPrice, Colors.orange)),
        DataCell(Text(item.stockAmount.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), tooltip: 'Add Stock', onPressed: () => state._showStockDialog(item, true)),
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.orange), tooltip: 'Reduce Stock', onPressed: () => state._showStockDialog(item, false)),
              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.indigo), tooltip: 'Edit', onPressed: () => state._showItemDialog(item)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context).translate('delete')),
                      content: Text('Are you sure you want to delete ${item.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).translate('cancel'), style: const TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            provider.deleteItem(item.id!);
                            Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
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

  @override bool get isRowCountApproximate => false;
  @override int get rowCount => items.length;
  @override int get selectedRowCount => 0;
}
"""
if 'class ItemDataSource' not in content:
    content = content + data_source

with open('lib/screens/items_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done")
