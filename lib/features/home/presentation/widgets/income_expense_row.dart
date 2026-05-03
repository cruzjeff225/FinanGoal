import 'package:flutter/material.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

class IncomeExpenseRow extends StatelessWidget {
  final double income;
  final double expense;

  const IncomeExpenseRow({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'Ingresos',
            amount: income,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.primary,
            isIncome: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniCard(
            label: 'Gastos',
            amount: expense,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.error,
            isIncome: false,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const _MiniCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  '\$${amount.toStringAsFixed(0)}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}