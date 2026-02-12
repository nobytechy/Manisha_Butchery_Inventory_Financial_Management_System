import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import '../../models/shop.dart';

class FinancialReportPage extends StatefulWidget {
  final Shop selectedShop;

  const FinancialReportPage({super.key, required this.selectedShop});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _loading = false;
  Map<String, double> _financialData = {};
  List<Map<String, dynamic>> _expenseDetails = [];

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() {
      _loading = true;
      _financialData = {};
      _expenseDetails = [];
    });

    // Get all necessary data
    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    final allPurchases = await SharedPrefsService.getPurchases(
      shopId: widget.selectedShop.id,
    );

    final allShopTransfers = await SharedPrefsService.getShopTransfers(
      shopId: widget.selectedShop.id,
    );

    final allProductTransfers = await SharedPrefsService.getProductTransfers(
      shopId: widget.selectedShop.id,
    );

    final allClosings = await SharedPrefsService.getShopClosings(
      shopId: widget.selectedShop.id,
    );

    final allExpenses = await SharedPrefsService.getExpenses(
      shopId: widget.selectedShop.id,
    );

    // Initialize totals
    double totalSales = 0;
    double totalCostOfSales = 0;
    double totalOpeningStock = 0;
    double totalPurchases = 0;
    double totalClosingStock = 0;

    // Process for each day in the date range
    DateTime currentDate =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    DateTime endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);

    // For each day in range
    while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      final reportDate = currentDate;
      final previousDate = reportDate.subtract(const Duration(days: 1));

      // Filter data for current date
      final purchases = allPurchases
          .where(
            (p) =>
                p.date.year == reportDate.year &&
                p.date.month == reportDate.month &&
                p.date.day == reportDate.day,
          )
          .toList();

      final shopTransfers = allShopTransfers
          .where(
            (t) =>
                t.date.year == reportDate.year &&
                t.date.month == reportDate.month &&
                t.date.day == reportDate.day,
          )
          .toList();

      final productTransfers = allProductTransfers
          .where(
            (t) =>
                t.date.year == reportDate.year &&
                t.date.month == reportDate.month &&
                t.date.day == reportDate.day,
          )
          .toList();

      final closings = allClosings
          .where(
            (c) =>
                c.date.year == reportDate.year &&
                c.date.month == reportDate.month &&
                c.date.day == reportDate.day,
          )
          .toList();

      final previousClosings = allClosings
          .where(
            (c) =>
                c.date.year == previousDate.year &&
                c.date.month == previousDate.month &&
                c.date.day == previousDate.day,
          )
          .toList();

      // Calculate for each product
      for (var product in products) {
        // Opening stock from previous day's closing
        double openingQty = 0;
        if (previousClosings.isNotEmpty) {
          final prevClosing = previousClosings.first;
          openingQty = prevClosing.productQuantities[product.id] ?? 0;
        }

        // Purchases for this product
        double purchasesQty = purchases
            .where((p) => p.productId == product.id)
            .fold(0, (sum, p) => sum + p.quantity);

        // Shop transfers
        double shopTransferInQty = shopTransfers
            .where(
              (t) =>
                  t.productId == product.id &&
                  t.toShopId == widget.selectedShop.id,
            )
            .fold(0, (sum, t) => sum + t.quantity);

        double shopTransferOutQty = shopTransfers
            .where(
              (t) =>
                  t.productId == product.id &&
                  t.fromShopId == widget.selectedShop.id,
            )
            .fold(0, (sum, t) => sum + t.quantity);

        // Product transfers
        double productTransferInQty = productTransfers
            .where((t) => t.toProductId == product.id)
            .fold(0, (sum, t) => sum + t.quantity);

        double productTransferOutQty = productTransfers
            .where((t) => t.fromProductId == product.id)
            .fold(0, (sum, t) => sum + t.quantity);

        // Actual closing stock
        double closingQty = 0;
        if (closings.isNotEmpty) {
          final closing = closings.first;
          closingQty = closing.productQuantities[product.id] ?? 0;
        }

        // Calculations using stocks report logic
        double totalIn = openingQty +
            purchasesQty +
            shopTransferInQty +
            productTransferInQty;
        double totalOut = shopTransferOutQty + productTransferOutQty;
        double theoreticalClosing = totalIn - totalOut;
        double salesQty = theoreticalClosing - closingQty;

        if (salesQty > 0) {
          // SALES VALUE: Use PRICE (not cost) for sales value
          double salesValue = salesQty * product.currentPrice;
          double costOfSales = salesQty * product.currentCost;

          totalSales += salesValue;
          totalCostOfSales += costOfSales;

          // STOCK VALUES: Use COST for stock values
          totalOpeningStock += openingQty * product.currentCost;
          totalPurchases += purchasesQty * product.currentCost;
        }

        // Closing stock always uses cost
        totalClosingStock += closingQty * product.currentCost;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Calculate expenses for the date range
    final expenses = allExpenses
        .where(
          (e) =>
              e.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              e.date.isBefore(_endDate.add(const Duration(days: 1))),
        )
        .toList();

    double totalExpenses = 0;
    Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      totalExpenses += expense.amount;
      categoryTotals[expense.categoryName] =
          (categoryTotals[expense.categoryName] ?? 0) + expense.amount;
    }

    // Convert category totals to list for display
    _expenseDetails = categoryTotals.entries.map((entry) {
      return {
        'category': entry.key,
        'amount': entry.value,
      };
    }).toList();

    // Sort expenses by amount (highest first)
    _expenseDetails.sort((a, b) => b['amount'].compareTo(a['amount']));

    // Calculate trading account values
    double costOfGoodsAvailable = totalOpeningStock + totalPurchases;
    double costOfGoodsSold = costOfGoodsAvailable - totalClosingStock;
    double grossProfit = totalSales - costOfGoodsSold;
    double netProfit = grossProfit - totalExpenses;

    setState(() {
      _financialData = {
        'sales': totalSales,
        'cost_of_sales': totalCostOfSales,
        'opening_stock': totalOpeningStock,
        'purchases': totalPurchases,
        'closing_stock': totalClosingStock,
        'cost_of_goods_available': costOfGoodsAvailable,
        'cost_of_goods_sold': costOfGoodsSold,
        'gross_profit': grossProfit,
        'expenses': totalExpenses,
        'net_profit': netProfit,
      };
      _loading = false;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      await _generateReport();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      await _generateReport();
    }
  }

  Widget _buildSalesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attach_money,
                    size: 20, color: Colors.green),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'TOTAL SALES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'USD ${(_financialData['sales'] ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'From ${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cost of Sales:',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'USD ${(_financialData['cost_of_sales'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingAccount() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trading Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),

          // Opening Stock (Cost)
          _buildSimpleRow(
            'Opening Stock',
            _financialData['opening_stock'] ?? 0,
            icon: Icons.inventory,
            color: Colors.blue,
          ),

          // Purchases (Cost)
          _buildSimpleRow(
            'Add: Purchases',
            _financialData['purchases'] ?? 0,
            icon: Icons.shopping_cart,
            color: Colors.orange,
          ),

          // Cost of Goods Available
          _buildSimpleRow(
            'Cost of Goods Available',
            _financialData['cost_of_goods_available'] ?? 0,
            isBold: true,
            color: Colors.purple,
          ),

          // Less: Closing Stock
          _buildSimpleRow(
            'Less: Closing Stock',
            _financialData['closing_stock'] ?? 0,
            icon: Icons.inventory_2,
            color: Colors.deepPurple,
            isCredit: true,
          ),

          const Divider(height: 20, thickness: 2),

          // Cost of Goods Sold
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cost of Goods Sold',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'USD ${(_financialData['cost_of_goods_sold'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Sales (Price)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'USD ${(_financialData['sales'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 20, thickness: 2),

          // Gross Profit
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: (_financialData['gross_profit'] ?? 0) >= 0
                    ? [Colors.green.shade100, Colors.green.shade50]
                    : [Colors.red.shade100, Colors.red.shade50],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_financialData['gross_profit'] ?? 0) >= 0
                    ? Colors.green.shade300
                    : Colors.red.shade300,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (_financialData['gross_profit'] ?? 0) >= 0
                      ? 'GROSS PROFIT'
                      : 'GROSS LOSS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: (_financialData['gross_profit'] ?? 0) >= 0
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                Text(
                  'USD ${(_financialData['gross_profit'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: (_financialData['gross_profit'] ?? 0) >= 0
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossAccount() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Profit & Loss Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),

          // Gross Profit
          _buildSimpleRow('Gross Profit', _financialData['gross_profit'] ?? 0),

          const SizedBox(height: 12),

          // Expenses Header
          const Text(
            'Less: Expenses',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Expense Items
          if (_expenseDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                'No expenses recorded',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
          else
            ..._expenseDetails.map((expense) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '• ${expense['category']}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'USD ${(expense['amount'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          const Divider(height: 16, thickness: 1),

          // Total Expenses
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Expenses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'USD ${(_financialData['expenses'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 20, thickness: 2),

          // Net Profit
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: (_financialData['net_profit'] ?? 0) >= 0
                    ? [Colors.green.shade100, Colors.green.shade50]
                    : [Colors.red.shade100, Colors.red.shade50],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_financialData['net_profit'] ?? 0) >= 0
                    ? Colors.green.shade300
                    : Colors.red.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_financialData['net_profit'] ?? 0) >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (_financialData['net_profit'] ?? 0) >= 0
                      ? 'NET PROFIT'
                      : 'NET LOSS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: (_financialData['net_profit'] ?? 0) >= 0
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                Text(
                  'USD ${(_financialData['net_profit'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: (_financialData['net_profit'] ?? 0) >= 0
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    IconData? icon,
    bool isCredit = false,
  }) {
    final displayAmount = isCredit ? -amount : amount;
    final displayColor =
        color ?? (displayAmount >= 0 ? Colors.black : Colors.red);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: displayColor),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                      color: displayColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: displayColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'USD ${displayAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: displayColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Metrics',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            padding: EdgeInsets.zero,
            children: [
              _buildMetricCard(
                'Gross Profit %',
                _financialData['sales'] != null && _financialData['sales']! > 0
                    ? '${((_financialData['gross_profit'] ?? 0) / (_financialData['sales'] ?? 1) * 100).toStringAsFixed(1)}%'
                    : '0.0%',
                Colors.green,
                Icons.percent,
              ),
              _buildMetricCard(
                'Net Profit %',
                _financialData['sales'] != null && _financialData['sales']! > 0
                    ? '${((_financialData['net_profit'] ?? 0) / (_financialData['sales'] ?? 1) * 100).toStringAsFixed(1)}%'
                    : '0.0%',
                (_financialData['net_profit'] ?? 0) >= 0
                    ? Colors.green
                    : Colors.red,
                Icons.trending_up,
              ),
              _buildMetricCard(
                'Expense Ratio',
                _financialData['sales'] != null && _financialData['sales']! > 0
                    ? '${((_financialData['expenses'] ?? 0) / (_financialData['sales'] ?? 1) * 100).toStringAsFixed(1)}%'
                    : '0.0%',
                Colors.orange,
                Icons.pie_chart,
              ),
              _buildMetricCard(
                'Stock Turnover',
                '${((_financialData['cost_of_goods_sold'] ?? 0) > 0 && ((_financialData['opening_stock'] ?? 0) + (_financialData['closing_stock'] ?? 0)) > 0) ? ((_financialData['cost_of_goods_sold'] ?? 0) / ((_financialData['opening_stock'] ?? 0) + (_financialData['closing_stock'] ?? 0)) / 2).toStringAsFixed(1) : '0.0'}x',
                Colors.blue,
                Icons.autorenew,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Financial Report - ${widget.selectedShop.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Date Range Selector
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From Date',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _selectStartDate,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _startDate.toString().split(' ')[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To Date',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _selectEndDate,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _endDate.toString().split(' ')[0],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Update Report',
                          style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading or Content
          if (_loading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Calculating financial report...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Total Sales Banner
                    _buildSalesSection(),

                    // Key Metrics
                    _buildKeyMetrics(),

                    // Trading Account
                    _buildTradingAccount(),

                    // Profit & Loss Account
                    _buildProfitLossAccount(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
