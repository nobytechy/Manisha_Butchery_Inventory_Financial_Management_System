import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/closing.dart';

class RecordClosingPage extends StatefulWidget {
  final Shop selectedShop;

  const RecordClosingPage({super.key, required this.selectedShop});

  @override
  State<RecordClosingPage> createState() => _RecordClosingPageState();
}

class _RecordClosingPageState extends State<RecordClosingPage> {
  List<Product> _products = [];
  final Map<String, TextEditingController> _quantityControllers = {};
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    setState(() {
      _products = products;
      _loading = false;
    });

    // Initialize controllers
    for (var product in products) {
      _quantityControllers[product.id] = TextEditingController();
    }
  }

  Future<void> _saveClosing() async {
    // Check if already closed for this date
    final existingClosings = await SharedPrefsService.getShopClosings(
      shopId: widget.selectedShop.id,
      date: _selectedDate,
    );

    if (existingClosings.isNotEmpty) {
      showErrorToast(
        'Already closed for ${_selectedDate.toString().split(' ')[0]}',
      );
      return;
    }

    // Validate all quantities are entered
    final productQuantities = <String, double>{};
    bool hasErrors = false;

    for (var product in _products) {
      final controller = _quantityControllers[product.id];
      final text = controller?.text.trim() ?? '';

      if (text.isEmpty) {
        showErrorToast('Please enter quantity for ${product.name}');
        hasErrors = true;
        break;
      }

      final quantity = double.tryParse(text);
      if (quantity == null || quantity < 0) {
        showErrorToast('Invalid quantity for ${product.name}');
        hasErrors = true;
        break;
      }

      productQuantities[product.id] = quantity;
    }

    if (hasErrors) return;

    final closing = ShopClosing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopId: widget.selectedShop.id,
      date: _selectedDate,
      productQuantities: productQuantities,
    );

    await SharedPrefsService.saveShopClosing(closing);

    // Auto-close warehouse
    await _autoCloseWarehouse();

    showSuccessToast('Closing recorded successfully');

    // Clear all fields
    for (var controller in _quantityControllers.values) {
      controller.clear();
    }

    // Move to next day
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _autoCloseWarehouse() async {
    final shops = await SharedPrefsService.getShops();
    final warehouse = shops.firstWhere((s) => s.isWarehouse);

    // Check if warehouse already closed today
    final existingClosings = await SharedPrefsService.getShopClosings(
      shopId: warehouse.id,
      date: _selectedDate,
    );

    if (existingClosings.isEmpty) {
      // Auto-close warehouse with zero quantities
      final warehouseProducts = await SharedPrefsService.getProducts(
        shopId: warehouse.id,
      );

      final productQuantities = <String, double>{};
      for (var product in warehouseProducts) {
        productQuantities[product.id] = 0.0;
      }

      final closing = ShopClosing(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shopId: warehouse.id,
        date: _selectedDate,
        productQuantities: productQuantities,
      );

      await SharedPrefsService.saveShopClosing(closing);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Record Closing - ${widget.selectedShop.name}'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text('No products found', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text(
                'Please add products first',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Record Closing - ${widget.selectedShop.name}'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Closing Date:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF1E3A8A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter closing quantities for all products',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final controller = _quantityControllers[product.id]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Price: USD ${product.currentPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cost: USD ${product.currentCost.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Closing Quantity (kg)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.scale),
                            suffixText: 'kg',
                            errorText: controller.text.isNotEmpty &&
                                    double.tryParse(controller.text) == null
                                ? 'Invalid number'
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _products.every((product) {
                  final controller = _quantityControllers[product.id]!;
                  final text = controller.text.trim();
                  if (text.isEmpty) return false;
                  final quantity = double.tryParse(text);
                  return quantity != null && quantity >= 0;
                })
                    ? _saveClosing
                    : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'SAVE CLOSING STOCK',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
