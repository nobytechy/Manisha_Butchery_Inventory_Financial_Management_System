import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/app_drawer.dart';
import '../models/shop.dart';
import 'shops/create_shop.dart';
import 'products/products_page.dart';
import 'purchases/purchases_page.dart';
import 'price/price_page.dart';
import 'transfers/shop_transfers.dart';
import 'transfers/product_transfers.dart';
import 'closing/record_closing.dart';
import 'closing/view_closings.dart';
import 'expenses/expense_categories.dart';
import 'expenses/expenses_page.dart';
import 'reports/stocks_report.dart';
import 'reports/financial_report.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Shop? _selectedShop;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedShop();
  }

  Future<void> _loadSelectedShop() async {
    final shop = await SharedPrefsService.getSelectedShop();
    setState(() {
      _selectedShop = shop;
      _loading = false;
    });
  }

  void _refreshShop() {
    _loadSelectedShop();
  }

  Widget _buildDashboardItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(0xFF1E3A8A)),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_selectedShop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Shop')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'No Shop Selected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please create or select a shop to continue',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateShopPage(),
                    ),
                  ).then((_) => _refreshShop());
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Create Shop'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              _selectedShop!.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshShop),
        ],
      ),
      drawer: AppDrawer(
        selectedShop: _selectedShop!,
        onShopChanged: _refreshShop,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardItem(Icons.shopping_cart, 'Products', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductsPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.inventory, 'Purchases', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PurchasesPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.attach_money, 'Price', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PricePage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(
              Icons.store_mall_directory,
              'Shop Transfers',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShopTransfersPage(selectedShop: _selectedShop!),
                  ),
                );
              },
            ),
            _buildDashboardItem(Icons.swap_horiz, 'Product Transfers', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductTransfersPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.close, 'Record Closing', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RecordClosingPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.list, 'View Closings', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewClosingsPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.category, 'Expense Categories', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ExpenseCategoriesPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.money_off, 'Expenses', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ExpensesPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.assessment, 'Stocks Report', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StocksReportPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.pie_chart, 'Financial Report', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FinancialReportPage(selectedShop: _selectedShop!),
                ),
              );
            }),
            _buildDashboardItem(Icons.business, 'Change Shop', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateShopPage()),
              ).then((_) => _refreshShop());
            }),
          ],
        ),
      ),
    );
  }
}
