class TransactionModel {
  final int? id;
  final String? cloudId;
  final double amount;
  final String description;
  final String category;
  final bool isIncome;
  final DateTime date;
  final String? notes;

  const TransactionModel({
    this.id,
    this.cloudId,
    required this.amount,
    required this.description,
    required this.category,
    required this.isIncome,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloudId': cloudId,
      'amount': amount,
      'description': description,
      'category': category,
      'isIncome': isIncome ? 1 : 0,
      'date': date.toUtc().toIso8601String(),
      'notes': notes,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'isIncome': isIncome,
      'date': date.toUtc().toIso8601String(),
      'notes': notes ?? '',
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      cloudId: map['cloudId'] ?? map['_id'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'],
      category: map['category'],
      isIncome: map['isIncome'] == 1 || map['isIncome'] == true,
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }

  TransactionModel copyWith({
    int? id,
    String? cloudId,
    double? amount,
    String? description,
    String? category,
    bool? isIncome,
    DateTime? date,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}