import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? receiptUrl;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.receiptUrl,
    required this.currency,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a new expense
  factory ExpenseModel.createNew({
    required String userId,
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    String? notes,
    String? receiptUrl,
    required String currency,
  }) {
    final now = DateTime.now();
    return ExpenseModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      category: category,
      amount: amount,
      date: date,
      notes: notes,
      receiptUrl: receiptUrl,
      currency: currency,
      createdAt: now,
      updatedAt: null,
    );
  }

  // Create from Json (Firestore)
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
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

    return ExpenseModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: parseDate(json['date']),
      notes: json['notes'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      currency: json['currency'] as String? ?? 'ETB',
      createdAt: parseDate(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
    );
  }

  // Convert to Json (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'receiptUrl': receiptUrl,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Clone with method to update expense properties
  ExpenseModel copyWith({
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
    String? receiptUrl,
    String? currency,
  }) {
    return ExpenseModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
