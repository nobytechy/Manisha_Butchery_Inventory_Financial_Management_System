class Shop {
  String id;
  String name;
  DateTime createdAt;
  bool isWarehouse;

  Shop({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isWarehouse = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isWarehouse': isWarehouse,
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      isWarehouse: json['isWarehouse'] ?? false,
    );
  }
}
