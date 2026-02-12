import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const primaryColor = Color(0xFF1E3A8A);
  static const secondaryColor = Color(0xFF3B82F6);
  static const backgroundColor = Color(0xFFF0F8FF);
  static const successColor = Color(0xFF10B981);
  static const errorColor = Color(0xFFEF4444);
  static const warningColor = Color(0xFFF59E0B);

  // Text styles
  static const headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const subHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const bodyStyle = TextStyle(fontSize: 16, color: Colors.black87);

  // App strings
  static const appName = 'Manisha Butchery';
  static const appSlogan = 'Fresh Meat, Fresh Profits';

  // Default values
  static const defaultPin = '0000';

  // Date formats
  static const dateFormat = 'yyyy-MM-dd';
  static const dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Storage keys
  static const storageShops = 'shops';
  static const storageProducts = 'products';
  static const storagePurchases = 'purchases';
  static const storagePriceHistory = 'price_history';
  static const storageShopTransfers = 'shop_transfers';
  static const storageProductTransfers = 'product_transfers';
  static const storageShopClosings = 'shop_closings';
  static const storageExpenseCategories = 'expense_categories';
  static const storageExpenses = 'expenses';
  static const storagePin = 'user_pin';
  static const storageSelectedShop = 'selected_shop_id';
}

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const createShop = '/shops/create';
  static const changeShop = '/shops/change';
  static const products = '/products';
  static const purchases = '/purchases';
  static const price = '/price';
  static const shopTransfers = '/transfers/shop';
  static const productTransfers = '/transfers/product';
  static const recordClosing = '/closing/record';
  static const viewClosings = '/closing/view';
  static const expenseCategories = '/expenses/categories';
  static const expenses = '/expenses';
  static const stocksReport = '/reports/stocks';
  static const financialReport = '/reports/financial';
}
