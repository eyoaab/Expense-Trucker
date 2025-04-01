import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../../../core/constants/app_constants.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection(AppConstants.categoriesCollection);

  // Get all categories for a user
  Future<List<CategoryModel>> getCategories(String userId) async {
    try {
      final snapshot =
          await _categoriesCollection.where('userId', isEqualTo: userId).get();

      if (snapshot.docs.isEmpty) {
        // If no categories found, initialize with default categories
        await _initializeDefaultCategories(userId);
        return CategoryModel.getDefaultCategories(userId);
      }

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data(), userId))
          .toList();
    } catch (e) {
      debugPrint('Error in getCategories: $e');
      // Return default categories in case of error
      return CategoryModel.getDefaultCategories(userId);
    }
  }

  // Initialize default categories for a new user
  Future<void> _initializeDefaultCategories(String userId) async {
    try {
      final batch = _firestore.batch();
      final defaultCategories = CategoryModel.getDefaultCategories(userId);

      for (var category in defaultCategories) {
        final docRef = _categoriesCollection.doc(category.id);
        batch.set(docRef, category.toJson());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in _initializeDefaultCategories: $e');
      rethrow;
    }
  }

  // Add a new custom category
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _categoriesCollection.doc(category.id).set(category.toJson());
    } catch (e) {
      debugPrint('Error in addCategory: $e');
      rethrow;
    }
  }

  // Update an existing category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      // We don't allow updating default categories
      if (category.isDefault) {
        throw Exception('Cannot update default categories');
      }

      await _categoriesCollection.doc(category.id).update(category.toJson());
    } catch (e) {
      debugPrint('Error in updateCategory: $e');
      rethrow;
    }
  }

  // Delete a custom category
  Future<void> deleteCategory(String categoryId) async {
    try {
      // Get the category to check if it's a default one
      final doc = await _categoriesCollection.doc(categoryId).get();

      if (doc.exists) {
        final category = CategoryModel.fromJson(
          doc.data()!,
          doc.data()!['userId'] as String,
        );

        // Don't allow deleting default categories
        if (category.isDefault) {
          throw Exception('Cannot delete default categories');
        }

        await _categoriesCollection.doc(categoryId).delete();
      }
    } catch (e) {
      debugPrint('Error in deleteCategory: $e');
      rethrow;
    }
  }

  // Delete all custom categories for a user (keeps default ones)
  Future<void> deleteAllCustomCategories(String userId) async {
    try {
      final snapshot = await _categoriesCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in deleteAllCustomCategories: $e');
      rethrow;
    }
  }
}
