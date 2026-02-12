import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/purchase.dart';

class PurchasesPage extends StatefulWidget {
  final Shop selectedShop;

  const PurchasesPage({super.key, required this.selectedShop});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  List<Purchase> _purchases = [];
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final purchases = await SharedPrefsService.getPurchases(
      shopId: widget.selectedShop.id,
    );
    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    setState(() {
      _purchases = purchases;
      _products = products;
    });
  }

  void _addPurchase() {
    if (_products.isEmpty) {
      showErrorToast('Please add products first');
      return;
    }

    showAddPurchaseModal(
      context,
      products: _products,
      onSave: (productId, quantity, cost, date) async {
        final product = _products.firstWhere((p) => p.id == productId);

        final purchase = Purchase(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: widget.selectedShop.id,
          productId: productId,
          productName: product.name,
          quantity: quantity,
          cost: cost,
          date: date,
        );

        await SharedPrefsService.savePurchase(purchase);

        // Update product cost
        product.currentCost = cost;
        await SharedPrefsService.updateProduct(product);

        showSuccessToast('Purchase added successfully');
        _loadData();
      },
    );
  }

  void _editPurchase(Purchase purchase) {
    showEditPurchaseModal(
      context,
      purchase: purchase,
      onSave: (quantity, cost, date) async {
        purchase.quantity = quantity;
        purchase.cost = cost;
        purchase.date = date;

        await SharedPrefsService.updatePurchase(purchase);

        // Update product cost if this is the latest purchase
        final product = _products.firstWhere((p) => p.id == purchase.productId);
        final purchases = await SharedPrefsService.getPurchases(
          shopId: widget.selectedShop.id,
          productId: purchase.productId,
        );

        if (purchases.isNotEmpty) {
          purchases.sort((a, b) => b.date.compareTo(a.date));
          product.currentCost = purchases.first.cost;
          await SharedPrefsService.updateProduct(product);
        }

        showSuccessToast('Purchase updated successfully');
        _loadData();
      },
    );
  }

  void _deletePurchase(Purchase purchase) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Purchase',
      message: 'Are you sure you want to delete this purchase record?',
      onConfirm: () async {
        await SharedPrefsService.deletePurchase(purchase.id);
        showSuccessToast('Purchase deleted successfully');
        _loadData();
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _searchByDate();
    }
  }

  Future<void> _searchByDate() async {
    if (_selectedDate == null) {
      await _loadData();
      return;
    }

    final purchases = await SharedPrefsService.getPurchases(
      shopId: widget.selectedShop.id,
      date: _selectedDate,
    );

    setState(() {
      _purchases = purchases;
    });
  }

  void _clearSearch() {
    setState(() {
      _selectedDate = null;
      _searchController.clear();
    });
    _loadData();
  }

  double _getTotalPurchases() {
    return _purchases.fold(
      0,
      (sum, purchase) => sum + (purchase.quantity * purchase.cost),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchases - ${widget.selectedShop.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addPurchase),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _searchByDate(),
                        decoration: InputDecoration(
                          labelText: 'Search by date (YYYY-MM-DD)',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _selectedDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                      tooltip: 'Pick Date',
                    ),
                  ],
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Showing purchases for: ${_selectedDate!.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Purchases Value:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'USD ${_getTotalPurchases().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _purchases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No purchases found',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (_selectedDate != null)
                          ElevatedButton(
                            onPressed: _clearSearch,
                            child: const Text('Clear Search'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) {
                      final purchase = _purchases[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.shopping_basket,
                            color: Color(0xFF1E3A8A),
                          ),
                          title: Text(
                            purchase.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${purchase.quantity} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Cost: USD ${purchase.cost.toStringAsFixed(2)}/kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Total: USD ${(purchase.quantity * purchase.cost).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Date: ${purchase.date.toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editPurchase(purchase),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePurchase(purchase),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
