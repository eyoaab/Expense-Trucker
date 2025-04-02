import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_error_widgets.dart' as custom_widgets;
import '../../auth/providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import 'add_edit_budget_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool _isLoading = true;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  int _selectedYear = DateTime.now().year;
  Map<String, double> _spending = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      final userId = authProvider.currentUser?.uid;
      if (userId == null) return;

      // Load categories if not already loaded
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories(userId);
      }

      // Load budgets for the current month
      final monthIndex = DateFormat('MMMM').parse(_selectedMonth).month;
      await budgetProvider.loadBudgetsByMonth(
          userId, monthIndex, _selectedYear);

      // Load spending data for each category
      final currentMonth = monthIndex;
      final currentYear = _selectedYear;
      _spending = await budgetProvider.getCategorySpending(
        userId,
        DateTime(currentYear, currentMonth, 1),
        DateTime(currentYear, currentMonth + 1, 0), // Last day of the month
      );
    } catch (e) {
      debugPrint('Error loading budget data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(String month) {
    if (month != _selectedMonth) {
      setState(() {
        _selectedMonth = month;
      });
      _loadData();
    }
  }

  void _changeYear(int year) {
    if (year != _selectedYear) {
      setState(() {
        _selectedYear = year;
      });
      _loadData();
    }
  }

  Future<void> _addBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditBudgetScreen(
          budget: null,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editBudget(BudgetModel budget) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBudgetScreen(
          budget: budget,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete the budget for ${budget.category}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        final budgetProvider =
            Provider.of<BudgetProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser!.uid;

        await budgetProvider.deleteBudget(budget.id, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting budget: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Reload data after deletion
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(budgetProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudget,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BudgetProvider budgetProvider) {
    return Column(
      children: [
        _buildMonthSelector(),
        Expanded(
          child: budgetProvider.budgets.isEmpty
              ? custom_widgets.EmptyStateWidget(
                  message: 'No budgets found for this month',
                  actionLabel: 'Add Budget',
                  onAction: _addBudget,
                  icon: Icons.account_balance_wallet,
                )
              : _buildBudgetList(budgetProvider),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final months = List.generate(12, (index) {
      return DateFormat('MMMM').format(DateTime(2022, index + 1));
    });

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: months.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (value) =>
                    value != null ? _changeMonth(value) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) => value != null ? _changeYear(value) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(BudgetProvider budgetProvider) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: budgetProvider.budgets.length,
      itemBuilder: (context, index) {
        final budget = budgetProvider.budgets[index];
        final category = categoryProvider.categories.firstWhere(
          (c) => c.name == budget.category,
          orElse: () => CategoryModel(
            id: 'unknown',
            name: budget.category,
            color: Colors.grey,
            icon: Icons.help_outline,
            isDefault: false,
            userId: '',
          ),
        );

        // Calculate spending percentage
        final spent = _spending[budget.category] ?? 0.0;
        final percentage =
            budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
        final isOverBudget = percentage > 100;

        Color progressColor;
        if (percentage >= 90) {
          progressColor = Colors.red;
        } else if (percentage >= 75) {
          progressColor = Colors.orange;
        } else {
          progressColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.2),
                      radius: 24,
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Budget: \$${budget.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editBudget(budget);
                        } else if (value == 'delete') {
                          _deleteBudget(budget);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: percentage / 100 > 1 ? 1 : percentage / 100,
                  color: progressColor,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: \$${spent.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      isOverBudget
                          ? '${percentage.toStringAsFixed(0)}% (Over Budget)'
                          : '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                if (isOverBudget) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Over by: \$${(spent - budget.amount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
