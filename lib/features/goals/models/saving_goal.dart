class SavingGoal {
  final int? id;
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

  // Calcula automáticamente el progreso (retorna un valor entre 0.0 y 1.0)
  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);

  // Convierte el objeto a un Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'emoji': emoji,
    };
  }

  // Crea el objeto a partir de un Map de SQLite
  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      savedAmount: map['savedAmount'],
      emoji: map['emoji'],
    );
  }

  // Método útil para crear copias modificando solo algunos campos (útil para Riverpod)
  SavingGoal copyWith({
    int? id,
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
