class ShopClosing {
  String id;
  String shopId;
  DateTime date;
  Map<String, double> productQuantities; // productId -> quantity

  ShopClosing({
    required this.id,
    required this.shopId,
    required this.date,
    required this.productQuantities,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'date': date.toIso8601String(),
      'productQuantities': productQuantities,
    };
  }

  factory ShopClosing.fromJson(Map<String, dynamic> json) {
    return ShopClosing(
      id: json['id'],
      shopId: json['shopId'],
      date: DateTime.parse(json['date']),
      productQuantities: Map<String, double>.from(json['productQuantities']),
    );
  }
}
