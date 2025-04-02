import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/expense_repository.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseRepository? _expenseRepository;
  bool _isLoading = false;
  String? _errorMessage;
  List<ExpenseModel>? _expenses;

  // Lazy initialize the repository
  ExpenseRepository get expenseRepository {
    _expenseRepository ??= ExpenseRepository();
    return _expenseRepository!;
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ExpenseModel> get expenses => _expenses ?? [];

  // Load expenses for a user
  Future<void> loadExpenses(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get expenses from repository
      final snapshot = await expenseRepository.getExpensesStream(userId).first;
      _expenses = snapshot;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load expenses by date range
  Future<void> loadExpensesByDateRange(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get expenses by date range from repository
      final snapshot = await expenseRepository
          .getExpensesByDateRangeStream(userId, startDate, endDate)
          .first;
      _expenses = snapshot;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load expenses by category and date range
  Future<void> loadExpensesByCategory(
    String userId, {
    required String category,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get expenses by category from repository
      final snapshot = await expenseRepository
          .getExpensesByCategoryStream(userId, category, startDate, endDate)
          .first;
      _expenses = snapshot;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get total expenses in a date range
  Future<double> getTotalExpenses(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await expenseRepository.getTotalExpenses(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 0.0;
    }
  }

  // Get expenses by category totals
  Future<Map<String, double>> getExpensesByCategory(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await expenseRepository.getExpensesByCategory(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Search expenses
  Future<List<ExpenseModel>> searchExpenses(
    String userId,
    String query,
  ) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      return await expenseRepository.searchExpenses(userId, query);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Add expense
  Future<bool> addExpense(
    ExpenseModel expense, {
    File? receiptImage,
    Uint8List? webReceiptImage,
    XFile? pickedFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await expenseRepository.addExpense(
        expense,
        receiptImage: receiptImage,
        webReceiptImage: webReceiptImage,
        pickedFile: pickedFile,
      );
      await loadExpenses(expense.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update expense
  Future<bool> updateExpense(
    ExpenseModel expense, {
    File? receiptImage,
    Uint8List? webReceiptImage,
    XFile? pickedFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await expenseRepository.updateExpense(
        expense,
        receiptImage: receiptImage,
        webReceiptImage: webReceiptImage,
        pickedFile: pickedFile,
      );
      await loadExpenses(expense.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(
    String userId,
    String expenseId,
    String? receiptUrl,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await expenseRepository.deleteExpense(expenseId, receiptUrl);
      await loadExpenses(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
