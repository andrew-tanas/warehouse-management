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
content = re.sub(search_bar_regex, category_filter_ui + r"\1", content, flags=re.DOTALL)

# 2. Add filter by category in filteredItems
filtered_items_regex = r"(List<Item> filteredItems = provider.items.where\(\(item\) \{)(.*?)(return item.name.toLowerCase\(\).contains\(_searchQuery\))(.*?\n\s*\}\).toList\(\);)"
def replace_filter(match):
    return match.group(1) + "\n                    if (_filterCategory != null && item.category != _filterCategory) return false;\n                    " + match.group(3) + match.group(4)
content = re.sub(filtered_items_regex, replace_filter, content, flags=re.DOTALL)

# 3. Add Category column to DataTable
data_columns_regex = r"(columns: \[\s*const DataColumn\(\s*label: Text\(\s*'ID',\s*style: TextStyle\(\s*fontWeight: FontWeight.bold,\s*\),\s*\),\s*\),)"
category_column = """
                                      DataColumn(
                                        label: Text(
                                          AppLocalizations.of(context).translate('category'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),"""
content = re.sub(data_columns_regex, r"\1" + category_column, content)

# 4. Add Category cell in rows
data_cells_regex = r"(cells: \[\s*DataCell\(Text\(item.id.toString\(\)\)\),)"
category_cell = """
                                          DataCell(Text(AppLocalizations.of(context).translate(item.category))),"""
content = re.sub(data_cells_regex, r"\1" + category_cell, content)

# 5. Make DataTable -> PaginatedDataTable
# Instead of replacing DataTable completely, I'll write the ItemDataSource at the bottom of the file
# and replace DataTable with PaginatedDataTable.
# Actually it's easier to just use ListView.builder if PaginatedDataTable is hard to parse out.
# Wait, replacing DataTable with PaginatedDataTable:
datatable_regex = r"DataTable\("
content = re.sub(datatable_regex, r"PaginatedDataTable(rowsPerPage: 10, columnSpacing: 15, source: _ItemDataSource(filteredItems, context, this, provider),", content, count=1)

# Now remove the rows: [ ... ] and replace with source: ...
rows_regex = r"rows: filteredItems\.map\(\(item\).*?\]\s*\)\s*\}\)\.toList\(\),\s*\)"
# Wait, the end of rows array is hard to match with regex.
# Let's just find the exact text we want to delete using a custom script.
EOF
python refactor_items.py
