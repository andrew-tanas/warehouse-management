import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/bill_item.dart';
import '../models/customer.dart';

class DraftBill {
  final String id;
  final Customer? customer;
  final List<BillItem> items;
  final double discountPercent;
  final DateTime dateCreated;

  DraftBill({
    required this.id,
    this.customer,
    required this.items,
    this.discountPercent = 0.0,
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer?.toMap(),
      'items': items.map((e) => e.toMap()).toList(),
      'discountPercent': discountPercent,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  factory DraftBill.fromJson(Map<String, dynamic> json) {
    return DraftBill(
      id: json['id'],
      customer: json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      items: (json['items'] as List).map((e) => BillItem.fromMap(e)).toList(),
      discountPercent: json['discountPercent']?.toDouble() ?? 0.0,
      dateCreated: DateTime.parse(json['dateCreated']),
    );
  }
}

class DraftService {
  static Future<File> get _file async {
    final appDocsDir = await getApplicationDocumentsDirectory();
    final draftsDir = join(appDocsDir.path, 'El Mohandes Warehouse');
    await Directory(draftsDir).create(recursive: true);
    return File(join(draftsDir, 'drafts.json'));
  }

  static Future<List<DraftBill>> getDrafts() async {
    final file = await _file;
    if (!await file.exists()) return [];
    
    try {
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((e) => DraftBill.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveDraft(DraftBill draft) async {
    final drafts = await getDrafts();
    final index = drafts.indexWhere((d) => d.id == draft.id);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.add(draft);
    }
    
    final file = await _file;
    await file.writeAsString(jsonEncode(drafts.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteDraft(String id) async {
    final drafts = await getDrafts();
    drafts.removeWhere((d) => d.id == id);
    
    final file = await _file;
    await file.writeAsString(jsonEncode(drafts.map((e) => e.toJson()).toList()));
  }
}
