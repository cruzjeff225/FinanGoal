import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saving_goal.dart';
import '../providers/saving_goals_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas de Ahorro'),
      ),
      body: goals.isEmpty
          ? const Center(child: Text('No tienes metas aún. ¡Crea una!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return _GoalCard(goal: goals[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGoalDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final emojiController = TextEditingController(text: '💰');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Meta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la meta'),
            ),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto a alcanzar'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final target = double.tryParse(targetController.text) ?? 0.0;
              final emoji = emojiController.text.trim().isNotEmpty ? emojiController.text : '💰';

              if (name.isNotEmpty && target > 0) {
                ref.read(savingGoalsProvider.notifier).addGoal(
                  SavingGoal(name: name, targetAmount: target, emoji: emoji),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final SavingGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = (goal.progress * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Cabecera: Emoji, Título y Botón de añadir
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: () => _showAddMoneyDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Textos de ahorrado vs objetivo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${goal.savedAmount.toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('de \$${goal.targetAmount.toStringAsFixed(2)}', 
                  style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            // Barra de progreso lineal
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress, // Progreso entre 0.0 y 1.0
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            
            // Porcentaje en texto
            Align(
              alignment: Alignment.centerRight,
              child: Text('$percentage%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Abonar a ${goal.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto a ahorrar',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0 && goal.id != null) {
                ref.read(savingGoalsProvider.notifier).addMoneyToGoal(goal.id!, amount);
              }
              Navigator.pop(context);
            },
            child: const Text('Abonar'),
          ),
        ],
      ),
    );
  }
}
