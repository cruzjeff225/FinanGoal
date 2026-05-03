import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  // Helper estático para mostrar el sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      // Transición slide-up personalizada
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 380),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  bool _isIncome = false;
  String _numStr = '';
  final String _description = 'Salario mensual';
  final String _category = '💼 Trabajo';

  void _numPress(String k) {
    setState(() {
      if (k == 'del') {
        if (_numStr.isNotEmpty) _numStr = _numStr.substring(0, _numStr.length - 1);
      } else if (k == '.' && _numStr.contains('.')) {
        return;
      } else if (_numStr.length < 8) {
        _numStr += k;
      }
    });
    HapticFeedback.lightImpact();
  }

  String get _displayAmount {
    final n = double.tryParse(_numStr) ?? 0;
    return '\$${n.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF152336),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 3,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text('Nueva Transacción', style: AppTextStyles.displayMedium
                .copyWith(fontSize: 18)),
          ),

          // Toggle ingreso/gasto
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Expanded(child: _TypeButton(
                  label: '↓  Ingreso',
                  active: _isIncome,
                  activeColor: AppColors.primary,
                  onTap: () => setState(() => _isIncome = true),
                )),
                const SizedBox(width: 8),
                Expanded(child: _TypeButton(
                  label: '↑  Gasto',
                  active: !_isIncome,
                  activeColor: AppColors.error,
                  onTap: () => setState(() => _isIncome = false),
                )),
              ],
            ),
          ),

          // Monto grande
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              children: [
                Text(
                  _displayAmount,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 40,
                    color: _isIncome ? AppColors.primary : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Toca para ingresar el monto', style: AppTextStyles.caption),
              ],
            ),
          ),

          // Campos info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _InfoField(icon: Icons.notes_rounded, label: 'DESCRIPCIÓN',
                value: _description),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(child: _InfoField(icon: Icons.category_outlined,
                    label: 'CATEGORÍA', value: _category)),
                const SizedBox(width: 8),
                Expanded(child: _InfoField(icon: Icons.calendar_today_outlined,
                    label: 'FECHA', value: '01 May 2026')),
              ],
            ),
          ),

          // Numpad
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2.8,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                ...'123456789'.split('').map((k) => _NumKey(
                  label: k,
                  onTap: () => _numPress(k),
                )),
                _NumKey(label: '.', onTap: () => _numPress('.'),
                    color: AppColors.primary),
                _NumKey(label: '0', onTap: () => _numPress('0')),
                _NumKey(label: '⌫', onTap: () => _numPress('del'),
                    color: AppColors.primary),
              ],
            ),
          ),

          // Botón guardar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Guardar Transacción',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white, fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-widgets del sheet
class _TypeButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.active,
    required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            color: active ? activeColor : AppColors.textHint,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                Text(value, style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _NumKey({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 17,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}