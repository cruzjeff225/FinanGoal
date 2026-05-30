import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import '../models/saving_goal.dart';
import '../providers/saving_goals_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Metas',
                            style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ahorra con un objetivo en mente',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Botón flotante estilizado como acción rápida arriba
                    GestureDetector(
                      onTap: () => _showCreateGoalBottomSheet(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Listado de metas ────────────────────────
              Expanded(
                child: goals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🎯', style: TextStyle(fontSize: 48)),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Sin metas activas',
                              style: AppTextStyles.displayMedium.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Crea una meta de viaje, salud, compras o entretenimiento y visualiza tu progreso de ahorro.',
                                style: AppTextStyles.caption,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 180,
                              height: 44,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => _showCreateGoalBottomSheet(context, ref),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Crear Meta',
                                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: goals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _GoalCard(goal: goals[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGoalBottomSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final emojiController = TextEditingController(text: '💰');

    // Categorías sugeridas con Emojis
    final List<Map<String, String>> categories = [
      {'name': 'Viaje ✈️', 'emoji': '✈️', 'defaultName': 'Mis Vacaciones'},
      {'name': 'Salud 🩺', 'emoji': '🩺', 'defaultName': 'Fondo de Salud'},
      {'name': 'Compras 🛍️', 'emoji': '🛍️', 'defaultName': 'Mis Compras'},
      {'name': 'Diversión 🎮', 'emoji': '🎮', 'defaultName': 'Entretenimiento'},
      {'name': 'Hogar 🏠', 'emoji': '🏠', 'defaultName': 'Ahorro Casa'},
      {'name': 'Auto 🚗', 'emoji': '🚗', 'defaultName': 'Fondo Auto'},
      {'name': 'Estudio 🎓', 'emoji': '🎓', 'defaultName': 'Mis Estudios'},
      {'name': 'General 💰', 'emoji': '💰', 'defaultName': 'Ahorro General'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        String selectedCategoryName = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF152336),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 12,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Text(
                    'Nueva Meta de Ahorro 🎯',
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Categorías sugeridas
                  Text(
                    'SUGERENCIAS DE METAS',
                    style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = selectedCategoryName == cat['name'];

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedCategoryName = cat['name']!;
                              emojiController.text = cat['emoji']!;
                              nameController.text = cat['defaultName']!;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat['name']!,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Emoji + Nombre en fila
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: TextField(
                            controller: emojiController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 26),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: nameController,
                            style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ej. Viaje a París ✈️',
                              hintStyle: AppTextStyles.caption,
                              border: InputBorder.none,
                              labelText: 'NOMBRE DE LA META',
                              labelStyle: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Monto Objetivo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 16, color: AppColors.primary),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16, color: AppColors.primary),
                        hintText: '0.00',
                        hintStyle: AppTextStyles.caption.copyWith(fontSize: 16),
                        border: InputBorder.none,
                        labelText: 'MONTO OBJETIVO A ALCANZAR',
                        labelStyle: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de creación
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final target = double.tryParse(targetController.text) ?? 0.0;
                          final emoji = emojiController.text.trim().isNotEmpty ? emojiController.text : '💰';

                          if (name.isNotEmpty && target > 0) {
                            ref.read(savingGoalsProvider.notifier).addGoal(
                              SavingGoal(name: name, targetAmount: target, emoji: emoji),
                            );
                            Navigator.pop(context);
                          } else {
                            HapticFeedback.vibrate();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Crear Meta',
                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final SavingGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = (goal.progress * 100).toStringAsFixed(1);
    final isCompleted = goal.progress >= 1.0;

    return Dismissible(
      key: Key('goal_${goal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
      ),
      onDismissed: (_) {
        if (goal.id != null) {
          ref.read(savingGoalsProvider.notifier).deleteGoal(goal.id!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Cabecera: Caja de emoji, título y botón de abonar
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted ? '🎉 ¡Objetivo Alcanzado!' : 'En progreso de ahorro',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isCompleted ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: isCompleted ? AppColors.accent : AppColors.primary,
                    size: 32,
                  ),
                  onPressed: () => _showAddMoneyDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Montos: Ahorrado vs Objetivo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '\$${goal.savedAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      ' de \$${goal.targetAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '$percentage%',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isCompleted ? AppColors.accent : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Barra de progreso estilizada
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.accent : AppColors.primary,
                ),
              ),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Abonar a ${goal.name}',
          style: AppTextStyles.displayMedium.copyWith(fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.labelLarge.copyWith(fontSize: 16, color: AppColors.primary),
          decoration: InputDecoration(
            labelText: 'Monto a ahorrar',
            labelStyle: AppTextStyles.caption,
            prefixText: '\$ ',
            prefixStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surfaceLight)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0 && goal.id != null) {
                ref.read(savingGoalsProvider.notifier).addMoneyToGoal(goal.id!, amount);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Abonar',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
