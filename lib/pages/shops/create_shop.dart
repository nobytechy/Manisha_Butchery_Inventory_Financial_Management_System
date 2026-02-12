import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import 'change_shop.dart';

class CreateShopPage extends StatefulWidget {
  const CreateShopPage({super.key});

  @override
  State<CreateShopPage> createState() => _CreateShopPageState();
}

class _CreateShopPageState extends State<CreateShopPage> {
  final TextEditingController _shopNameController = TextEditingController();
  List<Shop> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final shops = await SharedPrefsService.getShops();
    setState(() {
      _shops = shops;
    });
  }

  void _createShop() async {
    final shopName = _shopNameController.text.trim();
    if (shopName.isEmpty) {
      showErrorToast('Please enter shop name');
      return;
    }

    final shop = Shop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: shopName,
      createdAt: DateTime.now(),
      isWarehouse: false,
    );

    await SharedPrefsService.saveShop(shop);
    await SharedPrefsService.setSelectedShopId(shop.id);

    showSuccessToast('Shop created successfully');
    _shopNameController.clear();
    _loadShops();
  }

  void _editShop(Shop shop) {
    showEditShopModal(
      context,
      shop: shop,
      onSave: (newName) async {
        shop.name = newName;
        await SharedPrefsService.updateShop(shop);
        showSuccessToast('Shop updated successfully');
        _loadShops();
      },
    );
  }

  void _deleteShop(Shop shop) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Shop',
      message: 'Are you sure you want to delete ${shop.name}?',
      onConfirm: () async {
        await SharedPrefsService.deleteShop(shop.id);
        showSuccessToast('Shop deleted successfully');
        _loadShops();
      },
    );
  }

  void _changeShop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeShopPage(shops: _shops, onShopChanged: _loadShops),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Shops')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _createShop,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Shop'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Shops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _changeShop,
                  child: const Text('Change Shop'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _shops.length,
                itemBuilder: (context, index) {
                  final shop = _shops[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editShop(shop),
                          ),
                          if (!shop.isWarehouse)
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteShop(shop),
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
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }
}
