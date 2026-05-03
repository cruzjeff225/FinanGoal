import 'package:flutter/material.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

class SavingsGoalCard extends StatelessWidget {
  final String emoji;
  final String name;
  final double current;
  final double target;

  const SavingsGoalCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.current,
    required this.target,
  });

  double get _progress => (current / target).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final pct = (_progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelLarge),
                    Text(
                      '\$${_fmt(current)} / \$${_fmt(target)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}