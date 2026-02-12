import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manisha_butchery/models/closing.dart';
import 'package:manisha_butchery/models/expense.dart';
import 'package:manisha_butchery/models/price.dart';
import 'package:manisha_butchery/models/purchase.dart';
import 'package:manisha_butchery/models/transfer.dart';
import '../models/shop.dart';
import '../models/product.dart';

void showSuccessToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.green,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void showErrorToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void showChangePinModal(
  BuildContext context, {
  required void Function(String) onPinChanged,
}) {
  // Check if context is still mounted
  if (!context.mounted) return;

  final List<TextEditingController> controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          String getEnteredPin() {
            String pin = '';
            for (var controller in controllers) {
              pin += controller.text;
            }
            return pin;
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Change PIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Enter new 4-digit PIN',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF1E3A8A),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: TextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              FocusScope.of(context)
                                  .requestFocus(focusNodes[index + 1]);
                            } else if (value.isEmpty && index > 0) {
                              FocusScope.of(context)
                                  .requestFocus(focusNodes[index - 1]);
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: getEnteredPin().length == 4
                        ? () {
                            onPinChanged(getEnteredPin());
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('SAVE NEW PIN'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
              ],
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        for (var controller in controllers) {
          controller.dispose();
        }
        for (var node in focusNodes) {
          node.dispose();
        }
      });
    }
  });
}

void showAddProductModal(
  BuildContext context, {
  required void Function(String) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController controller = TextEditingController();
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add New Product',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_cart),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      } else {
                        showErrorToast('Please enter product name');
                      }
                    },
                    child: const Text('SAVE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.dispose();
      });
    }
  });
}

void showEditProductModal(
  BuildContext context, {
  required Product product,
  required void Function(String) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController controller = TextEditingController(
    text: product.name,
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Product',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_cart),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      } else {
                        showErrorToast('Please enter product name');
                      }
                    },
                    child: const Text('UPDATE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.dispose();
      });
    }
  });
}

void showEditShopModal(
  BuildContext context, {
  required Shop shop,
  required void Function(String) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController controller = TextEditingController(
    text: shop.name,
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Shop',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      } else {
                        showErrorToast('Please enter shop name');
                      }
                    },
                    child: const Text('UPDATE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.dispose();
      });
    }
  });
}

void showDeleteConfirmationModal(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  if (!context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.warning, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('DELETE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

void showAddPurchaseModal(
  BuildContext context, {
  required List<Product> products,
  required void Function(String, double, double, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      Product? selectedProduct;
      DateTime selectedDate = DateTime.now();

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Purchase',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    value: selectedProduct,
                    items: products.map((product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (Product? product) {
                      setState(() {
                        selectedProduct = product;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost per kg',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Purchase Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedProduct == null) {
                              showErrorToast('Please select a product');
                              return;
                            }
                            if (quantityController.text.isEmpty) {
                              showErrorToast('Please enter quantity');
                              return;
                            }
                            if (costController.text.isEmpty) {
                              showErrorToast('Please enter cost');
                              return;
                            }

                            final quantity = double.tryParse(
                              quantityController.text,
                            );
                            final cost = double.tryParse(costController.text);

                            if (quantity == null || quantity <= 0) {
                              showErrorToast('Please enter valid quantity');
                              return;
                            }
                            if (cost == null || cost <= 0) {
                              showErrorToast('Please enter valid cost');
                              return;
                            }

                            onSave(
                              selectedProduct!.id,
                              quantity,
                              cost,
                              selectedDate,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('SAVE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        quantityController.dispose();
        costController.dispose();
      });
    }
  });
}

void showEditPurchaseModal(
  BuildContext context, {
  required Purchase purchase,
  required void Function(double, double, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController quantityController = TextEditingController(
    text: purchase.quantity.toString(),
  );
  final TextEditingController costController = TextEditingController(
    text: purchase.cost.toString(),
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      DateTime selectedDate = purchase.date;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Purchase',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(
                      purchase.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost per kg',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Purchase Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (quantityController.text.isEmpty) {
                              showErrorToast('Please enter quantity');
                              return;
                            }
                            if (costController.text.isEmpty) {
                              showErrorToast('Please enter cost');
                              return;
                            }

                            final quantity = double.tryParse(
                              quantityController.text,
                            );
                            final cost = double.tryParse(costController.text);

                            if (quantity == null || quantity <= 0) {
                              showErrorToast('Please enter valid quantity');
                              return;
                            }
                            if (cost == null || cost <= 0) {
                              showErrorToast('Please enter valid cost');
                              return;
                            }

                            onSave(quantity, cost, selectedDate);
                            Navigator.pop(context);
                          },
                          child: const Text('UPDATE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        quantityController.dispose();
        costController.dispose();
      });
    }
  });
}

void showChangePriceModal(
  BuildContext context, {
  required Product product,
  required List<PriceHistory> priceHistory,
  required void Function(double) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController priceController = TextEditingController(
    text: product.currentPrice.toString(),
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Price',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Current Price: USD ${product.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Price',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'USD/kg',
                ),
              ),
              const SizedBox(height: 20),
              if (priceHistory.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Price History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: priceHistory.length,
                    itemBuilder: (context, index) {
                      final history = priceHistory[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            history.newPrice > history.oldPrice
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: history.newPrice > history.oldPrice
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(
                            'USD ${history.oldPrice.toStringAsFixed(2)} → USD ${history.newPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Changed: ${history.changedAt.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            history.newPrice > history.oldPrice
                                ? '+${(history.newPrice - history.oldPrice).toStringAsFixed(2)}'
                                : (history.newPrice - history.oldPrice)
                                    .toStringAsFixed(2),
                            style: TextStyle(
                              color: history.newPrice > history.oldPrice
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (priceController.text.isEmpty) {
                          showErrorToast('Please enter new price');
                          return;
                        }

                        final newPrice = double.tryParse(priceController.text);

                        if (newPrice == null || newPrice <= 0) {
                          showErrorToast('Please enter valid price');
                          return;
                        }

                        if (newPrice == product.currentPrice) {
                          showErrorToast('New price is same as current price');
                          return;
                        }

                        onSave(newPrice);
                        Navigator.pop(context);
                      },
                      child: const Text('UPDATE PRICE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        priceController.dispose();
      });
    }
  });
}

void showAddShopTransferModal(
  BuildContext context, {
  required Shop currentShop,
  required List<Shop> shops,
  required List<Product> products,
  required void Function(String, String, String, double, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController quantityController = TextEditingController();
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      Product? selectedProduct;
      Shop? fromShop;
      Shop? toShop;
      DateTime selectedDate = DateTime.now();

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Shop Transfer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    value: selectedProduct,
                    items: products.map((product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (Product? product) {
                      setState(() {
                        selectedProduct = product;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Shop>(
                    decoration: const InputDecoration(
                      labelText: 'From Shop',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.upload),
                    ),
                    value: fromShop,
                    items: shops.map((shop) {
                      // REMOVED FILTER: Show ALL shops
                      return DropdownMenuItem<Shop>(
                        value: shop,
                        child: Text(
                          '${shop.name}${shop.isWarehouse ? ' (Warehouse)' : ''}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Shop? shop) {
                      setState(() {
                        fromShop = shop;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Shop>(
                    decoration: const InputDecoration(
                      labelText: 'To Shop',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.download),
                    ),
                    value: toShop,
                    items: shops.map((shop) {
                      // REMOVED FILTER: Show ALL shops
                      return DropdownMenuItem<Shop>(
                        value: shop,
                        child: Text(
                          '${shop.name}${shop.isWarehouse ? ' (Warehouse)' : ''}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Shop? shop) {
                      setState(() {
                        toShop = shop;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Transfer Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedProduct == null) {
                              showErrorToast('Please select a product');
                              return;
                            }
                            if (fromShop == null) {
                              showErrorToast('Please select source shop');
                              return;
                            }
                            if (toShop == null) {
                              showErrorToast('Please select destination shop');
                              return;
                            }
                            if (fromShop?.id == toShop?.id) {
                              showErrorToast(
                                'Source and destination cannot be same',
                              );
                              return;
                            }
                            if (quantityController.text.isEmpty) {
                              showErrorToast('Please enter quantity');
                              return;
                            }

                            final quantity = double.tryParse(
                              quantityController.text,
                            );

                            if (quantity == null || quantity <= 0) {
                              showErrorToast('Please enter valid quantity');
                              return;
                            }

                            onSave(
                              selectedProduct!.id,
                              fromShop!.id,
                              toShop!.id,
                              quantity,
                              selectedDate,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('SAVE TRANSFER'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        quantityController.dispose();
      });
    }
  });
}

void showEditShopTransferModal(
  BuildContext context, {
  required ShopTransfer transfer,
  required void Function(double, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController quantityController = TextEditingController(
    text: transfer.quantity.toString(),
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      DateTime selectedDate = transfer.date;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Shop Transfer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(
                      transfer.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload),
                    title: Text('From: ${transfer.fromShopName}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: Text('To: ${transfer.toShopName}'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Transfer Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (quantityController.text.isEmpty) {
                              showErrorToast('Please enter quantity');
                              return;
                            }

                            final quantity = double.tryParse(
                              quantityController.text,
                            );

                            if (quantity == null || quantity <= 0) {
                              showErrorToast('Please enter valid quantity');
                              return;
                            }

                            onSave(quantity, selectedDate);
                            Navigator.pop(context);
                          },
                          child: const Text('UPDATE TRANSFER'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        quantityController.dispose();
      });
    }
  });
}

void showAddProductTransferModal(
  BuildContext context, {
  required List<Product> products,
  required void Function(String, String, double, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController quantityController = TextEditingController();
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      Product? fromProduct;
      Product? toProduct;
      DateTime selectedDate = DateTime.now();

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Product Transfer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'From Product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.arrow_upward),
                    ),
                    value: fromProduct,
                    items: products.map((product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (Product? product) {
                      setState(() {
                        fromProduct = product;
                        // Reset toProduct when fromProduct changes
                        if (toProduct?.id == fromProduct?.id) {
                          toProduct = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'To Product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.arrow_downward),
                    ),
                    value: toProduct,
                    items: products.where((p) => p.id != fromProduct?.id).map((
                      product,
                    ) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (Product? product) {
                      setState(() {
                        toProduct = product;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Transfer Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (fromProduct == null) {
                              showErrorToast('Please select source product');
                              return;
                            }
                            if (toProduct == null) {
                              showErrorToast(
                                'Please select destination product',
                              );
                              return;
                            }
                            if (fromProduct?.id == toProduct?.id) {
                              showErrorToast(
                                'Source and destination cannot be same',
                              );
                              return;
                            }
                            if (quantityController.text.isEmpty) {
                              showErrorToast('Please enter quantity');
                              return;
                            }

                            final quantity = double.tryParse(
                              quantityController.text,
                            );

                            if (quantity == null || quantity <= 0) {
                              showErrorToast('Please enter valid quantity');
                              return;
                            }

                            onSave(
                              fromProduct!.id,
                              toProduct!.id,
                              quantity,
                              selectedDate,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('SAVE TRANSFER'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        quantityController.dispose();
      });
    }
  });
}

void showEditProductTransferModal(
  BuildContext context, {
  required ProductTransfer transfer,
  required void Function(double, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController quantityController = TextEditingController(
    text: transfer.quantity.toString(),
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      DateTime selectedDate = transfer.date;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Product Transfer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: Text(
                      'From: ${transfer.fromProductName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_downward),
                    title: Text(
                      'To: ${transfer.toProductName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Transfer Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (quantityController.text.isEmpty) {
                              showErrorToast('Please enter quantity');
                              return;
                            }

                            final quantity = double.tryParse(
                              quantityController.text,
                            );

                            if (quantity == null || quantity <= 0) {
                              showErrorToast('Please enter valid quantity');
                              return;
                            }

                            onSave(quantity, selectedDate);
                            Navigator.pop(context);
                          },
                          child: const Text('UPDATE TRANSFER'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        quantityController.dispose();
      });
    }
  });
}

void showClosingDetailsModal(
  BuildContext context, {
  required ShopClosing closing,
  required List<Product> products,
  required String shopName,
}) {
  if (!context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      double totalValue = 0;

      // Calculate total value inside builder
      for (var productId in closing.productQuantities.keys) {
        final quantity = closing.productQuantities[productId]!;
        final product = products.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: '',
            shopId: '',
            name: 'Unknown Product',
            currentPrice: 0.0,
            createdAt: DateTime.now(),
          ),
        );
        totalValue += quantity * product.currentPrice;
      }

      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Closing Details - $shopName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Date: ${closing.date.toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Product Quantities',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: closing.productQuantities.length,
                itemBuilder: (context, index) {
                  final productId = closing.productQuantities.keys.elementAt(
                    index,
                  );
                  final quantity = closing.productQuantities[productId]!;
                  final product = products.firstWhere(
                    (p) => p.id == productId,
                    orElse: () => Product(
                      id: '',
                      shopId: '',
                      name: 'Unknown Product',
                      currentPrice: 0.0,
                      createdAt: DateTime.now(),
                    ),
                  );

                  final value = quantity * product.currentPrice;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.shopping_cart, size: 20),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Price: USD ${product.currentPrice.toStringAsFixed(2)}/kg',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${quantity.toStringAsFixed(2)} kg',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'USD ${value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Closing Value:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'USD ${totalValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CLOSE'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

void showAddExpenseCategoryModal(
  BuildContext context, {
  required void Function(String) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController controller = TextEditingController();
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Expense Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      } else {
                        showErrorToast('Please enter category name');
                      }
                    },
                    child: const Text('SAVE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.dispose();
      });
    }
  });
}

void showEditExpenseCategoryModal(
  BuildContext context, {
  required ExpenseCategory category,
  required void Function(String) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController controller = TextEditingController(
    text: category.name,
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Expense Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      } else {
                        showErrorToast('Please enter category name');
                      }
                    },
                    child: const Text('UPDATE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.dispose();
      });
    }
  });
}

void showAddExpenseModal(
  BuildContext context, {
  required List<ExpenseCategory> categories,
  required void Function(String, double, String, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      ExpenseCategory? selectedCategory;
      DateTime selectedDate = DateTime.now();

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descriptionController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem<ExpenseCategory>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (ExpenseCategory? category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
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
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (descriptionController.text.isEmpty) {
                              showErrorToast('Please enter description');
                              return;
                            }
                            if (amountController.text.isEmpty) {
                              showErrorToast('Please enter amount');
                              return;
                            }
                            if (selectedCategory == null) {
                              showErrorToast('Please select category');
                              return;
                            }

                            final amount = double.tryParse(
                              amountController.text,
                            );

                            if (amount == null || amount <= 0) {
                              showErrorToast('Please enter valid amount');
                              return;
                            }

                            onSave(
                              descriptionController.text.trim(),
                              amount,
                              selectedCategory!.id,
                              selectedDate,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('SAVE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        descriptionController.dispose();
        amountController.dispose();
      });
    }
  });
}

void showEditExpenseModal(
  BuildContext context, {
  required Expense expense,
  required List<ExpenseCategory> categories,
  required void Function(String, double, String, DateTime) onSave,
}) {
  if (!context.mounted) return;

  final TextEditingController descriptionController = TextEditingController(
    text: expense.description,
  );
  final TextEditingController amountController = TextEditingController(
    text: expense.amount.toString(),
  );
  bool _isDisposed = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      ExpenseCategory? selectedCategory = categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => categories.first,
      );
      DateTime selectedDate = expense.date;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descriptionController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem<ExpenseCategory>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (ExpenseCategory? category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
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
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (descriptionController.text.isEmpty) {
                              showErrorToast('Please enter description');
                              return;
                            }
                            if (amountController.text.isEmpty) {
                              showErrorToast('Please enter amount');
                              return;
                            }
                            if (selectedCategory == null) {
                              showErrorToast('Please select category');
                              return;
                            }

                            final amount = double.tryParse(
                              amountController.text,
                            );

                            if (amount == null || amount <= 0) {
                              showErrorToast('Please enter valid amount');
                              return;
                            }

                            onSave(
                              descriptionController.text.trim(),
                              amount,
                              selectedCategory!.id,
                              selectedDate,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('UPDATE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  ).then((_) {
    if (!_isDisposed) {
      _isDisposed = true;
      // Delay disposal to ensure animation is complete
      Future.delayed(const Duration(milliseconds: 300), () {
        descriptionController.dispose();
        amountController.dispose();
      });
    }
  });
}
