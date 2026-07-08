import re

with open('lib/screens/items_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add Category Filter UI next to search bar
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
    content = re.sub(search_bar_regex, category_filter_ui + r"\1", content, flags=re.DOTALL)

# 2. Add filter by category in filteredItems
filtered_items_regex = r"(List<Item> filteredItems = provider.items.where\(\(item\) \{)(.*?)(return item.name.toLowerCase\(\).contains\(_searchQuery\))(.*?\n\s*\}\).toList\(\);)"
def replace_filter(match):
    return match.group(1) + "\n                    if (_filterCategory != null && item.category != _filterCategory) return false;\n                    " + match.group(3) + match.group(4)
content = re.sub(filtered_items_regex, replace_filter, content, flags=re.DOTALL)

# 3. Add default sorting by category then name
sorting_regex = r"(if \(_sortColumnIndex != null\) \{)(.*?)(^\s*\})\s*else\s*\{"
# wait, there's no else. The code is:
# if (_sortColumnIndex != null) { ... }
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

# 4. Replace DataTable with PaginatedDataTable
datatable_start = content.find("child: DataTable(")
datatable_end = content.find(");", content.find("rows: filteredItems.map", datatable_start))
if datatable_start != -1 and datatable_end != -1:
    datatable_code = content[datatable_start:datatable_end+2]
    
    # Extract columns
    cols_match = re.search(r"columns: \[(.*?)\]\s*,", datatable_code, re.DOTALL)
    cols = cols_match.group(1) if cols_match else ""
    # Add Category Column
    cat_col = """
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(context).translate('category'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),"""
    cols = cols.replace("const DataColumn(", "DataColumn(", 1)
    cols = cols.replace("DataColumn(\n                                        label: Text(\n                                          'ID',", "DataColumn(\n                                        label: Text(\n                                          'ID',") 
    cols_parts = cols.split("DataColumn(")
    new_cols = cols_parts[0] + "DataColumn(" + cols_parts[1] + cat_col + "".join(["DataColumn(" + p for p in cols_parts[2:]])
    
    paginated = f"""child: PaginatedDataTable(
                                    showCheckboxColumn: false,
                                    rowsPerPage: filteredItems.length > 10 ? 10 : (filteredItems.isEmpty ? 1 : filteredItems.length),
                                    availableRowsPerPage: const [10, 20, 50, 100],
                                    onRowsPerPageChanged: (val) {{}},
                                    columns: [
                                      {new_cols}
                                    ],
                                    source: ItemDataSource(filteredItems, context, this, provider),
                                  )"""
    content = content[:datatable_start] + paginated + content[datatable_end+2:]

# 5. Add ItemDataSource class at the end
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
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => state._showStockDialog(item, true)),
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.orange), onPressed: () => state._showStockDialog(item, false)),
              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.indigo), onPressed: () => state._showItemDialog(item)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context).translate('delete')),
                      content: Text('Are you sure you want to delete ${item.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).translate('cancel'))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            provider.deleteItem(item.id!);
                            Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context).translate('delete')),
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
content = content + data_source

# Make _buildPriceCell and _showStockDialog public by removing _ if needed, or just let ItemDataSource access them if it's in the same file.
# Wait, _ItemsScreenState methods are accessible in the same file! So state._buildPriceCell works.

with open('lib/screens/items_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done")
