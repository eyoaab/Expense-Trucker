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
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create from Json (Firestore)
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
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
      currency: map['currency'] ?? 'USD',
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
    );
  }
}
