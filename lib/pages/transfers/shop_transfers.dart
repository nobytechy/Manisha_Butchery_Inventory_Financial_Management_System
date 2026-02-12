import 'package:flutter/material.dart';
import 'package:manisha_butchery/models/closing.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/transfer.dart';

class ShopTransfersPage extends StatefulWidget {
  final Shop selectedShop;

  const ShopTransfersPage({super.key, required this.selectedShop});

  @override
  State<ShopTransfersPage> createState() => _ShopTransfersPageState();
}

class _ShopTransfersPageState extends State<ShopTransfersPage> {
  List<ShopTransfer> _transfers = [];
  List<Shop> _shops = [];
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transfers = await SharedPrefsService.getShopTransfers(
      shopId: widget.selectedShop.id,
    );
    final shops = await SharedPrefsService.getShops();
    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    setState(() {
      _transfers = transfers;
      _shops = shops;
      _products = products;
    });
  }

  void _addTransfer() {
    if (_products.isEmpty) {
      showErrorToast('No products available');
      return;
    }
    if (_shops.length < 2) {
      showErrorToast('Need at least 2 shops for transfers');
      return;
    }

    showAddShopTransferModal(
      context,
      currentShop: widget.selectedShop,
      shops: _shops,
      products: _products,
      onSave: (productId, fromShopId, toShopId, quantity, date) async {
        final product = _products.firstWhere((p) => p.id == productId);
        final fromShop = _shops.firstWhere((s) => s.id == fromShopId);
        final toShop = _shops.firstWhere((s) => s.id == toShopId);

        final transfer = ShopTransfer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: productId,
          fromShopId: fromShopId,
          toShopId: toShopId,
          fromShopName: fromShop.name,
          toShopName: toShop.name,
          productName: product.name,
          quantity: quantity,
          date: date,
        );

        await SharedPrefsService.saveShopTransfer(transfer);

        // Auto-close warehouse if needed
        if (fromShop.isWarehouse || toShop.isWarehouse) {
          await _autoCloseWarehouse();
        }

        showSuccessToast('Transfer saved successfully');
        _loadData();
      },
    );
  }

  Future<void> _autoCloseWarehouse() async {
    final warehouse = _shops.firstWhere((s) => s.isWarehouse);
    final today = DateTime.now();

    // Check if warehouse already closed today
    final existingClosings = await SharedPrefsService.getShopClosings(
      shopId: warehouse.id,
      date: today,
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
        date: today,
        productQuantities: productQuantities,
      );

      await SharedPrefsService.saveShopClosing(closing);
    }
  }

  void _editTransfer(ShopTransfer transfer) {
    showEditShopTransferModal(
      context,
      transfer: transfer,
      onSave: (quantity, date) async {
        transfer.quantity = quantity;
        transfer.date = date;

        await SharedPrefsService.saveShopTransfer(transfer);
        showSuccessToast('Transfer updated successfully');
        _loadData();
      },
    );
  }

  void _deleteTransfer(ShopTransfer transfer) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Transfer',
      message: 'Are you sure you want to delete this transfer record?',
      onConfirm: () async {
        // Note: In production, you might want to mark as deleted instead of removing
        final transfers = await SharedPrefsService.getShopTransfers();
        transfers.removeWhere((t) => t.id == transfer.id);
        await SharedPrefsService.saveList(
          'shop_transfers',
          transfers.map((t) => t.toJson()).toList(),
        );

        showSuccessToast('Transfer deleted successfully');
        _loadData();
      },
    );
  }

  List<ShopTransfer> _getFilteredTransfers() {
    List<ShopTransfer> filtered = _transfers;

    if (_selectedDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.date.year == _selectedDate!.year &&
                t.date.month == _selectedDate!.month &&
                t.date.day == _selectedDate!.day,
          )
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.productName.toLowerCase().contains(search) ||
                t.fromShopName.toLowerCase().contains(search) ||
                t.toShopName.toLowerCase().contains(search),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransfers = _getFilteredTransfers();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Transfers - ${widget.selectedShop.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addTransfer),
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
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Search transfers',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
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
                      },
                      tooltip: 'Filter by date',
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
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Filtering by: ${_selectedDate!.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filteredTransfers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.swap_horiz,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No transfers found',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (_selectedDate != null ||
                            _searchController.text.isNotEmpty)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTransfers.length,
                    itemBuilder: (context, index) {
                      final transfer = filteredTransfers[index];
                      final isIncoming =
                          transfer.toShopId == widget.selectedShop.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color:
                            isIncoming ? Colors.green[50] : Colors.orange[50],
                        child: ListTile(
                          leading: Icon(
                            isIncoming ? Icons.download : Icons.upload,
                            color: isIncoming ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                            transfer.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${transfer.fromShopName} → ${transfer.toShopName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Quantity: ${transfer.quantity} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Date: ${transfer.date.toString().split(' ')[0]}',
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
                                onPressed: () => _editTransfer(transfer),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteTransfer(transfer),
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
