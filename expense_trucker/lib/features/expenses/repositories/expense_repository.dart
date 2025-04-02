import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/expense_model.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection(AppConstants.expensesCollection);

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
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    // Use a simpler query that doesn't need complex indexes
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Filter and sort in memory
      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data()))
          .where((expense) {
        return expense.date
                .isAfter(startDate.subtract(const Duration(minutes: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(minutes: 1)));
      }).toList();

      // Sort in descending order
      expenses.sort((a, b) => b.date.compareTo(a.date));

      return expenses;
    });
  }

  // Get expenses for a user by category within a date range
  Stream<List<ExpenseModel>> getExpensesByCategoryStream(
    String userId,
    String category,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Get all expenses in date range first
    return getExpensesByDateRangeStream(userId, startDate, endDate)
        .map((expenses) {
      // Then filter by category in memory (no need for complex index)
      return expenses.where((expense) => expense.category == category).toList();
    });
  }

  // Get total expenses for a date range
  Future<double> getTotalExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all expenses in date range
      final expenses =
          await getExpensesByDateRangeStream(userId, startDate, endDate).first;

      // Calculate total in memory
      double total = 0;
      for (var expense in expenses) {
        total += expense.amount;
      }

      return total;
    } catch (e) {
      debugPrint('Error in getTotalExpenses: $e');
      return 0.0;
    }
  }

  // Get total expenses for a specific category and date range
  Future<double> getTotalExpensesByCategory(
    String userId,
    String category,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get expenses filtered by category
      final expenses = await getExpensesByCategoryStream(
        userId,
        category,
        startDate,
        endDate,
      ).first;

      // Calculate total
      double total = 0;
      for (var expense in expenses) {
        total += expense.amount;
      }

      return total;
    } catch (e) {
      debugPrint('Error in getTotalExpensesByCategory: $e');
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
      // Get all expenses in date range
      final expenses =
          await getExpensesByDateRangeStream(userId, startDate, endDate).first;

      // Group by category in memory
      final Map<String, double> categoryTotals = {};
      for (var expense in expenses) {
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

      // Add expense to Firestore
      await _expensesCollection.doc(expense.id).set(expenseToAdd.toJson());
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

      // Update expense in Firestore
      await _expensesCollection
          .doc(expense.id)
          .update(expenseToUpdate.toJson());
    } catch (e) {
      debugPrint('Error in updateExpense: $e');
      rethrow;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId, String? receiptUrl) async {
    try {
      // Delete the receipt image from Firebase Storage if it exists
      if (receiptUrl != null && receiptUrl.isNotEmpty) {
        await _deleteReceipt(receiptUrl);
      }

      // Delete expense from Firestore
      await _expensesCollection.doc(expenseId).delete();
    } catch (e) {
      debugPrint('Error in deleteExpense: $e');
      rethrow;
    }
  }

  // Upload a receipt image to Firebase Storage for web
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

  // Upload a receipt image to Firebase Storage
  Future<String> _uploadReceipt(
    String userId,
    String expenseId,
    File imageFile,
  ) async {
    try {
      final fileName = path.basename(imageFile.path);
      final destination =
          '${AppConstants.receiptStoragePath}/$userId/$expenseId/$fileName';
      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask.whenComplete(() {});
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
}
