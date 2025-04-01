import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CategoryModel {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final bool isDefault;
  final String userId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.isDefault,
    required this.userId,
  });

  // Get a predefined list of default categories
  static List<CategoryModel> getDefaultCategories(String userId) {
    return [
      CategoryModel(
        id: 'food',
        name: 'Food',
        color: AppTheme.foodColor,
        icon: Icons.restaurant,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'transport',
        name: 'Transport',
        color: AppTheme.transportColor,
        icon: Icons.directions_car,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'shopping',
        name: 'Shopping',
        color: AppTheme.shoppingColor,
        icon: Icons.shopping_cart,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'housing',
        name: 'Housing',
        color: AppTheme.housingColor,
        icon: Icons.home,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'entertainment',
        name: 'Entertainment',
        color: AppTheme.entertainmentColor,
        icon: Icons.movie,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'healthcare',
        name: 'Healthcare',
        color: AppTheme.healthcareColor,
        icon: Icons.medical_services,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'education',
        name: 'Education',
        color: AppTheme.educationColor,
        icon: Icons.school,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'travel',
        name: 'Travel',
        color: AppTheme.travelColor,
        icon: Icons.flight,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'utilities',
        name: 'Utilities',
        color: AppTheme.utilitiesColor,
        icon: Icons.power,
        isDefault: true,
        userId: userId,
      ),
      CategoryModel(
        id: 'other',
        name: 'Other',
        color: AppTheme.otherColor,
        icon: Icons.category,
        isDefault: true,
        userId: userId,
      ),
    ];
  }

  // Create from Json (Firestore)
  factory CategoryModel.fromJson(Map<String, dynamic> json, String userId) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: IconData(
        json['icon'] as int,
        fontFamily: 'MaterialIcons',
      ),
      isDefault: json['isDefault'] as bool? ?? false,
      userId: json['userId'] as String? ?? userId,
    );
  }

  // Convert to Json (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
      'isDefault': isDefault,
      'userId': userId,
    };
  }

  // Clone with method to update category properties
  CategoryModel copyWith({
    String? name,
    Color? color,
    IconData? icon,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault,
      userId: userId,
    );
  }

  // Find a category by name
  static CategoryModel findByName(List<CategoryModel> categories, String name) {
    try {
      return categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      // Return 'Other' category if not found
      return categories.firstWhere(
        (category) => category.name == 'Other',
      );
    }
  }
}
