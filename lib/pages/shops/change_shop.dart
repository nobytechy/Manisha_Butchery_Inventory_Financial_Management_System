import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';

class ChangeShopPage extends StatefulWidget {
  final List<Shop> shops;
  final VoidCallback onShopChanged;

  const ChangeShopPage({
    super.key,
    required this.shops,
    required this.onShopChanged,
  });

  @override
  State<ChangeShopPage> createState() => _ChangeShopPageState();
}

class _ChangeShopPageState extends State<ChangeShopPage> {
  Shop? _selectedShop;

  @override
  void initState() {
    super.initState();
    _loadCurrentShop();
  }

  Future<void> _loadCurrentShop() async {
    final shop = await SharedPrefsService.getSelectedShop();
    setState(() {
      _selectedShop = shop;
    });
  }

  Future<void> _changeShop(Shop shop) async {
    await SharedPrefsService.setSelectedShopId(shop.id);
    setState(() {
      _selectedShop = shop;
    });
    widget.onShopChanged();
    showSuccessToast('Shop changed to ${shop.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Shop')),
      body: widget.shops.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No shops available',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Create New Shop'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_selectedShop != null)
                  Card(
                    margin: const EdgeInsets.all(16),
                    color: const Color(0xFFE3F2FD),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _selectedShop!.isWarehouse
                                ? Icons.warehouse
                                : Icons.store,
                            color: const Color(0xFF1E3A8A),
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Shop',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _selectedShop!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: ${_selectedShop!.id.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.green[700]),
                        ],
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Available Shops',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.shops.length,
                    itemBuilder: (context, index) {
                      final shop = widget.shops[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            shop.isWarehouse ? Icons.warehouse : Icons.store,
                            color: const Color(0xFF1E3A8A),
                          ),
                          title: Text(
                            shop.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'ID: ${shop.id.substring(0, 8)}...',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: shop.id == _selectedShop?.id
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green[700],
                                )
                              : null,
                          onTap: () => _changeShop(shop),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
