import os
import re

def rename_content(content):
    # Order matters: replace longer matches first
    replacements = [
        ('VendorProvider', 'CustomerProvider'),
        ('vendorProvider', 'customerProvider'),
        ('vendor_provider', 'customer_provider'),
        ('vendors_screen', 'customers_screen'),
        ('vendor_history', 'customer_history'),
        ('VendorHistory', 'CustomerHistory'),
        ('VendorsScreen', 'CustomersScreen'),
        ('vendorId', 'customerId'),
        ('vendorName', 'customerName'),
        ('Vendors', 'Customers'),
        ('vendors', 'customers'),
        ('Vendor', 'Customer'),
        ('vendor', 'customer'),
        ('VENDOR', 'CUSTOMER'),
        ('VENDORS', 'CUSTOMERS'),
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    return content

def main():
    lib_dir = 'lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = rename_content(content)
                
                if content != new_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated {filepath}")

    # Rename files
    files_to_rename = [
        ('lib/models/vendor.dart', 'lib/models/customer.dart'),
        ('lib/providers/vendor_provider.dart', 'lib/providers/customer_provider.dart'),
        ('lib/screens/vendors_screen.dart', 'lib/screens/customers_screen.dart'),
    ]
    
    for old_path, new_path in files_to_rename:
        if os.path.exists(old_path):
            os.rename(old_path, new_path)
            print(f"Renamed {old_path} to {new_path}")

if __name__ == '__main__':
    main()
