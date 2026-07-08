with open('lib/screens/items_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
for i, line in enumerate(lines):
    if "child: LayoutBuilder(" in line and "builder: (context, constraints) {" in lines[i+1]:
        start_idx = i
        break

end_idx = -1
if start_idx != -1:
    count = 0
    for i in range(start_idx, len(lines)):
        count += lines[i].count('{')
        count -= lines[i].count('}')
        if count == 0 and "}," in lines[i]:
            end_idx = i
            break
        if count == 0 and lines[i].strip() == "),":
            end_idx = i
            break

if start_idx != -1 and end_idx != -1:
    replacement = """                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.minWidth),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    cardColor: Colors.transparent,
                                    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: Colors.transparent),
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
                            },
                          ),
"""
    lines = lines[:start_idx] + [replacement] + lines[end_idx+1:]
    
    with open('lib/screens/items_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("done")
else:
    print(f"Failed to find LayoutBuilder: start={start_idx}, end={end_idx}")
