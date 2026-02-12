class ExpenseCategory {
  String id;
  String name;
  DateTime createdAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  }

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Expense {
  String id;
  String shopId;
  String categoryId;
  String categoryName;
  String description;
  double amount;
  DateTime date;

  Expense({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      shopId: json['shopId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      description: json['description'],
      amount: json['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
    );
  }
}
