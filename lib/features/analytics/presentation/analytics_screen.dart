import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/transaction/models/transaction_model.dart';
import 'package:finan_goal/features/transaction/providers/transaction_provider.dart';
import 'package:finan_goal/features/transaction/presentation/add_transaction_sheet.dart';

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

  void _showTransactionDetailsSheet(BuildContext context, WidgetRef ref, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _TransactionDetailsSheet(tx: tx, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = tx.isIncome ? AppColors.primary : AppColors.error;
    final sign  = tx.isIncome ? '+' : '-';

    return GestureDetector(
      onTap: () => _showTransactionDetailsSheet(context, ref, tx),
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

// ── Modal de Detalles de Transacción ──────────────────────────
class _TransactionDetailsSheet extends StatefulWidget {
  final TransactionModel tx;
  final WidgetRef ref;

  const _TransactionDetailsSheet({required this.tx, required this.ref});

  @override
  State<_TransactionDetailsSheet> createState() => _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<_TransactionDetailsSheet> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateRemaining();
      }
    });
  }

  void _calculateRemaining() {
    final difference = DateTime.now().toUtc().difference(widget.tx.date.toUtc());
    final remaining = 60 - difference.inSeconds;
    setState(() {
      _remainingSeconds = remaining.clamp(0, 60);
    });
    if (_remainingSeconds <= 0) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDateDetail(DateTime d) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day} de ${months[d.month - 1]} de ${d.year} a las $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tx.isIncome ? AppColors.primary : AppColors.error;
    final typeText = widget.tx.isIncome ? 'Ingreso' : 'Gasto';
    final sign = widget.tx.isIncome ? '+' : '-';
    final canEdit = _remainingSeconds > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF152336),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          // Categoría Emoji grande
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.tx.category.split(' ').first,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Título y Categoría
          Center(
            child: Column(
              children: [
                Text(
                  widget.tx.description,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tx.category,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Monto
          Center(
            child: Text(
              '$sign\$${widget.tx.amount.toStringAsFixed(2)}',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 36,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Divider(color: Color(0xFF243D54)),
          const SizedBox(height: 12),

          // Detalle de fecha y tipo
          _buildDetailRow('Tipo', typeText, icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _buildDetailRow('Fecha y Hora', _formatDateDetail(widget.tx.date), icon: Icons.calendar_today_outlined),
          const SizedBox(height: 12),

          // Notas / Descripción detallada
          Text(
            'DESCRIPCIÓN DETALLADA / NOTAS',
            style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight, width: 1),
            ),
            child: Text(
              widget.tx.notes != null && widget.tx.notes!.isNotEmpty
                  ? widget.tx.notes!
                  : 'Sin detalles adicionales registrados.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // Tiempo restante para edición
          Column(
            children: [
              // Edición
              if (canEdit)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Editable durante los próximos $_remainingSeconds segundos ⏱️',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Edición bloqueada (límite de 1 min superado)',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Acciones
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: canEdit
                  ? () {
                      Navigator.pop(context); // Cerrar detalles
                      AddTransactionSheet.show(context, transactionToEdit: widget.tx);
                    }
                  : null,
              icon: Icon(
                canEdit ? Icons.edit_outlined : Icons.lock_outline_rounded,
                size: 18,
              ),
              label: const Text('Editar', style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: canEdit ? AppColors.primary.withOpacity(0.5) : AppColors.textHint.withOpacity(0.3),
                ),
                disabledForegroundColor: AppColors.textHint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textHint, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}