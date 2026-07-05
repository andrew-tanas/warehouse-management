class Customer {
  int? id;
  String name;
  String genre; // 'wholesaler' or 'retail'
  double totalDebt;

  Customer({
    this.id,
    required this.name,
    required this.genre,
    this.totalDebt = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genre': genre,
      'totalDebt': totalDebt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      genre: map['genre'],
      totalDebt: map['totalDebt'],
    );
  }
}
