import 'package:flutter/material.dart';
import '../repositories/category_repository.dart';
import '../models/category_model.dart';
import '../../../core/theme/app_theme.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository = CategoryRepository();
  bool _isLoading = false;
  String? _errorMessage;
  List<CategoryModel>? _categories;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CategoryModel> get categories => _categories ?? [];

  CategoryProvider() {
    // Initialize with default categories if needed
    _categories = [];
  }

  // Load categories for a user
  Future<void> loadCategories(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getCategories(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a custom category
  Future<bool> addCategory({
    required String userId,
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create a new unique ID for the category (custom-{userId}-{name})
      final id = 'custom-$userId-${name.toLowerCase().replaceAll(' ', '-')}';

      final category = CategoryModel(
        id: id,
        name: name,
        color: color,
        icon: icon,
        isDefault: false,
        userId: userId,
      );

      await _categoryRepository.addCategory(category);
      await loadCategories(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update a category
  Future<bool> updateCategory(
    CategoryModel category, {
    String? name,
    Color? color,
    IconData? icon,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedCategory = category.copyWith(
        name: name,
        color: color,
        icon: icon,
      );

      await _categoryRepository.updateCategory(updatedCategory);
      await loadCategories(category.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String userId, String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryRepository.deleteCategory(categoryId);
      await loadCategories(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete all custom categories
  Future<bool> deleteAllCustomCategories(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryRepository.deleteAllCustomCategories(userId);
      await loadCategories(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Find a category by name
  CategoryModel findCategoryByName(String name) {
    try {
      return _categories!.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      // Return 'Other' category if not found
      return _categories!.firstWhere(
        (category) => category.name == 'Other',
        orElse: () => CategoryModel(
          id: 'other',
          name: 'Other',
          color: AppTheme.otherColor,
          icon: Icons.category,
          isDefault: true,
          userId: '',
        ),
      );
    }
  }
}
