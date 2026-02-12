import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'package:manisha_butchery/widgets/bottom_modals.dart';
import '../../models/shop.dart';
import '../../models/expense.dart';

class ExpensesPage extends StatefulWidget {
  final Shop selectedShop;

  const ExpensesPage({super.key, required this.selectedShop});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await SharedPrefsService.getExpenses(
      shopId: widget.selectedShop.id,
    );
    final categories = await SharedPrefsService.getExpenseCategories();

    setState(() {
      _expenses = expenses;
      _categories = categories;
    });
  }

  void _addExpense() {
    if (_categories.isEmpty) {
      showErrorToast('Please create expense categories first');
      return;
    }

    showAddExpenseModal(
      context,
      categories: _categories,
      onSave: (description, amount, categoryId, date) async {
        final category = _categories.firstWhere((c) => c.id == categoryId);

        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: widget.selectedShop.id,
          categoryId: categoryId,
          categoryName: category.name,
          description: description,
          amount: amount,
          date: date,
        );

        await SharedPrefsService.saveExpense(expense);
        showSuccessToast('Expense added successfully');
        _loadData();
      },
    );
  }

  void _editExpense(Expense expense) {
    showEditExpenseModal(
      context,
      expense: expense,
      categories: _categories,
      onSave: (description, amount, categoryId, date) async {
        final category = _categories.firstWhere((c) => c.id == categoryId);

        expense.description = description;
        expense.amount = amount;
        expense.categoryId = categoryId;
        expense.categoryName = category.name;
        expense.date = date;

        // Update in storage
        final expenses = await SharedPrefsService.getExpenses();
        final index = expenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          expenses[index] = expense;
          await SharedPrefsService.saveList(
            'expenses',
            expenses.map((e) => e.toJson()).toList(),
          );
        }

        showSuccessToast('Expense updated successfully');
        _loadData();
      },
    );
  }

  void _deleteExpense(Expense expense) {
    showDeleteConfirmationModal(
      context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete this expense?',
      onConfirm: () async {
        final expenses = await SharedPrefsService.getExpenses();
        expenses.removeWhere((e) => e.id == expense.id);
        await SharedPrefsService.saveList(
          'expenses',
          expenses.map((e) => e.toJson()).toList(),
        );

        showSuccessToast('Expense deleted');
        _loadData();
      },
    );
  }

  List<Expense> _getFilteredExpenses() {
    List<Expense> filtered = _expenses;

    if (_selectedDate != null) {
      filtered = filtered
          .where(
            (e) =>
                e.date.year == _selectedDate!.year &&
                e.date.month == _selectedDate!.month &&
                e.date.day == _selectedDate!.day,
          )
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.description.toLowerCase().contains(search) ||
                e.categoryName.toLowerCase().contains(search),
          )
          .toList();
    }

    return filtered..sort((a, b) => b.date.compareTo(a.date));
  }

  double _getTotalExpenses() {
    return _getFilteredExpenses().fold(
      0,
      (sum, expense) => sum + expense.amount,
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
      _selectedDate = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();
    final totalExpenses = _getTotalExpenses();

    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses - ${widget.selectedShop.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addExpense),
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
                          labelText: 'Search expenses',
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
                      onPressed: _selectDate,
                      tooltip: 'Filter by date',
                    ),
                  ],
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtering by: ${_selectedDate!.toString().split(' ')[0]}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: _clearFilters,
                          tooltip: 'Clear filters',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Expenses:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'USD ${totalExpenses.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.money_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No expenses found',
                          style: TextStyle(fontSize: 16),
                        ),
                        if (_selectedDate != null ||
                            _searchController.text.isNotEmpty)
                          ElevatedButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.money_off,
                            color: Colors.red[700],
                          ),
                          title: Text(
                            expense.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${expense.categoryName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Amount: USD ${expense.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Date: ${expense.date.toString().split(' ')[0]}',
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
                                onPressed: () => _editExpense(expense),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteExpense(expense),
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
