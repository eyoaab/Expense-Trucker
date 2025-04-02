import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_error_widgets.dart' as custom_widgets;
import '../../auth/providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'Monthly';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];
  Map<String, double> _categoryExpenses = {};
  List<ExpenseModel> _expenses = [];
  double _totalExpenses = 0;

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
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      final userId = authProvider.currentUser?.uid;
      if (userId == null) return;

      // Load categories if not already loaded
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories(userId);
      }

      // Set date range based on selected period
      DateTime startDate;
      DateTime endDate = DateTime.now();

      if (_selectedPeriod == 'Weekly') {
        // Get start of current week
        startDate = DateTime.now().subtract(
          Duration(days: DateTime.now().weekday - 1),
        );
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
      } else if (_selectedPeriod == 'Monthly') {
        // Get start of current month
        startDate = DateTime(_selectedYear, _selectedMonth, 1);
        endDate = DateTime(
            _selectedYear, _selectedMonth + 1, 0); // Last day of selected month
      } else {
        // Get start of current year
        startDate = DateTime(_selectedYear, 1, 1);
        endDate = DateTime(_selectedYear, 12, 31);
      }

      // Load expenses for the selected period
      await expenseProvider.loadExpensesByDateRange(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Get expenses and calculate by category
      _expenses = expenseProvider.expenses;
      _categoryExpenses = {};
      _totalExpenses = 0;

      for (final expense in _expenses) {
        _totalExpenses += expense.amount;

        if (_categoryExpenses.containsKey(expense.category)) {
          _categoryExpenses[expense.category] =
              _categoryExpenses[expense.category]! + expense.amount;
        } else {
          _categoryExpenses[expense.category] = expense.amount;
        }
      }
    } catch (e) {
      debugPrint('Error loading statistics data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(String? newPeriod) {
    if (newPeriod != null && newPeriod != _selectedPeriod) {
      setState(() {
        _selectedPeriod = newPeriod;
      });
      _loadData();
    }
  }

  void _changeMonth(int month) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? custom_widgets.EmptyStateWidget(
                  message: 'No expenses found for the selected period',
                  icon: Icons.bar_chart,
                )
              : _buildStatisticsContent(),
    );
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Period',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPeriod,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(),
                          ),
                          items: _periods.map((period) {
                            return DropdownMenuItem<String>(
                              value: period,
                              child: Text(period),
                            );
                          }).toList(),
                          onChanged: _changePeriod,
                        ),
                      ),
                      if (_selectedPeriod == 'Monthly') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(DateFormat('MMMM').format(
                                  DateTime(2022, index + 1),
                                )),
                              );
                            }),
                            onChanged: (value) =>
                                value != null ? _changeMonth(value) : null,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(5, (index) {
                            final year = DateTime.now().year - 2 + index;
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) =>
                              value != null ? _changeYear(value) : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Expense summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_totalExpenses.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of transactions: ${_expenses.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pie chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses by Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: _buildPieChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._buildCategoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _getCategorySections(categoryProvider),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: _getLegendItems(categoryProvider),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getCategorySections(
      CategoryProvider categoryProvider) {
    final List<PieChartSectionData> sections = [];

    _categoryExpenses.forEach((categoryName, amount) {
      final percentage = (amount / _totalExpenses) * 100;
      final category = categoryProvider.categories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => CategoryModel(
          id: 'unknown',
          name: categoryName,
          color: Colors.grey,
          icon: Icons.help_outline,
          isDefault: false,
          userId: '',
        ),
      );

      sections.add(
        PieChartSectionData(
          color: category.color,
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return sections;
  }

  List<Widget> _getLegendItems(CategoryProvider categoryProvider) {
    final List<Widget> items = [];

    _categoryExpenses.forEach((categoryName, amount) {
      final category = categoryProvider.categories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => CategoryModel(
          id: 'unknown',
          name: categoryName,
          color: Colors.grey,
          icon: Icons.help_outline,
          isDefault: false,
          userId: '',
        ),
      );

      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(categoryName, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    });

    return items;
  }

  List<Widget> _buildCategoryList() {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final List<Widget> items = [];

    // Sort categories by expense amount (descending)
    final sortedCategories = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final categoryName = entry.key;
      final amount = entry.value;
      final percentage = (amount / _totalExpenses) * 100;

      final category = categoryProvider.categories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => CategoryModel(
          id: 'unknown',
          name: categoryName,
          color: Colors.grey,
          icon: Icons.help_outline,
          isDefault: false,
          userId: '',
        ),
      );

      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: category.color.withOpacity(0.2),
                radius: 16,
                child: Icon(
                  category.icon,
                  size: 16,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }
}
