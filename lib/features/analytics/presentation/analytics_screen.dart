import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/transaction/models/transaction_model.dart';
import 'package:finan_goal/features/transaction/providers/transaction_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final totalIncome  = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);

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
                child: Text('Mis Movimientos',
                    style: AppTextStyles.displayMedium),
              ),

              const SizedBox(height: 16),

              // ── Resumen ingresos / gastos ────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Ingresos',
                        amount: totalIncome,
                        color: AppColors.primary,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Gastos',
                        amount: totalExpense,
                        color: AppColors.error,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Título lista ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Historial',
                    style:
                    AppTextStyles.displayMedium.copyWith(fontSize: 16)),
              ),

              const SizedBox(height: 12),

              // ── Lista de transacciones ───────────────────
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: AppColors.textHint, size: 48),
                      const SizedBox(height: 12),
                      Text('Sin movimientos aún',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint)),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _TransactionTile(tx: transactions[i], ref: ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta resumen ───────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: color, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de cada transacción ──────────────────────────────────
class _TransactionTile extends ConsumerWidget {
  final TransactionModel tx;
  final WidgetRef ref;

  const _TransactionTile({required this.tx, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = tx.isIncome ? AppColors.primary : AppColors.error;
    final sign  = tx.isIncome ? '+' : '-';

    return Dismissible(
      key: Key('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 24),
      ),
      onDismissed: (_) {
        ref.read(transactionProvider.notifier).deleteTransaction(tx.id!);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Ícono categoría
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  tx.category.split(' ').first, // el emoji
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Descripción y categoría
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description,
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.category}  •  ${_formatDate(tx.date)}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Monto
            Text(
              '$sign\$${tx.amount.toStringAsFixed(2)}',
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}