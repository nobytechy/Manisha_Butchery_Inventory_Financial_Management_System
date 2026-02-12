class Product {
  String id;
  String shopId;
  String name;
  double currentPrice;
  double currentCost;
  DateTime createdAt;

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.currentPrice = 0.0,
    this.currentCost = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'currentPrice': currentPrice,
      'currentCost': currentCost,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      shopId: json['shopId'],
      name: json['name'],
      currentPrice: json['currentPrice']?.toDouble() ?? 0.0,
      currentCost: json['currentCost']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
