import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/price.dart';
import '../models/transfer.dart';
import '../models/closing.dart';
import '../models/expense.dart';

class SharedPrefsService {
  static late SharedPreferences _prefs;
  static const Uuid _uuid = Uuid();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeDefaults();
  }

  static Future<void> _initializeDefaults() async {
    // Initialize default PIN if not set
    if (!_prefs.containsKey('user_pin')) {
      await _prefs.setString('user_pin', '0000');
    }

    // Initialize default shop (Warehouse) if no shops exist
    final shops = await getShops();
    if (shops.isEmpty) {
      final warehouse = Shop(
        id: _uuid.v4(),
        name: 'Warehouse',
        createdAt: DateTime.now(),
        isWarehouse: true,
      );
      await saveShop(warehouse);
      await setSelectedShopId(warehouse.id);
    }
  }

  // PIN Management
  static String getPin() {
    return _prefs.getString('user_pin') ?? '0000';
  }

  static Future<void> setPin(String pin) async {
    await _prefs.setString('user_pin', pin);
  }

  // Shop Management
  static Future<void> saveShop(Shop shop) async {
    final shops = await getShops();
    shops.add(shop);
    await saveList('shops', shops.map((s) => s.toJson()).toList());
  }

  static Future<List<Shop>> getShops() async {
    final List<String>? shopsJson = _prefs.getStringList('shops');
    if (shopsJson == null) return [];
    return shopsJson.map((json) => Shop.fromJson(_parseJson(json))).toList();
  }

  static Future<void> updateShop(Shop shop) async {
    final shops = await getShops();
    final index = shops.indexWhere((s) => s.id == shop.id);
    if (index != -1) {
      shops[index] = shop;
      await saveList('shops', shops.map((s) => s.toJson()).toList());
    }
  }

  static Future<void> deleteShop(String shopId) async {
    final shops = await getShops();
    shops.removeWhere((s) => s.id == shopId);
    await saveList('shops', shops.map((s) => s.toJson()).toList());
  }

  // Selected Shop
  static Future<void> setSelectedShopId(String shopId) async {
    await _prefs.setString('selected_shop_id', shopId);
  }

  static String? getSelectedShopId() {
    return _prefs.getString('selected_shop_id');
  }

  static Future<Shop?> getSelectedShop() async {
    final shopId = getSelectedShopId();
    if (shopId == null) return null;
    final shops = await getShops();
    try {
      return shops.firstWhere((shop) => shop.id == shopId);
    } catch (e) {
      return null;
    }
  }

  // Product Management
  static Future<void> saveProduct(Product product) async {
    final products = await getProducts();
    products.add(product);
    await saveList('products', products.map((p) => p.toJson()).toList());
  }

  static Future<List<Product>> getProducts({String? shopId}) async {
    final List<String>? productsJson = _prefs.getStringList('products');
    if (productsJson == null) return [];
    List<Product> products =
        productsJson.map((json) => Product.fromJson(_parseJson(json))).toList();

    if (shopId != null) {
      products = products.where((p) => p.shopId == shopId).toList();
    }

    return products;
  }

  static Future<void> updateProduct(Product product) async {
    final products = await getProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await saveList('products', products.map((p) => p.toJson()).toList());
    }
  }

  static Future<void> deleteProduct(String productId) async {
    final products = await getProducts();
    products.removeWhere((p) => p.id == productId);
    await saveList('products', products.map((p) => p.toJson()).toList());
  }

  // Purchase Management
  static Future<void> savePurchase(Purchase purchase) async {
    final purchases = await getPurchases();
    purchases.add(purchase);
    await saveList('purchases', purchases.map((p) => p.toJson()).toList());
  }

  static Future<List<Purchase>> getPurchases({
    String? shopId,
    DateTime? date,
    String? productId,
  }) async {
    final List<String>? purchasesJson = _prefs.getStringList('purchases');
    if (purchasesJson == null) return [];

    List<Purchase> purchases = purchasesJson
        .map((json) => Purchase.fromJson(_parseJson(json)))
        .toList();

    if (shopId != null) {
      purchases = purchases.where((p) => p.shopId == shopId).toList();
    }

    if (productId != null) {
      purchases = purchases.where((p) => p.productId == productId).toList();
    }

    if (date != null) {
      purchases = purchases
          .where(
            (p) =>
                p.date.year == date.year &&
                p.date.month == date.month &&
                p.date.day == date.day,
          )
          .toList();
    }

    return purchases;
  }

  static Future<void> updatePurchase(Purchase purchase) async {
    final purchases = await getPurchases();
    final index = purchases.indexWhere((p) => p.id == purchase.id);
    if (index != -1) {
      purchases[index] = purchase;
      await saveList('purchases', purchases.map((p) => p.toJson()).toList());
    }
  }

  static Future<void> deletePurchase(String purchaseId) async {
    final purchases = await getPurchases();
    purchases.removeWhere((p) => p.id == purchaseId);
    await saveList('purchases', purchases.map((p) => p.toJson()).toList());
  }

  // Price History Management
  static Future<void> savePriceHistory(PriceHistory price) async {
    final prices = await getPriceHistory();
    prices.add(price);
    await saveList('price_history', prices.map((p) => p.toJson()).toList());
  }

  static Future<List<PriceHistory>> getPriceHistory({String? productId}) async {
    final List<String>? pricesJson = _prefs.getStringList('price_history');
    if (pricesJson == null) return [];

    List<PriceHistory> prices = pricesJson
        .map((json) => PriceHistory.fromJson(_parseJson(json)))
        .toList();

    if (productId != null) {
      prices = prices.where((p) => p.productId == productId).toList();
    }

    return prices..sort((a, b) => b.changedAt.compareTo(a.changedAt));
  }

  // Shop Transfer Management
  static Future<void> saveShopTransfer(ShopTransfer transfer) async {
    final List<String>? transfersJson = _prefs.getStringList('shop_transfers');
    List<Map<String, dynamic>> transfers = [];

    if (transfersJson != null) {
      transfers = transfersJson.map((json) => _parseJson(json)).toList();
    }

    // Remove existing transfer with same ID
    transfers.removeWhere((t) => t['id'] == transfer.id);

    // Add the new transfer
    transfers.add(transfer.toJson());

    // Save back to SharedPreferences
    await _prefs.setStringList(
      'shop_transfers',
      transfers.map((t) => jsonEncode(t)).toList(),
    );

    print('DEBUG: Saved shop transfer:');
    print('  ID: ${transfer.id}');
    print('  Product: ${transfer.productName} (${transfer.productId})');
    print('  From: ${transfer.fromShopName} (${transfer.fromShopId})');
    print('  To: ${transfer.toShopName} (${transfer.toShopId})');
    print('  Quantity: ${transfer.quantity}');
    print('  Date: ${transfer.date}');
  }

  static Future<List<ShopTransfer>> getAllShopTransfers() async {
    final List<String>? transfersJson = _prefs.getStringList('shop_transfers');
    if (transfersJson == null) {
      print('DEBUG: No shop transfers found in SharedPreferences');
      return [];
    }

    List<ShopTransfer> transfers = [];
    for (var json in transfersJson) {
      try {
        final transfer = ShopTransfer.fromJson(_parseJson(json));
        transfers.add(transfer);
      } catch (e) {
        print('DEBUG: Error parsing transfer JSON: $e');
        print('JSON: $json');
      }
    }

    print('DEBUG: Retrieved ${transfers.length} shop transfers');
    for (var transfer in transfers) {
      print('  - ${transfer.productName} (ID: ${transfer.productId}) '
          'From: ${transfer.fromShopId} To: ${transfer.toShopId}');
    }

    return transfers..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<List<ShopTransfer>> getShopTransfers({String? shopId}) async {
    final List<String>? transfersJson = _prefs.getStringList('shop_transfers');
    if (transfersJson == null) return [];

    List<ShopTransfer> transfers = transfersJson
        .map((json) => ShopTransfer.fromJson(_parseJson(json)))
        .toList();

    if (shopId != null) {
      transfers = transfers
          .where((t) => t.fromShopId == shopId || t.toShopId == shopId)
          .toList();
    }

    return transfers..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> updateShopTransfer(ShopTransfer transfer) async {
    final transfers = await getShopTransfers();
    final index = transfers.indexWhere((t) => t.id == transfer.id);
    if (index != -1) {
      transfers[index] = transfer;
      await saveList(
        'shop_transfers',
        transfers.map((t) => t.toJson()).toList(),
      );
    }
  }

  static Future<void> deleteShopTransfer(String transferId) async {
    final transfers = await getShopTransfers();
    transfers.removeWhere((t) => t.id == transferId);
    await saveList(
      'shop_transfers',
      transfers.map((t) => t.toJson()).toList(),
    );
  }

  // Product Transfer Management
  static Future<void> saveProductTransfer(ProductTransfer transfer) async {
    final transfers = await getProductTransfers();
    transfers.add(transfer);
    await saveList(
      'product_transfers',
      transfers.map((t) => t.toJson()).toList(),
    );
  }

  static Future<List<ProductTransfer>> getProductTransfers({
    String? shopId,
  }) async {
    final List<String>? transfersJson = _prefs.getStringList(
      'product_transfers',
    );
    if (transfersJson == null) return [];

    List<ProductTransfer> transfers = transfersJson
        .map((json) => ProductTransfer.fromJson(_parseJson(json)))
        .toList();

    if (shopId != null) {
      transfers = transfers.where((t) => t.shopId == shopId).toList();
    }

    return transfers..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> updateProductTransfer(ProductTransfer transfer) async {
    final transfers = await getProductTransfers();
    final index = transfers.indexWhere((t) => t.id == transfer.id);
    if (index != -1) {
      transfers[index] = transfer;
      await saveList(
        'product_transfers',
        transfers.map((t) => t.toJson()).toList(),
      );
    }
  }

  static Future<void> deleteProductTransfer(String transferId) async {
    final transfers = await getProductTransfers();
    transfers.removeWhere((t) => t.id == transferId);
    await saveList(
      'product_transfers',
      transfers.map((t) => t.toJson()).toList(),
    );
  }

  // Shop Closing Management
  static Future<void> saveShopClosing(ShopClosing closing) async {
    final closings = await getShopClosings();
    closings.add(closing);
    await saveList('shop_closings', closings.map((c) => c.toJson()).toList());
  }

  static Future<List<ShopClosing>> getShopClosings({
    String? shopId,
    DateTime? date,
  }) async {
    final List<String>? closingsJson = _prefs.getStringList('shop_closings');
    if (closingsJson == null) return [];

    List<ShopClosing> closings = closingsJson
        .map((json) => ShopClosing.fromJson(_parseJson(json)))
        .toList();

    if (shopId != null) {
      closings = closings.where((c) => c.shopId == shopId).toList();
    }

    if (date != null) {
      closings = closings
          .where(
            (c) =>
                c.date.year == date.year &&
                c.date.month == date.month &&
                c.date.day == date.day,
          )
          .toList();
    }

    return closings..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteShopClosing(String closingId) async {
    final closings = await getShopClosings();
    closings.removeWhere((c) => c.id == closingId);
    await saveList('shop_closings', closings.map((c) => c.toJson()).toList());
  }

  // Expense Category Management
  static Future<void> saveExpenseCategory(ExpenseCategory category) async {
    final categories = await getExpenseCategories();
    categories.add(category);
    await saveList(
      'expense_categories',
      categories.map((c) => c.toJson()).toList(),
    );
  }

  static Future<List<ExpenseCategory>> getExpenseCategories() async {
    final List<String>? categoriesJson = _prefs.getStringList(
      'expense_categories',
    );
    if (categoriesJson == null) return [];

    return categoriesJson
        .map((json) => ExpenseCategory.fromJson(_parseJson(json)))
        .toList();
  }

  static Future<void> updateExpenseCategory(ExpenseCategory category) async {
    final categories = await getExpenseCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = category;
      await saveList(
        'expense_categories',
        categories.map((c) => c.toJson()).toList(),
      );
    }
  }

  static Future<void> deleteExpenseCategory(String categoryId) async {
    final categories = await getExpenseCategories();
    categories.removeWhere((c) => c.id == categoryId);
    await saveList(
      'expense_categories',
      categories.map((c) => c.toJson()).toList(),
    );
  }

  // Expense Management
  static Future<void> saveExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await saveList('expenses', expenses.map((e) => e.toJson()).toList());
  }

  static Future<List<Expense>> getExpenses({
    String? shopId,
    DateTime? date,
  }) async {
    final List<String>? expensesJson = _prefs.getStringList('expenses');
    if (expensesJson == null) return [];

    List<Expense> expenses =
        expensesJson.map((json) => Expense.fromJson(_parseJson(json))).toList();

    if (shopId != null) {
      expenses = expenses.where((e) => e.shopId == shopId).toList();
    }

    if (date != null) {
      expenses = expenses
          .where(
            (e) =>
                e.date.year == date.year &&
                e.date.month == date.month &&
                e.date.day == date.day,
          )
          .toList();
    }

    return expenses..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> updateExpense(Expense expense) async {
    final expenses = await getExpenses();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      await saveList('expenses', expenses.map((e) => e.toJson()).toList());
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    final expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == expenseId);
    await saveList('expenses', expenses.map((e) => e.toJson()).toList());
  }

  // Helper methods
  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final jsonList = items.map((item) => _jsonEncode(item)).toList();
    await _prefs.setStringList(key, jsonList);
  }

  static Map<String, dynamic> _parseJson(String json) {
    // Simple JSON parser for basic maps
    final result = <String, dynamic>{};

    // Remove outer braces and trim
    var content = json.trim();
    if (content.startsWith('{') && content.endsWith('}')) {
      content = content.substring(1, content.length - 1).trim();
    }

    if (content.isEmpty) return result;

    // Split by commas but handle nested objects and arrays
    var start = 0;
    var inString = false;
    var braceDepth = 0;
    var bracketDepth = 0;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"' && (i == 0 || content[i - 1] != '\\')) {
        inString = !inString;
      } else if (!inString) {
        if (char == '{') {
          braceDepth++;
        } else if (char == '}')
          braceDepth--;
        else if (char == '[')
          bracketDepth++;
        else if (char == ']')
          bracketDepth--;
        else if (char == ',' && braceDepth == 0 && bracketDepth == 0) {
          final pair = content.substring(start, i).trim();
          _addPair(result, pair);
          start = i + 1;
        }
      }
    }

    final pair = content.substring(start).trim();
    if (pair.isNotEmpty) {
      _addPair(result, pair);
    }

    return result;
  }

  static void _addPair(Map<String, dynamic> map, String pair) {
    final colonIndex = pair.indexOf(':');
    if (colonIndex != -1) {
      var key = pair.substring(0, colonIndex).trim();
      final value = pair.substring(colonIndex + 1).trim();

      // Remove quotes from key
      if (key.startsWith('"') && key.endsWith('"')) {
        key = key.substring(1, key.length - 1);
      }

      map[key] = _parseValue(value);
    }
  }

  static dynamic _parseValue(String value) {
    value = value.trim();

    // String
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1).replaceAll('\\"', '"');
    }

    // Number
    if (double.tryParse(value) != null) {
      return double.parse(value);
    }

    // Boolean
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value == 'null') return null;

    // DateTime (ISO format)
    if (value.contains('T') && value.contains('-')) {
      try {
        // Remove quotes if present
        var dateStr = value;
        if (dateStr.startsWith('"') && dateStr.endsWith('"')) {
          dateStr = dateStr.substring(1, dateStr.length - 1);
        }
        return DateTime.parse(dateStr);
      } catch (e) {
        return value;
      }
    }

    // Object
    if (value.startsWith('{') && value.endsWith('}')) {
      return _parseJson(value);
    }

    // Array
    if (value.startsWith('[') && value.endsWith(']')) {
      return _parseArray(value);
    }

    // Default
    return value;
  }

  static List<dynamic> _parseArray(String array) {
    final result = <dynamic>[];
    var content = array.trim();

    if (content.startsWith('[') && content.endsWith(']')) {
      content = content.substring(1, content.length - 1).trim();
    }

    if (content.isEmpty) return result;

    var start = 0;
    var inString = false;
    var braceDepth = 0;
    var bracketDepth = 0;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"' && (i == 0 || content[i - 1] != '\\')) {
        inString = !inString;
      } else if (!inString) {
        if (char == '{') {
          braceDepth++;
        } else if (char == '}')
          braceDepth--;
        else if (char == '[')
          bracketDepth++;
        else if (char == ']')
          bracketDepth--;
        else if (char == ',' && braceDepth == 0 && bracketDepth == 0) {
          final item = content.substring(start, i).trim();
          result.add(_parseValue(item));
          start = i + 1;
        }
      }
    }

    final item = content.substring(start).trim();
    if (item.isNotEmpty) {
      result.add(_parseValue(item));
    }

    return result;
  }

  static String _jsonEncode(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;

    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;

      // Key
      buffer.write('"$key":');

      // Value
      if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else if (value is num) {
        buffer.write(value);
      } else if (value is bool) {
        buffer.write(value);
      } else if (value == null) {
        buffer.write('null');
      } else if (value is DateTime) {
        buffer.write('"${value.toIso8601String()}"');
      } else if (value is Map) {
        buffer.write(_jsonEncode(Map<String, dynamic>.from(value)));
      } else if (value is List) {
        buffer.write('[');
        for (var i = 0; i < value.length; i++) {
          if (i > 0) buffer.write(',');
          if (value[i] is Map) {
            buffer.write(_jsonEncode(Map<String, dynamic>.from(value[i])));
          } else if (value[i] is String) {
            buffer.write('"${value[i]}"');
          } else {
            buffer.write(value[i].toString());
          }
        }
        buffer.write(']');
      } else {
        buffer.write('"$value"');
      }
    });

    buffer.write('}');
    return buffer.toString();
  }

  // Clear all data (for testing/reset)
  static Future<void> clearAllData() async {
    await _prefs.clear();
    await _initializeDefaults();
  }

  // Backup data (export as JSON string)
  static Future<String> backupData() async {
    final allData = <String, dynamic>{};

    allData['shops'] = (await getShops()).map((s) => s.toJson()).toList();
    allData['products'] = (await getProducts()).map((p) => p.toJson()).toList();
    allData['purchases'] =
        (await getPurchases()).map((p) => p.toJson()).toList();
    allData['price_history'] =
        (await getPriceHistory()).map((p) => p.toJson()).toList();
    allData['shop_transfers'] =
        (await getShopTransfers()).map((t) => t.toJson()).toList();
    allData['product_transfers'] =
        (await getProductTransfers()).map((t) => t.toJson()).toList();
    allData['shop_closings'] =
        (await getShopClosings()).map((c) => c.toJson()).toList();
    allData['expense_categories'] =
        (await getExpenseCategories()).map((c) => c.toJson()).toList();
    allData['expenses'] = (await getExpenses()).map((e) => e.toJson()).toList();

    return _jsonEncode(allData);
  }
}
