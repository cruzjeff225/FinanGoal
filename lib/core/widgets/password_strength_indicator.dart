import 'package:flutter/material.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

enum PasswordStrength { empty, weak, fair, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score == 2 || score == 3) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = evaluate(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    final (label, color, segments) = switch (strength) {
      PasswordStrength.weak => ('Débil', AppColors.error, 1),
      PasswordStrength.fair => ('Regular', AppColors.warning, 2),
      PasswordStrength.strong => ('Fuerte', AppColors.success, 3),
      PasswordStrength.empty => ('', Colors.transparent, 0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (i) {
            final active = i < segments;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? color : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey(label),
            children: [
              Icon(
                strength == PasswordStrength.strong
                    ? Icons.shield_rounded
                    : Icons.info_outline_rounded,
                color: color,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                'Contraseña $label',
                style: AppTextStyles.caption.copyWith(color: color),
              ),
              if (strength != PasswordStrength.strong) ...[
                const SizedBox(width: 4),
                Text(
                  _hint(password),
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _hint(String password) {
    if (password.length < 8) return '· mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return '· agrega mayúsculas';
    if (!RegExp(r'[0-9]').hasMatch(password)) return '· agrega números';
    if (!RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(password)) {
      return '· agrega símbolos';
    }
    return '';
  }
}