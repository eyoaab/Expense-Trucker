import 'package:flutter/material.dart';
import '../repositories/budget_repository.dart';
import '../models/budget_model.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _budgetRepository = BudgetRepository();
  bool _isLoading = false;
  String? _errorMessage;
  List<BudgetModel>? _budgets;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BudgetModel> get budgets => _budgets ?? [];

  // Load budgets for a user
  Future<void> loadBudgets(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _budgetRepository.getBudgetsStream(userId).first;
      _budgets = snapshot;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get budgets for specific month
  Future<List<BudgetModel>> getBudgetsByMonth(
    String userId,
    int year,
    int month,
  ) async {
    try {
      return await _budgetRepository.getBudgetsByMonth(userId, year, month);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get a specific budget
  Future<BudgetModel?> getBudget(
    String userId,
    String category,
    int year,
    int month,
  ) async {
    try {
      return await _budgetRepository.getBudget(userId, category, year, month);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get spending percentage against budget
  Future<double> getSpendingPercentage(
    String userId,
    String category,
    int year,
    int month,
    double spentAmount,
  ) async {
    try {
      return await _budgetRepository.getSpendingPercentage(
        userId,
        category,
        year,
        month,
        spentAmount,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 0.0;
    }
  }

  // Set budget
  Future<bool> setBudget(BudgetModel budget) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetRepository.setBudget(budget);
      await loadBudgets(budget.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete budget
  Future<bool> deleteBudget(String userId, String budgetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetRepository.deleteBudget(budgetId);
      await loadBudgets(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete all budgets
  Future<bool> deleteAllBudgets(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetRepository.deleteAllBudgets(userId);
      _budgets = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
