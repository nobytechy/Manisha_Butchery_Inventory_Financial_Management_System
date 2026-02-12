class ShopTransfer {
  String id;
  String productId;
  String fromShopId;
  String toShopId;
  String fromShopName;
  String toShopName;
  String productName;
  double quantity;
  DateTime date;

  ShopTransfer({
    required this.id,
    required this.productId,
    required this.fromShopId,
    required this.toShopId,
    required this.fromShopName,
    required this.toShopName,
    required this.productName,
    required this.quantity,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'fromShopId': fromShopId,
      'toShopId': toShopId,
      'fromShopName': fromShopName,
      'toShopName': toShopName,
      'productName': productName,
      'quantity': quantity,
      'date': date.toIso8601String(),
    };
  }

  factory ShopTransfer.fromJson(Map<String, dynamic> json) {
    return ShopTransfer(
      id: json['id'],
      productId: json['productId'],
      fromShopId: json['fromShopId'],
      toShopId: json['toShopId'],
      fromShopName: json['fromShopName'],
      toShopName: json['toShopName'],
      productName: json['productName'],
      quantity: json['quantity']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
    );
  }
}

class ProductTransfer {
  String id;
  String shopId;
  String fromProductId;
  String toProductId;
  String fromProductName;
  String toProductName;
  double quantity;
  DateTime date;

  ProductTransfer({
    required this.id,
    required this.shopId,
    required this.fromProductId,
    required this.toProductId,
    required this.fromProductName,
    required this.toProductName,
    required this.quantity,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'fromProductId': fromProductId,
      'toProductId': toProductId,
      'fromProductName': fromProductName,
      'toProductName': toProductName,
      'quantity': quantity,
      'date': date.toIso8601String(),
    };
  }

  factory ProductTransfer.fromJson(Map<String, dynamic> json) {
    return ProductTransfer(
      id: json['id'],
      shopId: json['shopId'],
      fromProductId: json['fromProductId'],
      toProductId: json['toProductId'],
      fromProductName: json['fromProductName'],
      toProductName: json['toProductName'],
      quantity: json['quantity']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
    );
  }
}
