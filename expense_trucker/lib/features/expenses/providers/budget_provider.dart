import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import '../repositories/expense_repository.dart';

class BudgetProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetRepository _budgetRepository = BudgetRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all budgets for a user
  Future<void> loadBudgets(String userId) async {
    if (!Firebase.apps.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      _budgets =
          snapshot.docs.map((doc) => BudgetModel.fromFirestore(doc)).toList();

      // Don't await this call - run it after the UI is updated
      _updateBudgetSpending(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load budgets for a specific month and year
  Future<void> loadBudgetsByMonth(String userId, int month, int year) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      _budgets =
          snapshot.docs.map((doc) => BudgetModel.fromFirestore(doc)).toList();

      // Don't await this call - run it after the UI is updated
      _updateBudgetSpending(userId, month: month, year: year);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update budget spending amounts based on actual expenses
  Future<void> _updateBudgetSpending(String userId,
      {int? month, int? year}) async {
    try {
      // Skip if no budgets to update
      if (_budgets.isEmpty) return;

      List<BudgetModel> updatedBudgets = List.from(_budgets);
      bool hasChanges = false;

      // Get all expenses for this time period at once
      final currentMonth = month ?? _budgets.first.month;
      final currentYear = year ?? _budgets.first.year;

      // Calculate start and end dates for the month
      final startDate = DateTime(currentYear, currentMonth, 1);
      final endDate =
          DateTime(currentYear, currentMonth + 1, 0); // Last day of month

      // Get all expenses for this time period
      final expenses = await _expenseRepository
          .getExpensesByDateRangeStream(userId, startDate, endDate)
          .first;

      // Group expenses by category
      final Map<String, double> categoryTotals = {};
      for (final expense in expenses) {
        categoryTotals.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      // Update each budget with the corresponding category spending
      for (int i = 0; i < updatedBudgets.length; i++) {
        final budget = updatedBudgets[i];
        final totalSpent = categoryTotals[budget.category] ?? 0.0;

        // Only update if the spent amount has changed
        if (totalSpent != budget.spent) {
          final updatedBudget = budget.copyWith(spent: totalSpent);
          updatedBudgets[i] = updatedBudget;
          hasChanges = true;

          // Fire and forget Firestore update
          _firestore
              .collection('budgets')
              .doc(budget.id)
              .update({'spent': totalSpent}).catchError((e) {
            debugPrint('Error updating budget in Firestore: $e');
          });
        }
      }

      // Only update state if there are changes
      if (hasChanges) {
        _budgets = updatedBudgets;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating budget spending: $e');
    }
  }

  // Add a new budget or update an existing one
  Future<void> setBudget({
    required String userId,
    required String category,
    required double amount,
    required int month,
    required int year,
    required String currency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if a budget already exists for this category, month, and year
      final existingBudget = _budgets
          .where((b) =>
              b.userId == userId &&
              b.category == category &&
              b.month == month &&
              b.year == year)
          .firstOrNull;

      if (existingBudget != null) {
        // Update existing budget
        final updatedBudget = existingBudget.copyWith(
          amount: amount,
          currency: currency,
        );
        await _firestore
            .collection('budgets')
            .doc(existingBudget.id)
            .update(updatedBudget.toJson());
      } else {
        // Create a new budget
        final newBudget = BudgetModel.createNew(
          userId: userId,
          category: category,
          amount: amount,
          month: month,
          year: year,
          currency: currency,
        );
        await _firestore
            .collection('budgets')
            .doc(newBudget.id)
            .set(newBudget.toJson());
      }

      // Reload budgets to update the list
      await loadBudgetsByMonth(userId, month, year);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String budgetId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the budget to get its month and year for reloading
      final budget = _budgets.firstWhere((b) => b.id == budgetId);

      // Delete from Firestore
      await _firestore.collection('budgets').doc(budgetId).delete();

      // Reload budgets for the specific month and year
      await loadBudgetsByMonth(userId, budget.month, budget.year);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get total spending amount for each category in a date range
  Future<Map<String, double>> getCategorySpending(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Use a simpler approach to avoid index issues
      final expenses = await _expenseRepository
          .getExpensesByDateRangeStream(userId, startDate, endDate)
          .first;

      final Map<String, double> categoryTotals = {};
      for (final expense in expenses) {
        categoryTotals.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      return categoryTotals;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Calculate budget progress for a category
  double calculateBudgetProgress(
      String category, Map<String, double> spending) {
    final budget = _budgets.firstWhere(
      (b) => b.category == category,
      orElse: () => BudgetModel(
        id: '',
        userId: '',
        category: category,
        amount: 0,
        month: DateTime.now().month,
        year: DateTime.now().year,
        currency: 'USD',
        createdAt: DateTime.now(),
      ),
    );

    final spent = spending[category] ?? 0;
    if (budget.amount <= 0) return 0;

    return (spent / budget.amount).clamp(0.0, 1.0);
  }
}
