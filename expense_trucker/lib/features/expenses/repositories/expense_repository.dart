import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection(AppConstants.expensesCollection);

  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _firestore.collection(AppConstants.budgetsCollection);

  // Get all expenses for a user
  Stream<List<ExpenseModel>> getExpensesStream(String userId) {
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromJson(doc.data());
      }).toList();
    });
  }

  // Get all expenses for a user within a date range
  Stream<List<ExpenseModel>> getExpensesByDateRangeStream(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromJson(doc.data());
      }).toList();
    });
  }

  // Get expenses for a user by category within a date range
  Stream<List<ExpenseModel>> getExpensesByCategoryStream(
    String userId,
    String category,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('date', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseModel.fromJson(doc.data());
      }).toList();
    });
  }

  // Add a new expense
  Future<void> addExpense(
    ExpenseModel expense, {
    File? receiptImage,
    Uint8List? webReceiptImage,
    XFile? pickedFile,
  }) async {
    try {
      // If receipt image is provided, upload it to Firebase Storage
      String? receiptUrl;
      if (kIsWeb && webReceiptImage != null) {
        final fileName = pickedFile?.name ??
            'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        receiptUrl = await _uploadWebReceipt(
          expense.userId,
          expense.id,
          webReceiptImage,
          fileName,
        );
      } else if (receiptImage != null) {
        receiptUrl =
            await _uploadReceipt(expense.userId, expense.id, receiptImage);
      }

      // Create expense with updated receipt URL if available
      final expenseToAdd = receiptUrl != null
          ? expense.copyWith(receiptUrl: receiptUrl)
          : expense;

      // Start a batch write transaction
      final batch = _firestore.batch();

      // Add expense to Firestore
      batch.set(_expensesCollection.doc(expense.id), expenseToAdd.toJson());

      // Update corresponding budget if exists
      await _updateBudgetAfterExpenseChange(batch, expense, isAddition: true);

      // Commit the batch
      await batch.commit();
    } catch (e) {
      debugPrint('Error in addExpense: $e');
      rethrow;
    }
  }

  // Update an existing expense
  Future<void> updateExpense(
    ExpenseModel expense, {
    File? receiptImage,
    Uint8List? webReceiptImage,
    XFile? pickedFile,
  }) async {
    try {
      // Get original expense to calculate difference
      final originalDoc = await _expensesCollection.doc(expense.id).get();
      ExpenseModel? originalExpense;
      if (originalDoc.exists) {
        originalExpense = ExpenseModel.fromJson(originalDoc.data()!);
      }

      // If receipt image is provided, upload it to Firebase Storage
      String? receiptUrl;
      if (kIsWeb && webReceiptImage != null) {
        final fileName = pickedFile?.name ??
            'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
        receiptUrl = await _uploadWebReceipt(
          expense.userId,
          expense.id,
          webReceiptImage,
          fileName,
        );
      } else if (receiptImage != null) {
        receiptUrl =
            await _uploadReceipt(expense.userId, expense.id, receiptImage);
      }

      // Create expense with updated receipt URL if available
      final expenseToUpdate = receiptUrl != null
          ? expense.copyWith(receiptUrl: receiptUrl)
          : expense;

      // Start a batch write transaction
      final batch = _firestore.batch();

      // Update expense in Firestore
      batch.update(
          _expensesCollection.doc(expense.id), expenseToUpdate.toJson());

      // Update budget if exists
      if (originalExpense != null) {
        // If category changed, restore original budget and update new category budget
        if (originalExpense.category != expense.category) {
          // Restore amount in old budget category
          await _updateBudgetForCategory(
            batch,
            expense.userId,
            originalExpense.category,
            originalExpense.date.month,
            originalExpense.date.year,
            -originalExpense.amount, // negative to restore the amount
          );

          // Update new category budget
          await _updateBudgetForCategory(
            batch,
            expense.userId,
            expense.category,
            expense.date.month,
            expense.date.year,
            expense.amount,
          );
        } else {
          // Same category but amount might have changed
          double amountDifference = expense.amount - originalExpense.amount;

          if (amountDifference != 0) {
            await _updateBudgetForCategory(
              batch,
              expense.userId,
              expense.category,
              expense.date.month,
              expense.date.year,
              amountDifference,
            );
          }
        }
      }

      // Commit all changes
      await batch.commit();
    } catch (e) {
      debugPrint('Error in updateExpense: $e');
      rethrow;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId, String? receiptUrl) async {
    try {
      // Get the expense details first
      final expenseDoc = await _expensesCollection.doc(expenseId).get();
      if (!expenseDoc.exists) {
        throw Exception('Expense not found');
      }

      final expense = ExpenseModel.fromJson(expenseDoc.data()!);

      // Start a batch operation
      final batch = _firestore.batch();

      // Delete the expense from Firestore
      batch.delete(_expensesCollection.doc(expenseId));

      // Restore the amount to the budget
      await _updateBudgetAfterExpenseChange(batch, expense, isAddition: false);

      // Commit the batch
      await batch.commit();

      // Delete the receipt image from Firebase Storage if it exists
      // This is done after the database operations since it's less critical
      if (receiptUrl != null && receiptUrl.isNotEmpty) {
        await _deleteReceipt(receiptUrl);
      }
    } catch (e) {
      debugPrint('Error in deleteExpense: $e');
      rethrow;
    }
  }

  // Helper method to update budget when expense is added or deleted
  Future<void> _updateBudgetAfterExpenseChange(
      WriteBatch batch, ExpenseModel expense,
      {required bool isAddition}) async {
    try {
      double amountChange = isAddition ? expense.amount : -expense.amount;
      await _updateBudgetForCategory(
        batch,
        expense.userId,
        expense.category,
        expense.date.month,
        expense.date.year,
        amountChange,
      );
    } catch (e) {
      debugPrint('Error in _updateBudgetAfterExpenseChange: $e');
      // Don't rethrow here as this is a helper method
    }
  }

  // Helper method to update budget by specific amount
  Future<void> _updateBudgetForCategory(
    WriteBatch batch,
    String userId,
    String category,
    int month,
    int year,
    double amountChange,
  ) async {
    try {
      // Find the budget for this category, month, and year
      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // No budget exists for this category/month/year
        return;
      }

      // Get the budget document
      final budgetDoc = querySnapshot.docs.first;
      final budgetData = budgetDoc.data();
      final budget = BudgetModel.fromJson(budgetData);

      // Calculate how much of the budget has been spent
      final currentSpent =
          await _getCurrentSpentAmount(userId, category, month, year);

      // Create a new spent tracking field or use existing
      Map<String, dynamic> updates = {
        'spent': currentSpent + amountChange,
      };

      // Update the budget document
      batch.update(_budgetsCollection.doc(budgetDoc.id), updates);
    } catch (e) {
      debugPrint('Error in _updateBudgetForCategory: $e');
      // Log but don't rethrow since this is a helper method
    }
  }

  // Helper method to get the current spent amount for a budget
  Future<double> _getCurrentSpentAmount(
    String userId,
    String category,
    int month,
    int year,
  ) async {
    try {
      // Get the budget document
      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 0.0;
      }

      final budgetDoc = querySnapshot.docs.first;
      final budgetData = budgetDoc.data();

      // Check if there's an existing 'spent' field
      if (budgetData.containsKey('spent')) {
        return (budgetData['spent'] as num).toDouble();
      }

      // If no 'spent' field exists, calculate from expenses
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final expensesSnapshot = await _expensesCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0.0;
      for (var doc in expensesSnapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data());
        total += expense.amount;
      }

      // Update the budget with the calculated spent amount
      await _budgetsCollection.doc(budgetDoc.id).update({'spent': total});

      return total;
    } catch (e) {
      debugPrint('Error in _getCurrentSpentAmount: $e');
      return 0.0;
    }
  }

  // Upload a receipt image to Firebase Storage
  Future<String> _uploadReceipt(
      String userId, String expenseId, File imageFile) async {
    try {
      final fileName = path.basename(imageFile.path);
      final destination =
          '${AppConstants.receiptStoragePath}/$userId/$expenseId/$fileName';

      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error in _uploadReceipt: $e');
      rethrow;
    }
  }

  // Delete a receipt image from Firebase Storage
  Future<void> _deleteReceipt(String receiptUrl) async {
    try {
      final ref = _storage.refFromURL(receiptUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error in _deleteReceipt: $e');
      // Don't rethrow, just log the error
    }
  }

  // Get total spent amount for a specific date range
  Future<double> getTotalExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _expensesCollection
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data());
        total += expense.amount;
      }

      return total;
    } catch (e) {
      debugPrint('Error in getTotalExpenses: $e');
      return 0;
    }
  }

  // Get total spent by category for a specific date range
  Future<Map<String, double>> getExpensesByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _expensesCollection
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
          .where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
          .get();

      final Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data());
        categoryTotals.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      return categoryTotals;
    } catch (e) {
      debugPrint('Error in getExpensesByCategory: $e');
      return {};
    }
  }

  // Search expenses by title or notes
  Future<List<ExpenseModel>> searchExpenses(
    String userId,
    String query,
  ) async {
    try {
      // Firebase doesn't support native text search, so we'll fetch all user expenses
      // and filter them on the client side
      final snapshot = await _expensesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      final List<ExpenseModel> searchResults = [];
      final lowerCaseQuery = query.toLowerCase();

      for (var doc in snapshot.docs) {
        final expense = ExpenseModel.fromJson(doc.data());

        if (expense.title.toLowerCase().contains(lowerCaseQuery) ||
            (expense.notes != null &&
                expense.notes!.toLowerCase().contains(lowerCaseQuery)) ||
            expense.category.toLowerCase().contains(lowerCaseQuery)) {
          searchResults.add(expense);
        }
      }

      return searchResults;
    } catch (e) {
      debugPrint('Error in searchExpenses: $e');
      return [];
    }
  }

  // Upload a receipt image from web to Firebase Storage
  Future<String> _uploadWebReceipt(
    String userId,
    String expenseId,
    Uint8List imageData,
    String fileName,
  ) async {
    try {
      final destination =
          '${AppConstants.receiptStoragePath}/$userId/$expenseId/$fileName';

      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putData(
        imageData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error in _uploadWebReceipt: $e');
      rethrow;
    }
  }
}
