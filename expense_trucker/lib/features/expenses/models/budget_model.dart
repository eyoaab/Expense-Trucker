import 'package:uuid/uuid.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final String period; // 'monthly', 'weekly', etc.
  final int year;
  final int month; // 1-12
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.period,
    required this.year,
    required this.month,
    required this.currency,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a new budget
  factory BudgetModel.createNew({
    required String userId,
    required String category,
    required double amount,
    String period = 'monthly',
    int? year,
    int? month,
    required String currency,
  }) {
    final now = DateTime.now();
    return BudgetModel(
      id: const Uuid().v4(),
      userId: userId,
      category: category,
      amount: amount,
      period: period,
      year: year ?? now.year,
      month: month ?? now.month,
      currency: currency,
      createdAt: now,
      updatedAt: null,
    );
  }

  // Create from Json (Firestore)
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      currency: json['currency'] as String? ?? 'USD',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['updatedAt'] as int),
            )
          : null,
    );
  }

  // Convert to Json (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'period': period,
      'year': year,
      'month': month,
      'currency': currency,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Clone with method to update budget properties
  BudgetModel copyWith({
    String? category,
    double? amount,
    String? period,
    int? year,
    int? month,
    String? currency,
  }) {
    return BudgetModel(
      id: id,
      userId: userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      year: year ?? this.year,
      month: month ?? this.month,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
