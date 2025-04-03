import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_error_widgets.dart' as custom_widgets;
import '../../auth/providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import 'add_expense_screen.dart';
import 'statistics_screen.dart';
import 'budgets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<Widget> _screens = const [
    _ExpensesTab(),
    StatisticsScreen(),
    BudgetsScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Expenses',
    'Statistics',
    'Budgets',
    'Profile',
  ];

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
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);

      final userId = authProvider.currentUser?.uid;
      if (userId == null) return;

      // Load user data if not already loaded
      if (authProvider.userData == null) {
        final authRepository = authProvider.authRepository;
        final userData = await authRepository.getUserData(userId);
      }

      // Load categories if not already loaded
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories(userId);
      }

      // Load expenses for the current date range
      await expenseProvider.loadExpensesByDateRange(
        userId,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Load budgets for the current month
      await budgetProvider.loadBudgetsByMonth(
        userId,
        DateTime.now().month,
        DateTime.now().year,
      );
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDateRange,
              tooltip: 'Select Date Range',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFF9AA33),
              onPressed: _addExpense,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        final expenseProvider =
            Provider.of<ExpenseProvider>(context, listen: false);
        await expenseProvider.loadExpensesByDateRange(
          userId,
          startDate: _startDate,
          endDate: _endDate,
        );
      }
    }
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );

    if (result == true) {
      // Reload expenses if a new expense was added
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        final expenseProvider =
            Provider.of<ExpenseProvider>(context, listen: false);
        await expenseProvider.loadExpensesByDateRange(
          userId,
          startDate: _startDate,
          endDate: _endDate,
        );
      }
    }
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (expenseProvider.expenses.isEmpty) {
      return custom_widgets.EmptyStateWidget(
        message: 'No expenses found for the selected date range',
        actionLabel: 'Add Expense',
        onAction: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );

          if (result == true) {
            // Reload expenses if a new expense was added
            final userId = authProvider.currentUser?.uid;
            if (userId != null) {
              await expenseProvider.loadExpensesByDateRange(
                userId,
                startDate: DateTime.now().subtract(const Duration(days: 30)),
                endDate: DateTime.now(),
              );
            }
          }
        },
        icon: Icons.attach_money,
      );
    }

    // Group expenses by date
    final groupedExpenses = <DateTime, List<ExpenseModel>>{};
    for (final expense in expenseProvider.expenses) {
      final dateOnly =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (groupedExpenses.containsKey(dateOnly)) {
        groupedExpenses[dateOnly]!.add(expense);
      } else {
        groupedExpenses[dateOnly] = [expense];
      }
    }

    // Sort dates in descending order
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final expenses = groupedExpenses[date]!;

        // Calculate total for this day
        final dailyTotal =
            expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMMMd().format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${authProvider.userData?.preferredCurrency ?? '\$'}${dailyTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...expenses.map((expense) {
              final category =
                  categoryProvider.findCategoryByName(expense.category);
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color.withOpacity(0.2),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 20,
                    ),
                  ),
                  title: Text(expense.title),
                  subtitle: Text(expense.category),
                  trailing: Text(
                    '${authProvider.userData?.preferredCurrency ?? '\$'}${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: expense.amount > 0
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () {
                    // View expense details or edit
                    // This will be implemented in a future PR
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
