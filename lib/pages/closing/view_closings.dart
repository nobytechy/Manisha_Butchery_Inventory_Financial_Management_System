import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/closing.dart';
import '../../models/product.dart';

class ViewClosingsPage extends StatefulWidget {
  final Shop selectedShop;

  const ViewClosingsPage({super.key, required this.selectedShop});

  @override
  State<ViewClosingsPage> createState() => _ViewClosingsPageState();
}

class _ViewClosingsPageState extends State<ViewClosingsPage> {
  List<ShopClosing> _closings = [];
  List<Shop> _shops = [];
  List<Product> _products = [];
  String? _selectedShopId; // Change from Shop? to String?
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with the widget's selected shop id immediately
    _selectedShopId = widget.selectedShop.id;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final closings = await SharedPrefsService.getShopClosings(
        shopId: widget.selectedShop.id,
      );
      final shops = await SharedPrefsService.getShops();
      final products = await SharedPrefsService.getProducts(
        shopId: widget.selectedShop.id,
      );

      setState(() {
        _closings = closings;
        _shops = shops;
        _products = products;
        // Ensure _selectedShopId is never null
        _selectedShopId ??= widget.selectedShop.id;
      });
    } catch (error) {
      // Handle error appropriately
      print('Error loading data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Shop? get _selectedShop {
    if (_selectedShopId == null) return null;
    return _shops.firstWhere(
      (shop) => shop.id == _selectedShopId,
      orElse: () => widget.selectedShop,
    );
  }

  List<ShopClosing> _getFilteredClosings() {
    List<ShopClosing> filtered = _closings;

    if (_selectedShopId != null) {
      filtered = filtered.where((c) => c.shopId == _selectedShopId).toList();
    }

    if (_selectedDate != null) {
      filtered = filtered
          .where(
            (c) =>
                c.date.year == _selectedDate!.year &&
                c.date.month == _selectedDate!.month &&
                c.date.day == _selectedDate!.day,
          )
          .toList();
    }

    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  double _getTotalValue(ShopClosing closing) {
    double total = 0;
    closing.productQuantities.forEach((productId, quantity) {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(
          id: '',
          shopId: '',
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );
      total += quantity * product.currentPrice;
    });
    return total;
  }

  void _showClosingDetails(ShopClosing closing) {
    showClosingDetailsModal(
      context,
      closing: closing,
      products: _products,
      shopName: _shops
          .firstWhere(
            (s) => s.id == closing.shopId,
            orElse: () =>
                Shop(id: '', name: 'Unknown', createdAt: DateTime.now()),
          )
          .name,
    );
  }

  void _deleteClosing(ShopClosing closing) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Closing Record',
      message:
          'Are you sure you want to delete closing record for ${closing.date.toString().split(' ')[0]}?',
      onConfirm: () async {
        final closings = await SharedPrefsService.getShopClosings();
        closings.removeWhere((c) => c.id == closing.id);
        await SharedPrefsService.saveList(
          'shop_closings',
          closings.map((c) => c.toJson()).toList(),
        );

        // Show success message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Closing record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

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

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedShopId = widget.selectedShop.id;
      _selectedDate = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredClosings = _getFilteredClosings();
    final currentSelectedShop = _selectedShop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Closing Stocks'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Shop',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    value: _selectedShopId,
                    items: _shops.map((shop) {
                      return DropdownMenuItem<String>(
                        value: shop.id,
                        child: Text(shop.name),
                      );
                    }).toList(),
                    onChanged: (shopId) {
                      setState(() {
                        _selectedShopId = shopId;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                      : 'Select date',
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          tooltip: 'Clear date filter',
                        ),
                    ],
                  ),
                  if (_selectedShopId != widget.selectedShop.id ||
                      _selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredClosings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.list, size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        const Text(
                          'No closing records found',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (_selectedShopId != widget.selectedShop.id ||
                            _selectedDate != null)
                          ElevatedButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredClosings.length,
                      itemBuilder: (context, index) {
                        final closing = filteredClosings[index];
                        final shop = _shops.firstWhere(
                          (s) => s.id == closing.shopId,
                          orElse: () => Shop(
                            id: '',
                            name: 'Unknown',
                            createdAt: DateTime.now(),
                          ),
                        );
                        final totalValue = _getTotalValue(closing);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(
                              Icons.inventory,
                              color: Color(0xFF1E3A8A),
                            ),
                            title: Text(
                              shop.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${closing.date.toString().split(' ')[0]}',
                                ),
                                Text(
                                  'Products: ${closing.productQuantities.length}',
                                ),
                                Text(
                                  'Total Value: USD ${totalValue.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20),
                                  onPressed: () => _showClosingDetails(closing),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteClosing(closing),
                                ),
                              ],
                            ),
                            onTap: () => _showClosingDetails(closing),
                          ),
                        );
                      },
                    ),
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
