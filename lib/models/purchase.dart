class Purchase {
  String id;
  String shopId;
  String productId;
  String productName;
  double quantity;
  double cost;
  DateTime date;

  Purchase({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.cost,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'cost': cost,
      'date': date.toIso8601String(),
    };
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      shopId: json['shopId'],
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity']?.toDouble() ?? 0.0,
      cost: json['cost']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
    );
  }
}
