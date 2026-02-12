// ignore_for_file: unused_field, unused_import

import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../models/transfer.dart';
import '../../models/closing.dart';

class StocksReportPage extends StatefulWidget {
  final Shop selectedShop;

  const StocksReportPage({super.key, required this.selectedShop});

  @override
  State<StocksReportPage> createState() => _StocksReportPageState();
}

class _StocksReportPageState extends State<StocksReportPage> {
  List<Product> _products = [];
  DateTime? _selectedDate;
  bool _loading = false;
  List<Map<String, dynamic>> _reportData = [];
  Map<String, double> _totals = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _reportData = [];
      _totals = {};
    });

    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    if (_selectedDate == null) return;

    final reportDate = _selectedDate!;
    final previousDate = reportDate.subtract(const Duration(days: 1));

    // Get all data for calculations
    final allPurchases = await SharedPrefsService.getPurchases(
      shopId: widget.selectedShop.id,
    );

    // Get ALL shop transfers without filtering
    final allShopTransfers = await SharedPrefsService.getAllShopTransfers();

    final allProductTransfers = await SharedPrefsService.getProductTransfers(
      shopId: widget.selectedShop.id,
    );

    final allClosings = await SharedPrefsService.getShopClosings(
      shopId: widget.selectedShop.id,
    );

    // Filter data for selected date
    final purchases = allPurchases
        .where(
          (p) =>
              p.date.year == reportDate.year &&
              p.date.month == reportDate.month &&
              p.date.day == reportDate.day,
        )
        .toList();

    // Filter shop transfers for selected date (ALL transfers for the date)
    final shopTransfersForDate = allShopTransfers
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

    // Calculate report for each product
    for (var product in products) {
      // Opening stock from previous day's closing
      double opening = 0;
      if (previousClosings.isNotEmpty) {
        final prevClosing = previousClosings.first;
        opening = prevClosing.productQuantities[product.id] ?? 0;
      }

      // Purchases for this product
      double purchasesQty = purchases
          .where((p) => p.productId == product.id)
          .fold(0, (sum, p) => sum + p.quantity);

      // Shop transfers IN (to this shop for this product)
      // Match by product ID first, then by name
      double shopTransferIn = 0;

      // 1. Match by product ID
      shopTransferIn = shopTransfersForDate
          .where(
            (t) =>
                t.productId == product.id &&
                t.toShopId == widget.selectedShop.id,
          )
          .fold(0, (sum, t) => sum + t.quantity);

      // 2. If no matches by ID, try matching by product name (case-insensitive)
      if (shopTransferIn == 0) {
        shopTransferIn = shopTransfersForDate
            .where(
              (t) =>
                  t.productName.toLowerCase() == product.name.toLowerCase() &&
                  t.toShopId == widget.selectedShop.id,
            )
            .fold(0, (sum, t) => sum + t.quantity);
      }

      // Shop transfers OUT (from this shop for this product)
      double shopTransferOut = 0;

      // 1. Match by product ID
      shopTransferOut = shopTransfersForDate
          .where(
            (t) =>
                t.productId == product.id &&
                t.fromShopId == widget.selectedShop.id,
          )
          .fold(0, (sum, t) => sum + t.quantity);

      // 2. If no matches by ID, try matching by product name (case-insensitive)
      if (shopTransferOut == 0) {
        shopTransferOut = shopTransfersForDate
            .where(
              (t) =>
                  t.productName.toLowerCase() == product.name.toLowerCase() &&
                  t.fromShopId == widget.selectedShop.id,
            )
            .fold(0, (sum, t) => sum + t.quantity);
      }

      // Product transfers IN (to this product)
      double productTransferIn = productTransfers
          .where((t) => t.toProductId == product.id)
          .fold(0, (sum, t) => sum + t.quantity);

      // Product transfers OUT (from this product)
      double productTransferOut = productTransfers
          .where((t) => t.fromProductId == product.id)
          .fold(0, (sum, t) => sum + t.quantity);

      // Actual closing stock
      double actualClosing = 0;
      if (closings.isNotEmpty) {
        final closing = closings.first;
        actualClosing = closing.productQuantities[product.id] ?? 0;
      }

      // Calculations
      double totalIn =
          opening + purchasesQty + shopTransferIn + productTransferIn;
      double totalOut = shopTransferOut + productTransferOut;
      double theoreticalClosing = totalIn - totalOut;
      double salesQty = theoreticalClosing - actualClosing;
      double salesCost = salesQty * product.currentCost;
      double salesPrice = salesQty * product.currentPrice;
      double grossProfit = salesPrice - salesCost;

      Map<String, dynamic> row = {
        'product': product.name,
        'product_id': product.id,
        'cost': product.currentCost,
        'price': product.currentPrice,
        'opening': opening,
        'purchases': purchasesQty,
        'transfer_in': productTransferIn,
        'shop_transfer_in': shopTransferIn,
        'total_in': totalIn,
        'transfer_out': productTransferOut,
        'shop_transfer_out': shopTransferOut,
        'total_out': totalOut,
        'actual_closing': actualClosing,
        'theoretical_closing': theoreticalClosing,
        'sales_qty': salesQty,
        'sales_cost': salesCost,
        'sales_price': salesPrice,
        'gross_profit': grossProfit,
      };

      _reportData.add(row);

      // Update totals
      for (var key in row.keys) {
        if (row[key] is double) {
          _totals[key] = (_totals[key] ?? 0) + (row[key] as double);
        }
      }
    }

    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadReport();
    }
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 12,
          horizontalMargin: 12,
          columns: const [
            DataColumn(
              label: Text(
                'Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              tooltip: 'Product name',
            ),
            DataColumn(
              label:
                  Text('Cost', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
              tooltip: 'Cost per kg',
            ),
            DataColumn(
              label:
                  Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
              tooltip: 'Selling price per kg',
            ),
            DataColumn(
              label: Text(
                'Opening',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Opening stock (kg)',
            ),
            DataColumn(
              label: Text(
                'Purchases',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Purchases (kg)',
            ),
            DataColumn(
              label:
                  Text('P-T-In', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
              tooltip: 'Product Transfer In (kg)',
            ),
            DataColumn(
              label:
                  Text('S-T-In', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
              tooltip: 'Shop Transfer In (kg)',
            ),
            DataColumn(
              label: Text(
                'Total In',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Total Incoming (kg)',
            ),
            DataColumn(
              label: Text('P-T-Out',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
              tooltip: 'Product Transfer Out (kg)',
            ),
            DataColumn(
              label: Text('S-T-Out',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
              tooltip: 'Shop Transfer Out (kg)',
            ),
            DataColumn(
              label: Text(
                'Total Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Total Outgoing (kg)',
            ),
            DataColumn(
              label: Text(
                'Act Close',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Actual Closing (kg)',
            ),
            DataColumn(
              label: Text(
                'Theo Close',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Theoretical Closing (kg)',
            ),
            DataColumn(
              label: Text(
                'Sales Qty',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Sales Quantity (kg)',
            ),
            DataColumn(
              label: Text(
                'Sales Cost',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Total Sales Cost',
            ),
            DataColumn(
              label: Text(
                'Sales Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Total Sales Price',
            ),
            DataColumn(
              label: Text(
                'Profit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
              tooltip: 'Gross Profit',
            ),
          ],
          rows: [
            ..._reportData.map((row) {
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        row['product'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(row['cost'].toStringAsFixed(2))),
                  DataCell(Text(row['price'].toStringAsFixed(2))),
                  DataCell(Text(row['opening'].toStringAsFixed(2))),
                  DataCell(Text(row['purchases'].toStringAsFixed(2))),
                  DataCell(
                    Tooltip(
                      message: 'Product Transfer In',
                      child: Text(row['transfer_in'].toStringAsFixed(2)),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: 'Shop Transfer In',
                      child: Text(row['shop_transfer_in'].toStringAsFixed(2)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        row['total_in'].toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: 'Product Transfer Out',
                      child: Text(row['transfer_out'].toStringAsFixed(2)),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: 'Shop Transfer Out',
                      child: Text(row['shop_transfer_out'].toStringAsFixed(2)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        row['total_out'].toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(Text(row['actual_closing'].toStringAsFixed(2))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          Text(row['theoretical_closing'].toStringAsFixed(2)),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        row['sales_qty'].toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(Text(row['sales_cost'].toStringAsFixed(2))),
                  DataCell(Text(row['sales_price'].toStringAsFixed(2))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (row['gross_profit'] as double) >= 0
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (row['gross_profit'] as double) >= 0
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        row['gross_profit'].toStringAsFixed(2),
                        style: TextStyle(
                          color: (row['gross_profit'] as double) >= 0
                              ? Colors.green[800]
                              : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_totals.isNotEmpty)
              DataRow(
                color: WidgetStateProperty.all(Colors.grey[50]),
                cells: [
                  const DataCell(
                    Text('TOTALS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child:
                          Text(_totals['cost']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child:
                          Text(_totals['price']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                          _totals['opening']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                          _totals['purchases']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                          _totals['transfer_in']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                        _totals['shop_transfer_in']?.toStringAsFixed(2) ??
                            '0.00',
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        border: Border(
                            top:
                                BorderSide(color: Colors.blue[300]!, width: 2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _totals['total_in']?.toStringAsFixed(2) ?? '0.00',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(_totals['transfer_out']?.toStringAsFixed(2) ??
                          '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                        _totals['shop_transfer_out']?.toStringAsFixed(2) ??
                            '0.00',
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        border: Border(
                            top: BorderSide(color: Colors.red[300]!, width: 2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _totals['total_out']?.toStringAsFixed(2) ?? '0.00',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                          _totals['actual_closing']?.toStringAsFixed(2) ??
                              '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                        _totals['theoretical_closing']?.toStringAsFixed(2) ??
                            '0.00',
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        border: Border(
                            top: BorderSide(
                                color: Colors.green[300]!, width: 2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _totals['sales_qty']?.toStringAsFixed(2) ?? '0.00',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                          _totals['sales_cost']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Text(
                          _totals['sales_price']?.toStringAsFixed(2) ?? '0.00'),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_totals['gross_profit'] ?? 0) >= 0
                            ? Colors.green[200]
                            : Colors.red[200],
                        border: Border(
                          top: BorderSide(
                            color: (_totals['gross_profit'] ?? 0) >= 0
                                ? Colors.green[400]!
                                : Colors.red[400]!,
                            width: 2,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _totals['gross_profit']?.toStringAsFixed(2) ?? '0.00',
                        style: TextStyle(
                          color: (_totals['gross_profit'] ?? 0) >= 0
                              ? Colors.green[900]
                              : Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stocks Report - ${widget.selectedShop.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Refresh Report',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // FIXED: Use LayoutBuilder to constrain the Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF90CAF9)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF1976D2),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _selectedDate != null
                                            ? _selectedDate!
                                                .toString()
                                                .split(' ')[0]
                                            : 'Select date',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF1976D2),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _loadReport,
                            icon: const Icon(Icons.calculate, size: 16),
                            label: const Text('Calculate',
                                style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: P-T = Product Transfer, S-T = Shop Transfer',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Calculating report...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (_reportData.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.assessment_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No report data available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Select a date and click Calculate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadReport,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate Report'),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                child: _buildSummaryBox(
                                  'Total In',
                                  _totals['total_in'] ?? 0,
                                  Colors.blue,
                                  Icons.call_received,
                                ),
                              ),
                              Flexible(
                                child: _buildSummaryBox(
                                  'Total Out',
                                  _totals['total_out'] ?? 0,
                                  Colors.red,
                                  Icons.call_made,
                                ),
                              ),
                              Flexible(
                                child: _buildSummaryBox(
                                  'Shop T-In',
                                  _totals['shop_transfer_in'] ?? 0,
                                  Colors.green,
                                  Icons.store_mall_directory,
                                ),
                              ),
                              Flexible(
                                child: _buildSummaryBox(
                                  'Shop T-Out',
                                  _totals['shop_transfer_out'] ?? 0,
                                  Colors.orange,
                                  Icons.store,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildDataTable(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_loading && _reportData.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gross Profit Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'For selected date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_totals['gross_profit'] ?? 0) >= 0
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_totals['gross_profit'] ?? 0) >= 0
                                    ? Colors.green[300]!
                                    : Colors.red[300]!,
                              ),
                            ),
                            child: Text(
                              'USD ${(_totals['gross_profit'] ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: (_totals['gross_profit'] ?? 0) >= 0
                                    ? Colors.green[900]
                                    : Colors.red[900],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _buildSummaryItem(
                            'Sales Value',
                            _totals['sales_price'] ?? 0,
                            Colors.green,
                          ),
                        ),
                        Flexible(
                          child: _buildSummaryItem(
                            'Sales Cost',
                            _totals['sales_cost'] ?? 0,
                            Colors.blue,
                          ),
                        ),
                        Flexible(
                          child: _buildSummaryItem(
                            'Profit Margin',
                            _totals['sales_price'] != null &&
                                    _totals['sales_price']! > 0
                                ? ((_totals['gross_profit'] ?? 0) /
                                    _totals['sales_price']! *
                                    100)
                                : 0,
                            Colors.purple,
                            isPercent: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
      String title, double value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color,
      {bool isPercent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            isPercent
                ? '${value.toStringAsFixed(1)}%'
                : 'USD ${value.toStringAsFixed(2)}',
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
}
