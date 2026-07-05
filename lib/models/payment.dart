class Payment {
  int? id;
  int customerId;
  double amount;
  DateTime date;
  String note;

  Payment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      customerId: map['customerId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
