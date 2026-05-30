class SavingGoal {
  final String? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String emoji;

  SavingGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.emoji,
  });

  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'emoji': emoji,
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['_id'] ?? map['id'],
      name: map['name'],
      targetAmount: (map['targetAmount'] as num).toDouble(),
      savedAmount: (map['savedAmount'] as num).toDouble(),
      emoji: map['emoji'],
    );
  }

  SavingGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? emoji,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      emoji: emoji ?? this.emoji,
    );
  }
}