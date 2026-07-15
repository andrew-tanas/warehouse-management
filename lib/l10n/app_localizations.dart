import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'dashboard': 'Dashboard',
      'customers': 'Customers',
      'items': 'Items',
      'bills': 'Bills',
      'create_bill': 'Create Bill',
      'add_customer': 'Add Customer',
      'add_item': 'Add Item',
      'customers_management': 'Customers Management',
      'items_management': 'Items Management',
      'bills_history': 'Bills History',
      'print_pdf': 'Print PDF',
      'delete': 'Delete',
      'edit': 'Edit',
      'cancel': 'Cancel',
      'save': 'Save',
      'name': 'Name',
      'genre': 'Genre',
      'wholesaler': 'Wholesaler',
      'retail': 'Retail',
      'total_debt': 'Total Debt',
      'size': 'Size',
      'category': 'Category',
      'men': 'Men',
      'women': 'Women',
      'boys': 'Boys',
      'girls': 'Girls',
      'retail_price': 'Retail Price',
      'wholesale_price': 'Wholesale Price',
      'stock_amount': 'Stock Amount',
      'quantity_dozens': 'Quantity (in Dozens)',
      'select_customer': 'Select Customer',
      'select_item': 'Select Item',
      'customer_name': 'Customer Name',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'total': 'Total',
      'summary': 'Summary',
      'bill_items': 'Bill Items',
      'customer_info': 'Customer Information',
      'add': 'Add',
      'no_customers': 'No customers found. Add a new customer to get started.',
      'no_items': 'No items found',
      'no_bills': 'No bills found',
      'no_items_added': 'No items added yet',
      'price_applied': 'Price applied',
      'actions': 'Actions',
      'delete_bill_confirm': 'Are you sure? This will reverse the debt from the customer.',
      'bill_created': 'Bill Created Successfully!',
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',
      'normal': 'Normal',
      'custom_price': 'Custom Price',
      'price_tier': 'Price Tier',
      'item_size': 'Size',
      'item_price': 'Price',
      'discount_percent': 'Discount (%)',
      'pay': 'Pay',
      'payment_method': 'Payment Method',
      'note': 'Note',
      'amount': 'Amount',
      'history': 'History',
      'customer_history': 'Customer History',
      'statement': 'Statement',
      'select_date_range': 'Select a date range (optional). Leave empty to print all history.',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'not_selected': 'Not selected',
    },
    'ar': {
      'dashboard': 'لوحة القيادة',
      'customers': 'العملاء',
      'items': 'الأصناف',
      'bills': 'الفواتير',
      'create_bill': 'إنشاء فاتورة',
      'add_customer': 'إضافة عميل',
      'add_item': 'إضافة صنف',
      'customers_management': 'إدارة العملاء',
      'items_management': 'إدارة الأصناف',
      'bills_history': 'سجل الفواتير',
      'print_pdf': 'طباعة PDF',
      'delete': 'حذف',
      'edit': 'تعديل',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'name': 'الصنف',
      'genre': 'النوع',
      'wholesaler': 'تاجر جملة',
      'retail': 'تجزئة',
      'total_debt': 'إجمالي الديون',
      'size': 'المقاس',
      'category': 'الفئة',
      'men': 'رجالي',
      'women': 'حريمي',
      'boys': 'اولادي',
      'girls': 'بناتي',
      'retail_price': 'سعر التجزئة',
      'wholesale_price': 'سعر الجملة',
      'stock_amount': 'الكمية في المخزن',
      'quantity_dozens': 'الكمية (دستة)',
      'select_customer': 'اختر العميل',
      'select_item': 'اختر الصنف',
      'customer_name': 'اسم العميل',
      'subtotal': 'الاجمالي قبل الخصم',
      'discount': 'الخصم',
      'total': 'الإجمالي',
      'summary': 'الملخص',
      'bill_items': 'أصناف الفاتورة',
      'customer_info': 'معلومات العميل',
      'add': 'إضافة',
      'no_customers': 'لم يتم العثور على عملاء. أضف عميلاً جديداً للبدء.',
      'no_items': 'لم يتم العثور على أصناف',
      'no_bills': 'لم يتم العثور على فواتير',
      'no_items_added': 'لم يتم إضافة أي أصناف بعد',
      'price_applied': 'السعر المطبق',
      'actions': 'الإجراءات',
      'delete_bill_confirm': 'هل أنت متأكد؟ سيؤدي هذا إلى عكس الدين من العميل.',
      'bill_created': 'تم إنشاء الفاتورة بنجاح!',
      'language': 'اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'normal': 'عادي',
      'custom_price': 'سعر مخصص',
      'price_tier': 'فئة السعر',
      'item_size': 'المقاس',
      'item_price': 'السعر',
      'discount_percent': 'الخصم (%)',
      'pay': 'دفع',
      'payment_method': 'طريقة الدفع',
      'note': 'ملاحظة',
      'amount': 'المبلغ',
      'history': 'السجل',
      'customer_history': 'سجل العميل',
      'statement': 'كشف حساب',
      'select_date_range': 'اختر فترة زمنية (اختياري). اتركها فارغة لطباعة السجل بالكامل.',
      'start_date': 'تاريخ البداية',
      'end_date': 'تاريخ النهاية',
      'not_selected': 'غير محدد',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
