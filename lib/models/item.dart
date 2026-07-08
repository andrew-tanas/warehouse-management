class Item {
  int? id;
  String name;
  String size;
  String category;
  double retailPrice;
  double wholesalePrice;
  double? customPrice;
  double stockAmount;

  Item({
    this.id,
    required this.name,
    required this.size,
    required this.category,
    required this.retailPrice,
    required this.wholesalePrice,
    this.customPrice,
    required this.stockAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'category': category,
      'retailPrice': retailPrice,
      'wholesalePrice': wholesalePrice,
      'customPrice': customPrice,
      'stockAmount': stockAmount,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      size: map['size'],
      category: map['category'] ?? 'men', // default category
      retailPrice: map['retailPrice'],
      wholesalePrice: map['wholesalePrice'],
      customPrice: map['customPrice'],
      stockAmount: (map['stockAmount'] as num).toDouble(),
    );
  }
}
