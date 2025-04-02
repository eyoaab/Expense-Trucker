import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import 'expense_provider.dart';

class BudgetProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetRepository _budgetRepository = BudgetRepository();
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
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
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
      final expenseProvider = ExpenseProvider();
      await expenseProvider.loadExpensesByDateRange(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      final expenses = expenseProvider.expenses;
      final spending = <String, double>{};

      for (final expense in expenses) {
        spending.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      return spending;
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
