import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/product.dart';

class ProductsPage extends StatefulWidget {
  final Shop selectedShop;

  const ProductsPage({super.key, required this.selectedShop});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  int _debugCounter = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('ProductsPage initState for shop: ${widget.selectedShop.id}');

    // Load products after a short delay
    Future.microtask(() {
      if (mounted && !_isDisposed) {
        _loadProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    _debugCounter++;
    debugPrint('_loadProducts called (attempt $_debugCounter)');
    debugPrint('Shop ID: ${widget.selectedShop.id}');
    debugPrint(
        'Mounted: $mounted, Disposed: $_isDisposed, Loading: $_isLoading');

    // Don't load if already loading or disposed
    if (_isLoading || _isDisposed || !mounted) {
      debugPrint('Skipping load - Conditions not met');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Calling SharedPrefsService.getProducts...');
      final products = await SharedPrefsService.getProducts(
        shopId: widget.selectedShop.id,
      );

      debugPrint('Received ${products.length} products');
      for (var product in products) {
        debugPrint(
            'Product: ${product.name}, Price: ${product.currentPrice}, Cost: ${product.currentCost}');
      }

      // Check again if widget is still mounted
      if (!mounted || _isDisposed) {
        debugPrint('Widget disposed during async operation');
        return;
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });

      debugPrint('Products loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Error loading products: $e');
      debugPrint('Stack trace: $stackTrace');

      // Don't show error if widget is disposed
      if (!mounted || _isDisposed) {
        debugPrint('Widget disposed, not showing error');
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading products: ${e.toString()}';
      });

      // Show toast only for user-facing errors
      if (e.toString().contains('Exception')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            showErrorToast('Failed to load products');
          }
        });
      }
    }
  }

  void _addProduct() {
    debugPrint('_addProduct called');

    // Check if context is still valid
    if (!mounted || _isDisposed) {
      debugPrint('Cannot show modal - widget not mounted');
      return;
    }

    try {
      showAddProductModal(
        context,
        onSave: (productName) async {
          debugPrint('Saving product: $productName');

          try {
            final product = Product(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              shopId: widget.selectedShop.id,
              name: productName.trim(),
              currentPrice: 0.0,
              currentCost: 0.0,
              createdAt: DateTime.now(),
            );

            debugPrint('Product created: ${product.toJson()}');

            await SharedPrefsService.saveProduct(product);

            // Check if widget is still mounted before updating UI
            if (!mounted || _isDisposed) {
              debugPrint('Widget disposed after saving');
              return;
            }

            showSuccessToast('Product added successfully');
            await _loadProducts(); // Reload with safe checks
          } catch (e, stackTrace) {
            debugPrint('Error adding product: $e');
            debugPrint('Stack trace: $stackTrace');

            if (!mounted || _isDisposed) return;
            showErrorToast('Error adding product: ${e.toString()}');
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing add modal: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted && !_isDisposed) {
        showErrorToast('Cannot open add product form');
      }
    }
  }

  void _editProduct(Product product) {
    debugPrint('_editProduct called for: ${product.name}');

    if (!mounted || _isDisposed) {
      debugPrint('Cannot show modal - widget not mounted');
      return;
    }

    try {
      showEditProductModal(
        context,
        product: product,
        onSave: (newName) async {
          debugPrint('Updating product ${product.id} to name: $newName');

          try {
            // Create updated product with all fields
            final updatedProduct = Product(
              id: product.id,
              shopId: product.shopId,
              name: newName.trim(),
              currentPrice: product.currentPrice,
              currentCost: product.currentCost,
              createdAt: product.createdAt,
            );

            debugPrint('Updated product: ${updatedProduct.toJson()}');

            await SharedPrefsService.updateProduct(updatedProduct);

            if (!mounted || _isDisposed) {
              debugPrint('Widget disposed after updating');
              return;
            }

            showSuccessToast('Product updated successfully');
            await _loadProducts();
          } catch (e, stackTrace) {
            debugPrint('Error updating product: $e');
            debugPrint('Stack trace: $stackTrace');

            if (!mounted || _isDisposed) return;
            showErrorToast('Error updating product: ${e.toString()}');
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing edit modal: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted && !_isDisposed) {
        showErrorToast('Cannot open edit form');
      }
    }
  }

  void _deleteProduct(Product product) {
    debugPrint('_deleteProduct called for: ${product.name}');

    if (!mounted || _isDisposed) {
      debugPrint('Cannot show modal - widget not mounted');
      return;
    }

    try {
      showDeleteConfirmationModal(
        context,
        title: 'Delete Product',
        message: 'Are you sure you want to delete "${product.name}"?',
        onConfirm: () async {
          debugPrint('Deleting product: ${product.id}');

          try {
            await SharedPrefsService.deleteProduct(product.id);

            if (!mounted || _isDisposed) {
              debugPrint('Widget disposed after deleting');
              return;
            }

            showSuccessToast('Product deleted successfully');
            await _loadProducts();
          } catch (e, stackTrace) {
            debugPrint('Error deleting product: $e');
            debugPrint('Stack trace: $stackTrace');

            if (!mounted || _isDisposed) return;
            showErrorToast('Error deleting product: ${e.toString()}');
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing delete modal: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted && !_isDisposed) {
        showErrorToast('Cannot open delete confirmation');
      }
    }
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
    debugPrint('ProductsPage build called, product count: ${_products.length}');

    final filteredProducts = _getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: Text('Products - ${widget.selectedShop.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('Manual refresh triggered');
              if (mounted && !_isDisposed) {
                _loadProducts();
              }
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              debugPrint('Add button pressed');
              if (mounted && !_isDisposed) {
                _addProduct();
              }
            },
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                // Safe setState
                if (mounted && !_isDisposed) {
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                labelText: 'Search Products',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          if (mounted && !_isDisposed) {
                            setState(() {});
                          }
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        if (mounted && !_isDisposed) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _products.isEmpty
                                  ? 'No products yet'
                                  : 'No matching products found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_products.isEmpty)
                              ElevatedButton(
                                onPressed: _addProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                ),
                                child: const Text('Add Your First Product'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          // Double-check product data
                          if (product.name.isEmpty) {
                            debugPrint(
                                'Warning: Product at index $index has empty name');
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1E3A8A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart,
                                  color: Color(0xFF1E3A8A),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                product.name.isNotEmpty
                                    ? product.name
                                    : 'Unnamed Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: USD ${product.currentPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Cost: USD ${product.currentCost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Created: ${product.createdAt.toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      if (mounted && !_isDisposed) {
                                        _editProduct(product);
                                      }
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      if (mounted && !_isDisposed) {
                                        _deleteProduct(product);
                                      }
                                    },
                                    tooltip: 'Delete',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('ProductsPage dispose called');
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }
}
