import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final int month;
  final int year;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double spent;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.currency,
    required this.createdAt,
    this.updatedAt,
    this.spent = 0.0,
  });

  // Create a new budget
  factory BudgetModel.createNew({
    required String userId,
    required String category,
    required double amount,
    required int month,
    required int year,
    required String currency,
  }) {
    final now = DateTime.now();
    return BudgetModel(
      id: const Uuid().v4(),
      userId: userId,
      category: category,
      amount: amount,
      month: month,
      year: year,
      currency: currency,
      createdAt: now,
      updatedAt: null,
      spent: 0.0,
    );
  }

  // Convert to Json (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'spent': spent,
    };
  }

  // Create from Json (Firestore)
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    // Helper function to parse date fields that might be Timestamps or milliseconds
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is Map && value['_seconds'] != null) {
        // Sometimes Firestore returns serialized timestamps
        return DateTime.fromMillisecondsSinceEpoch(
            (value['_seconds'] as int) * 1000);
      }
      return DateTime.now();
    }

    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
      currency: json['currency'] as String? ?? 'ETB',
      createdAt: parseDate(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
      spent: json['spent'] != null ? (json['spent'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      month: map['month'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      currency: map['currency'] ?? 'ETB',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is int)
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : (map['updatedAt'] is int)
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
              : null,
      spent: map['spent'] != null ? (map['spent'] as num).toDouble() : 0.0,
    );
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel.fromMap(data, doc.id);
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    int? month,
    int? year,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? spent,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spent: spent ?? this.spent,
    );
  }

  // Calculate budget remaining
  double get remaining => amount - spent;

  // Calculate percentage spent
  double get percentageSpent => amount > 0 ? (spent / amount) * 100 : 0;
}
