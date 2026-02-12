import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/price.dart';

class PricePage extends StatefulWidget {
  final Shop selectedShop;

  const PricePage({super.key, required this.selectedShop});

  @override
  State<PricePage> createState() => _PricePageState();
}

class _PricePageState extends State<PricePage> {
  List<Product> _products = [];
  List<PriceHistory> _priceHistory = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    setState(() {
      _products = products;
    });
  }

  Future<void> _loadPriceHistory(String productId) async {
    final history = await SharedPrefsService.getPriceHistory(
      productId: productId,
    );

    setState(() {
      _priceHistory = history;
    });
  }

  void _changePrice(Product product) {
    showChangePriceModal(
      context,
      product: product,
      priceHistory: _priceHistory,
      onSave: (newPrice) async {
        final priceHistory = PriceHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.id,
          shopId: widget.selectedShop.id,
          oldPrice: product.currentPrice,
          newPrice: newPrice,
          changedAt: DateTime.now(),
        );

        await SharedPrefsService.savePriceHistory(priceHistory);

        // Update product price
        product.currentPrice = newPrice;
        await SharedPrefsService.updateProduct(product);

        showSuccessToast('Price updated successfully');
        await _loadPriceHistory(product.id);
        _loadData();
      },
    );
  }

  List<Product> _getFilteredProducts() {
    if (_searchController.text.isEmpty) {
      return _products;
    }
    return _products
        .where(
          (product) => product.name.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: Text('Price Management - ${widget.selectedShop.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.attach_money,
                            color: Color(0xFF1E3A8A),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Current Price: USD ${product.currentPrice.toStringAsFixed(2)}/kg',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Current Cost: USD ${product.currentCost.toStringAsFixed(2)}/kg',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Profit Margin: USD ${(product.currentPrice - product.currentCost).toStringAsFixed(2)}/kg',
                                style: TextStyle(
                                  color: (product.currentPrice -
                                              product.currentCost) >=
                                          0
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _loadPriceHistory(product.id);
                              _changePrice(product);
                            },
                            child: const Text('Change Price'),
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
