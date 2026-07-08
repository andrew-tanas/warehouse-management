import re

with open('lib/screens/items_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _filterCategory to _ItemsScreenState
content = re.sub(
    r"String _searchQuery = '';",
    r"String _searchQuery = '';\n  String? _filterCategory;",
    content,
    count=1
)

# 2. Update _showItemDialog with category field
dialog_match = re.search(r"void _showItemDialog\(\[Item\? item\]\) \{.*?(?=showDialog\()", content, re.DOTALL)
if dialog_match:
    dialog_code = dialog_match.group(0)
    dialog_code_new = dialog_code.replace("double stockAmount = item?.stockAmount ?? 0.0;", "double stockAmount = item?.stockAmount ?? 0.0;\n    String category = item?.category ?? 'men';")
    content = content.replace(dialog_code, dialog_code_new)

# 3. Add Category Dropdown in the dialog Form
form_match = re.search(r"onSaved: \(val\) => size = val!,\n\s*\),", content, re.DOTALL)
if form_match:
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

# 4. Add category to newItem in _showItemDialog
new_item_match = re.search(r"final newItem = Item\(\s*id: item\?\.id,\s*name: name,\s*size: size,", content)
if new_item_match:
    content = content.replace(new_item_match.group(0), new_item_match.group(0) + "\n                    category: category,")

with open('lib/screens/items_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done")
