class PriceHistory {
  String id;
  String productId;
  String shopId;
  double oldPrice;
  double newPrice;
  DateTime changedAt;

  PriceHistory({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.oldPrice,
    required this.newPrice,
    required this.changedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'shopId': shopId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'changedAt': changedAt.toIso8601String(),
    };
  }

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      id: json['id'],
      productId: json['productId'],
      shopId: json['shopId'],
      oldPrice: json['oldPrice']?.toDouble() ?? 0.0,
      newPrice: json['newPrice']?.toDouble() ?? 0.0,
      changedAt: DateTime.parse(json['changedAt']),
    );
  }
}
