class Bill {
  int? id;
  DateTime date;
  int customerId;
  String customerName;
  double total;
  double discountApplied;
  int customerBillNumber;

  Bill({
    this.id,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.total,
    required this.discountApplied,
    this.customerBillNumber = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'total': total,
      'discountApplied': discountApplied,
      'customerBillNumber': customerBillNumber,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      date: DateTime.parse(map['date']),
      customerId: map['customerId'],
      customerName: map['customerName'],
      total: map['total'],
      discountApplied: map['discountApplied'],
      customerBillNumber: map['customerBillNumber'] ?? 0,
    );
  }
}
