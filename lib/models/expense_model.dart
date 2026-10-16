import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final String note;
  final double amount;
  final DateTime createdAt;

  ExpenseModel({
    String? id,
    required this.note,
    required this.amount,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ExpenseModel(
      id: docId ?? map['id'] ?? '',
      note: map['note'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? note,
    double? amount,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
