import 'package:pdf/pdf.dart';
import 'dart:math' as math;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../db/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

import '../models/customer.dart';
import '../models/payment.dart';
import '../models/item.dart';

class StatementOperation {
  final DateTime date;
  final String description;
  final double amountChange;

  StatementOperation(this.date, this.description, this.amountChange);
}

class PdfGenerator {
  static Future<void> printBill(
    BuildContext context,
    Bill bill, [
    Customer? customer,
  ]) async {
    final l10n = AppLocalizations.of(context);
    final isArabic =
        Provider.of<LocaleProvider>(
          context,
          listen: false,
        ).locale.languageCode ==
        'ar';
    final textDir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    final List<BillItem> billItems = await DatabaseHelper.instance.getBillItems(
      bill.id!,
    );

    bool hasNotes = billItems.any(
      (item) => item.note != null && item.note!.isNotEmpty,
    );
    List<String> headers = [
      l10n.translate('name'),
      l10n.translate('item_size'),
      l10n.translate('item_price'),
      l10n.translate('quantity_dozens'),
      l10n.translate('total'),
    ];
    if (hasNotes) headers.add(l10n.translate('note'));

    List<List<String>> data = billItems.map((item) {
      List<String> row = [
        item.itemName,
        item.itemSize,
        (item.itemPrice.toStringAsFixed(2)),
        item.quantityDozens.toStringAsFixed(2),
        (item.total.toStringAsFixed(2)),
      ];
      if (hasNotes) row.add(item.note ?? '');
      return row;
    }).toList();

    if (isArabic) {
      headers = headers.reversed.toList();
      data = data.map((row) => row.reversed.toList()).toList();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: textDir,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  isArabic ? 'بيان' : 'Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '${isArabic ? 'التاريخ' : 'Date'}: ${DateFormat('yyyy-MM-dd HH:mm').format(bill.date)}',
              ),
              pw.Text(
                '${l10n.translate('customer_name')}: ${bill.customerName}',
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: [fontBold],
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: isArabic
                    ? pw.Alignment.centerLeft
                    : pw.Alignment.centerRight,
                cellAlignments: {
                  isArabic ? headers.length - 1 : 0: isArabic
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
                  isArabic ? headers.length - 2 : 1: isArabic
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
                },
                cellStyle: pw.TextStyle(fontFallback: [font]),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: isArabic
                    ? pw.MainAxisAlignment.start
                    : pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: isArabic
                        ? pw.CrossAxisAlignment.start
                        : pw.CrossAxisAlignment.end,
                    children: [
                      if (bill.discountApplied > 0) ...[
                        pw.Text(
                          '${l10n.translate('subtotal')}: ${(bill.total + bill.discountApplied).toStringAsFixed(2)}',
                          style: pw.TextStyle(fontFallback: [font]),
                        ),
                        pw.Text(
                          '${l10n.translate('discount')}: ${bill.discountApplied.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            color: PdfColors.red,
                            fontFallback: [font],
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '${l10n.translate('total')}: ${bill.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          fontFallback: [fontBold],
                        ),
                      ),
                      if (customer != null) ...[
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: isArabic
                                ? pw.CrossAxisAlignment.start
                                : pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${isArabic ? 'الرصيد السابق' : 'Previous Balance'}: ${((customer.totalDebt - bill.total).abs()).toStringAsFixed(2)}',
                                style: pw.TextStyle(fontFallback: [font]),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '${isArabic ? 'الرصيد الحالي' : 'Current Balance'}: ${(customer.totalDebt.abs()).toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontFallback: [fontBold],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> printCustomerStatement(
    BuildContext context,
    Customer customer,
    List<Bill> bills,
    List<Payment> payments, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isArabic =
        Provider.of<LocaleProvider>(
          context,
          listen: false,
        ).locale.languageCode ==
        'ar';
    final textDir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    double sumBills = bills.fold(0, (sum, bill) => sum + bill.total);
    double sumPayments = payments.fold(
      0,
      (sum, payment) => sum + payment.amount,
    );
    double overallInitialDebt = customer.totalDebt - sumBills + sumPayments;

    List<StatementOperation> ops = [];
    for (var b in bills) {
      ops.add(
        StatementOperation(b.date, isArabic ? 'فاتورة' : 'Bill', b.total),
      );
    }
    for (var p in payments) {
      ops.add(
        StatementOperation(
          p.date,
          (isArabic ? 'دفعة' : 'Payment') +
              (p.note.isNotEmpty ? ' - ${p.note}' : ''),
          -p.amount,
        ),
      );
    }
    ops.sort((a, b) => a.date.compareTo(b.date));

    double startingBalanceForRange = overallInitialDebt;
    List<StatementOperation> filteredOps = [];

    for (var op in ops) {
      bool isAfterStart =
          startDate == null ||
          !op.date.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          );
      bool isBeforeEnd =
          endDate == null ||
          !op.date.isAfter(
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          );

      if (isAfterStart && isBeforeEnd) {
        filteredOps.add(op);
      } else if (!isAfterStart) {
        startingBalanceForRange += op.amountChange;
      }
    }

    List<List<String>> tableData = [];

    // Initial/Previous balance row
    tableData.add([
      '-',
      startDate == null
          ? (isArabic ? 'الرصيد الافتتاحي' : 'Initial Balance')
          : (isArabic ? 'الرصيد السابق' : 'Previous Balance'),
      '-',
      startingBalanceForRange.toStringAsFixed(2),
    ]);

    double currentBalance = startingBalanceForRange;
    for (var op in filteredOps) {
      currentBalance += op.amountChange;
      tableData.add([
        DateFormat('yyyy-MM-dd').format(op.date),
        op.description,
        op.amountChange.abs().toStringAsFixed(2),
        currentBalance.toStringAsFixed(2),
      ]);
    }

    // Current balance row
    tableData.add([
      '-',
      isArabic ? 'الرصيد الحالي' : 'Current Balance',
      '-',
      currentBalance.toStringAsFixed(2),
    ]);

    List<String> headers = [
      isArabic ? 'التاريخ' : 'Date',
      isArabic ? 'العملية' : 'Operation',
      isArabic ? 'المبلغ' : 'Amount',
      isArabic ? 'الرصيد' : 'Balance',
    ];

    if (isArabic) {
      headers = headers.reversed.toList();
      tableData = tableData.map((row) => row.reversed.toList()).toList();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: textDir,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  isArabic ? 'كشف حساب عميل' : 'Customer Statement',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('${isArabic ? 'العميل' : 'Customer'}: ${customer.name}'),
              pw.Text(
                '${isArabic ? 'تاريخ الطباعة' : 'Print Date'}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontFallback: [fontBold],
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: isArabic
                    ? pw.Alignment.centerLeft
                    : pw.Alignment.centerRight,
                cellAlignments: {
                  isArabic ? 3 : 0: pw.Alignment.center,
                  isArabic ? 2 : 1: isArabic
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
                },
                cellStyle: pw.TextStyle(fontFallback: [font]),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> printItemsList(
    BuildContext context,
    List<Item> items,
    List<String> selectedColumns,
  ) async {
    final l10n = AppLocalizations.of(context);
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final isArabic = locale.languageCode == 'ar';
    final textDir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document();

    Map<String, List<Item>> groupedItems = {};
    for (var item in items) {
      groupedItems.putIfAbsent(item.name, () => []).add(item);
    }

    List<pw.Widget> allBlocks = [];
    for (var entry in groupedItems.entries) {
      String itemName = entry.key;
      List<Item> groupItems = entry.value;

      List<pw.Widget> groupRows = groupItems.map((item) {
        List<pw.Widget> cells = [];
        for (String col in selectedColumns) {
          if (col == 'name') continue;
          String text = '';
          if (col == 'id')
            text = item.id.toString();
          else if (col == 'size')
            text = item.size;
          else if (col == 'retail_price')
            text = item.retailPrice.toStringAsFixed(2);
          else if (col == 'wholesale_price')
            text = item.wholesalePrice.toStringAsFixed(2);
          else if (col == 'custom_price')
            text = (item.customPrice ?? 0).toStringAsFixed(2);
          else if (col == 'stock_amount')
            text = item.stockAmount
                .toStringAsFixed(2)
                .replaceAll(RegExp(r'\.00$'), '');

          cells.add(
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(2),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(width: isArabic ? 0 : 1),
                    right: pw.BorderSide(width: isArabic ? 1 : 0),
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(fontSize: 10, fontFallback: [font]),
                  ),
                ),
              ),
            ),
          );
        }

        return pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide()),
          ),
          child: pw.Row(children: cells),
        );
      }).toList();

      List<pw.Widget> headerCells = [];
      for (String col in selectedColumns) {
        if (col == 'name') continue;
        String text = col;
        if (col == 'retail_price' ||
            col == 'wholesale_price' ||
            col == 'custom_price')
          text = isArabic ? 'السعر' : 'Price';
        else if (col == 'id')
          text = 'ID';
        else
          text = l10n.translate(col);

        headerCells.add(
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(width: isArabic ? 0 : 1),
                  right: pw.BorderSide(width: isArabic ? 1 : 0),
                ),
              ),
              child: pw.Center(
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    fontFallback: [fontBold],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      pw.Widget groupWidget = pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              width: 25,
              color: PdfColors.blue100,
              child: pw.Center(
                child: pw.Transform.rotateBox(
                  angle: isArabic ? math.pi / 2 : -math.pi / 2,
                  child: pw.Text(
                    itemName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      fontFallback: [fontBold],
                    ),
                  ),
                ),
              ),
            ),
            pw.Container(width: 1, color: PdfColors.black),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                      border: pw.Border(bottom: pw.BorderSide()),
                    ),
                    child: pw.Row(children: headerCells),
                  ),
                  ...groupRows,
                ],
              ),
            ),
          ],
        ),
      );

      allBlocks.add(groupWidget);
    }

    pw.Widget gridWrap = pw.Wrap(
      spacing: 5,
      runSpacing: 5,
      children: allBlocks
          .map((block) => pw.SizedBox(width: 115, child: block))
          .toList(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: textDir,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context pdfContext) {
          return [
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                isArabic ? 'قائمة اسعار' : 'Items List',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            gridWrap,
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
