import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/services/api_service.dart';
import 'package:finan_goal/features/transaction/models/transaction_model.dart';
import 'package:finan_goal/features/transaction/providers/transaction_provider.dart';
import '../models/saving_goal.dart';

final savingGoalsProvider = StateNotifierProvider<SavingGoalsNotifier, List<SavingGoal>>((ref) {
  return SavingGoalsNotifier(ref);
});

class SavingGoalsNotifier extends StateNotifier<List<SavingGoal>> {
  final Ref ref;

  SavingGoalsNotifier(this.ref) : super([]) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      final data = await ApiService.getGoals();
      state = data.map((g) => SavingGoal.fromMap(g)).toList();
    } catch (e) {
      state = [];
    }
  }

  Future<void> addGoal(SavingGoal goal) async {
    try {
      final created = await ApiService.createGoal(goal.toMap());
      state = [...state, SavingGoal.fromMap(created)];
    } catch (e) {
      // Error al crear
    }
  }

  Future<void> addMoneyToGoal(String id, double amountToAdd) async {
    try {
      final goalIndex = state.indexWhere((g) => g.id == id);
      if (goalIndex == -1) return;

      final currentGoal = state[goalIndex];
      final newSavedAmount = currentGoal.savedAmount + amountToAdd;
      final updatedGoal = currentGoal.copyWith(savedAmount: newSavedAmount);

      await ApiService.updateGoal(id, {'savedAmount': newSavedAmount});

      // Crear una transacción para registrar el abono
      final tx = TransactionModel(
        amount: amountToAdd,
        description: 'Abono a ${currentGoal.name}',
        category: '🎯 Abono',
        isIncome: false, // se resta del saldo disponible para sumarlo a la meta
        date: DateTime.now(),
        notes: 'Dinero abonado a la meta: ${currentGoal.name} ${currentGoal.emoji}',
      );
      await ref.read(transactionProvider.notifier).addTransaction(tx);

      state = [
        for (final goal in state)
          if (goal.id == id) updatedGoal else goal,
      ];
    } catch (e) {
      // Error al actualizar
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await ApiService.deleteGoal(id);
      state = state.where((g) => g.id != id).toList();
    } catch (e) {
      // Error al eliminar
    }
  }
}