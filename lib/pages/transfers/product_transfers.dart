import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/product.dart';
import '../../models/transfer.dart';

class ProductTransfersPage extends StatefulWidget {
  final Shop selectedShop;

  const ProductTransfersPage({super.key, required this.selectedShop});

  @override
  State<ProductTransfersPage> createState() => _ProductTransfersPageState();
}

class _ProductTransfersPageState extends State<ProductTransfersPage> {
  List<ProductTransfer> _transfers = [];
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transfers = await SharedPrefsService.getProductTransfers(
      shopId: widget.selectedShop.id,
    );
    final products = await SharedPrefsService.getProducts(
      shopId: widget.selectedShop.id,
    );

    setState(() {
      _transfers = transfers;
      _products = products;
    });
  }

  void _addTransfer() {
    if (_products.length < 2) {
      showErrorToast('Need at least 2 products for transfers');
      return;
    }

    showAddProductTransferModal(
      context,
      products: _products,
      onSave: (fromProductId, toProductId, quantity, date) async {
        final fromProduct = _products.firstWhere((p) => p.id == fromProductId);
        final toProduct = _products.firstWhere((p) => p.id == toProductId);

        final transfer = ProductTransfer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: widget.selectedShop.id,
          fromProductId: fromProductId,
          toProductId: toProductId,
          fromProductName: fromProduct.name,
          toProductName: toProduct.name,
          quantity: quantity,
          date: date,
        );

        await SharedPrefsService.saveProductTransfer(transfer);

        showSuccessToast('Product transfer saved successfully');
        _loadData();
      },
    );
  }

  void _editTransfer(ProductTransfer transfer) {
    showEditProductTransferModal(
      context,
      transfer: transfer,
      onSave: (quantity, date) async {
        transfer.quantity = quantity;
        transfer.date = date;

        await SharedPrefsService.saveProductTransfer(transfer);
        showSuccessToast('Transfer updated successfully');
        _loadData();
      },
    );
  }

  void _deleteTransfer(ProductTransfer transfer) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Transfer',
      message: 'Are you sure you want to delete this product transfer?',
      onConfirm: () async {
        final transfers = await SharedPrefsService.getProductTransfers();
        transfers.removeWhere((t) => t.id == transfer.id);
        await SharedPrefsService.saveList(
          'product_transfers',
          transfers.map((t) => t.toJson()).toList(),
        );

        showSuccessToast('Transfer deleted successfully');
        _loadData();
      },
    );
  }

  List<ProductTransfer> _getFilteredTransfers() {
    List<ProductTransfer> filtered = _transfers;

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
                t.fromProductName.toLowerCase().contains(search) ||
                t.toProductName.toLowerCase().contains(search),
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
        title: Text('Product Transfers - ${widget.selectedShop.name}'),
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
                          Icons.swap_horizontal_circle,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No product transfers found',
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.swap_horiz,
                            color: Color(0xFF1E3A8A),
                          ),
                          title: Text(
                            '${transfer.fromProductName} → ${transfer.toProductName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
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
