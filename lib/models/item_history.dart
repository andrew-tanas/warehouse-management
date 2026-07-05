class ItemHistory {
  int? id;
  int itemId;
  DateTime date;
  double amountChange;
  String note;
  int? billId;

  ItemHistory({
    this.id,
    required this.itemId,
    required this.date,
    required this.amountChange,
    required this.note,
    this.billId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'date': date.toIso8601String(),
      'amountChange': amountChange,
      'note': note,
      'billId': billId,
    };
  }

  factory ItemHistory.fromMap(Map<String, dynamic> map) {
    return ItemHistory(
      id: map['id'],
      itemId: map['itemId'],
      date: DateTime.parse(map['date']),
      amountChange: (map['amountChange'] as num).toDouble(),
      note: map['note'],
      billId: map['billId'],
    );
  }
}
