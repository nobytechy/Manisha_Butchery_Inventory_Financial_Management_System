import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/expense.dart';

class ExpenseCategoriesPage extends StatefulWidget {
  final Shop selectedShop;

  const ExpenseCategoriesPage({super.key, required this.selectedShop});

  @override
  State<ExpenseCategoriesPage> createState() => _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends State<ExpenseCategoriesPage> {
  List<ExpenseCategory> _categories = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await SharedPrefsService.getExpenseCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _addCategory() {
    showAddExpenseCategoryModal(
      context,
      onSave: (categoryName) async {
        final category = ExpenseCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: categoryName,
          createdAt: DateTime.now(),
        );

        await SharedPrefsService.saveExpenseCategory(category);
        showSuccessToast('Category added successfully');
        _loadCategories();
      },
    );
  }

  void _editCategory(ExpenseCategory category) {
    showEditExpenseCategoryModal(
      context,
      category: category,
      onSave: (newName) async {
        category.name = newName;
        // Note: Since we can't update individual items in the list easily,
        // we'll replace the entire list
        final categories = await SharedPrefsService.getExpenseCategories();
        final index = categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          categories[index] = category;
          await SharedPrefsService.saveList(
            'expense_categories',
            categories.map((c) => c.toJson()).toList(),
          );
        }

        showSuccessToast('Category updated successfully');
        _loadCategories();
      },
    );
  }

  void _deleteCategory(ExpenseCategory category) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete ${category.name}?',
      onConfirm: () async {
        final categories = await SharedPrefsService.getExpenseCategories();
        categories.removeWhere((c) => c.id == category.id);
        await SharedPrefsService.saveList(
          'expense_categories',
          categories.map((c) => c.toJson()).toList(),
        );

        showSuccessToast('Category deleted');
        _loadCategories();
      },
    );
  }

  List<ExpenseCategory> _getFilteredCategories() {
    if (_searchController.text.isEmpty) {
      return _categories;
    }
    return _categories
        .where(
          (category) => category.name.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Categories - ${widget.selectedShop.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addCategory),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search Categories',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.category,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No expense categories found',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (_searchController.text.isNotEmpty)
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Text('Clear Search'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.category,
                            color: Color(0xFF1E3A8A),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Created: ${category.createdAt.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCategory(category),
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
