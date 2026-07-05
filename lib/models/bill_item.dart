class BillItem {
  int? id;
  int billId;
  int itemId;
  String itemName;
  String itemSize;
  double itemPrice;
  double quantityDozens;
  double total;
  String? note;

  BillItem({
    this.id,
    required this.billId,
    required this.itemId,
    required this.itemName,
    required this.itemSize,
    required this.itemPrice,
    required this.quantityDozens,
    required this.total,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'itemId': itemId,
      'itemName': itemName,
      'itemSize': itemSize,
      'itemPrice': itemPrice,
      'quantityDozens': quantityDozens,
      'total': total,
      'note': note,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'],
      billId: map['billId'],
      itemId: map['itemId'],
      itemName: map['itemName'],
      itemSize: map['itemSize'],
      itemPrice: map['itemPrice'],
      quantityDozens: map['quantityDozens'],
      total: map['total'],
      note: map['note'],
    );
  }
}
