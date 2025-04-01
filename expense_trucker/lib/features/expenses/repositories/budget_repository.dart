import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../../../core/constants/app_constants.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _firestore.collection(AppConstants.budgetsCollection);

  // Get all budgets for a user
  Stream<List<BudgetModel>> getBudgetsStream(String userId) {
    return _budgetsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BudgetModel.fromJson(doc.data());
      }).toList();
    });
  }

  // Get a user's budget for a specific category, month, and year
  Future<BudgetModel?> getBudget(
    String userId,
    String category,
    int year,
    int month,
  ) async {
    try {
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BudgetModel.fromJson(snapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      debugPrint('Error in getBudget: $e');
      return null;
    }
  }

  // Get all budgets for a specific month and year
  Future<List<BudgetModel>> getBudgetsByMonth(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error in getBudgetsByMonth: $e');
      return [];
    }
  }

  // Add or update a budget
  Future<void> setBudget(BudgetModel budget) async {
    try {
      // Check if budget already exists
      final existingBudget = await getBudget(
        budget.userId,
        budget.category,
        budget.year,
        budget.month,
      );

      if (existingBudget != null) {
        // Update existing budget
        final updatedBudget = existingBudget.copyWith(
          amount: budget.amount,
          currency: budget.currency,
        );
        await _budgetsCollection
            .doc(existingBudget.id)
            .update(updatedBudget.toJson());
      } else {
        // Create new budget
        await _budgetsCollection.doc(budget.id).set(budget.toJson());
      }
    } catch (e) {
      debugPrint('Error in setBudget: $e');
      rethrow;
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetsCollection.doc(budgetId).delete();
    } catch (e) {
      debugPrint('Error in deleteBudget: $e');
      rethrow;
    }
  }

  // Get spending percentage against budget for a specific category, month, and year
  Future<double> getSpendingPercentage(
    String userId,
    String category,
    int year,
    int month,
    double spentAmount,
  ) async {
    try {
      final budget = await getBudget(userId, category, year, month);

      if (budget != null && budget.amount > 0) {
        return (spentAmount / budget.amount) * 100;
      }

      return 0;
    } catch (e) {
      debugPrint('Error in getSpendingPercentage: $e');
      return 0;
    }
  }

  // Delete all budgets for a user
  Future<void> deleteAllBudgets(String userId) async {
    try {
      final snapshot =
          await _budgetsCollection.where('userId', isEqualTo: userId).get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in deleteAllBudgets: $e');
      rethrow;
    }
  }
}
