class TransactionModel {
  final int? id;
  final double amount;
  final String description;
  final String category;
  final bool isIncome;
  final DateTime date;

  const TransactionModel({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.isIncome,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'isIncome': isIncome ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      description: map['description'],
      category: map['category'],
      isIncome: map['isIncome'] == 1,
      date: DateTime.parse(map['date']),
    );
  }

  TransactionModel copyWith({
    int? id,
    double? amount,
    String? description,
    String? category,
    bool? isIncome,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
    );
  }
}