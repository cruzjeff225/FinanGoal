import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../models/saving_goal.dart';

final savingGoalsProvider = StateNotifierProvider<SavingGoalsNotifier, List<SavingGoal>>((ref) {
  return SavingGoalsNotifier();
});

class SavingGoalsNotifier extends StateNotifier<List<SavingGoal>> {
  SavingGoalsNotifier() : super([]) {
    loadGoals(); // Cargar metas automáticamente al inicializar
  }

  Future<void> loadGoals() async {
    state = await DatabaseHelper.instance.getGoals();
  }

  Future<void> addGoal(SavingGoal goal) async {
    final id = await DatabaseHelper.instance.insertGoal(goal);
    state = [...state, goal.copyWith(id: id)];
  }

  // Actualiza el progreso guardando el nuevo monto ahorrado
  Future<void> addMoneyToGoal(int id, double amountToAdd) async {
    final goalIndex = state.indexWhere((g) => g.id == id);
    if (goalIndex == -1) return;

    final currentGoal = state[goalIndex];
    
    // Sumamos el dinero nuevo a lo que ya estaba ahorrado
    final newSavedAmount = currentGoal.savedAmount + amountToAdd;
    
    // Aseguramos que no sobrepase el monto objetivo visualmente, aunque puedes quitar esto si quieres guardar más.
    final updatedGoal = currentGoal.copyWith(savedAmount: newSavedAmount);

    // Guardamos en la base de datos
    await DatabaseHelper.instance.updateGoal(updatedGoal);

    // Actualizamos el estado de Riverpod
    state = [
      for (final goal in state)
        if (goal.id == id) updatedGoal else goal,
    ];
  }
}
