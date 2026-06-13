import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/transaction/models/transaction_model.dart';
import 'package:finan_goal/features/transaction/providers/transaction_provider.dart';

const _incomeCategories = [
  '💼 Trabajo',
  '💰 Freelance',
  '📈 Inversiones',
  '🎁 Regalo',
  '🏦 Banco',
  '📦 Venta',
  '🔄 Transferencia',
  '➕ Otro',
];

const _expenseCategories = [
  '🛒 Supermercado',
  '🍔 Comida',
  '🚗 Transporte',
  '🏠 Vivienda',
  '💊 Salud',
  '📚 Educación',
  '🎬 Entretenimiento',
  '👗 Ropa',
  '💡 Servicios',
  '➕ Otro',
];

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;
  const AddTransactionSheet({super.key, this.transactionToEdit});

  static Future<void> show(BuildContext context, {TransactionModel? transactionToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 380),
      ),
      builder: (_) => AddTransactionSheet(transactionToEdit: transactionToEdit),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  bool _isIncome = true;
  String _numStr = '';
  String _category = _incomeCategories.first;
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _isIncome = tx.isIncome;
      _numStr = tx.amount.toString();
      if (_numStr.endsWith('.0')) {
        _numStr = _numStr.substring(0, _numStr.length - 2);
      }
      _category = tx.category;
      _descController.text = tx.description;
      _notesController.text = tx.notes ?? '';
    } else {
      _category = _incomeCategories.first;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _numPress(String k) {
    setState(() {
      if (k == 'del') {
        if (_numStr.isNotEmpty) {
          _numStr = _numStr.substring(0, _numStr.length - 1);
        }
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

  double get _parsedAmount => double.tryParse(_numStr) ?? 0.0;

  void _switchType(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      _category =
      isIncome ? _incomeCategories.first : _expenseCategories.first;
    });
  }

  Future<void> _save() async {
    if (_parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa un monto válido',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!.copyWith(
        amount: _parsedAmount,
        description: _descController.text.trim().isEmpty
            ? (_isIncome ? 'Ingreso' : 'Gasto')
            : _descController.text.trim(),
        category: _category,
        isIncome: _isIncome,
        notes: _notesController.text.trim(),
      );
      await ref.read(transactionProvider.notifier).updateTransaction(tx);
    } else {
      final tx = TransactionModel(
        amount: _parsedAmount,
        description: _descController.text.trim().isEmpty
            ? (_isIncome ? 'Ingreso' : 'Gasto')
            : _descController.text.trim(),
        category: _category,
        isIncome: _isIncome,
        date: DateTime.now(),
        notes: _notesController.text.trim(),
      );
      await ref.read(transactionProvider.notifier).addTransaction(tx);
    }
    if (mounted) Navigator.pop(context);
  }

  void _showCategoryPicker() {
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: categories
            .map((cat) => ListTile(
          title: Text(cat, style: AppTextStyles.labelLarge),
          trailing: _category == cat
              ? Icon(Icons.check_rounded, color: AppColors.primary)
              : null,
          onTap: () {
            setState(() => _category = cat);
            Navigator.pop(context);
          },
        ))
            .toList(),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isIncome ? AppColors.primary : AppColors.error;
    final isEditing = widget.transactionToEdit != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF152336),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      // ── SingleChildScrollView soluciona el overflow ──
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                isEditing ? 'Editar Transacción' : 'Nueva Transacción',
                style: AppTextStyles.displayMedium.copyWith(fontSize: 18),
              ),
            ),

            // Toggle ingreso / gasto
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: '↓  Ingreso',
                      active: _isIncome,
                      activeColor: AppColors.primary,
                      onTap: () => _switchType(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeButton(
                      label: '↑  Gasto',
                      active: !_isIncome,
                      activeColor: AppColors.error,
                      onTap: () => _switchType(false),
                    ),
                  ),
                ],
              ),
            ),

            // Monto
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  Text(
                    _displayAmount,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 40,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('Toca los números para ingresar el monto',
                      style: AppTextStyles.caption),
                ],
              ),
            ),

            // Descripción editable
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes_rounded,
                        color: AppColors.textHint, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _descController,
                        style:
                        AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: _isIncome
                              ? 'Salario mensual...'
                              : 'Descripción...',
                          hintStyle: AppTextStyles.caption,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notas detalladas
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(Icons.description_outlined,
                          color: AppColors.textHint, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        minLines: 1,
                        style:
                        AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Detalles adicionales / lo que compraste...',
                          hintStyle: AppTextStyles.caption,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categoría y fecha
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showCategoryPicker,
                      child: _InfoField(
                        icon: Icons.category_outlined,
                        label: 'CATEGORÍA',
                        value: _category,
                        isInteractive: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoField(
                      icon: Icons.calendar_today_outlined,
                      label: 'FECHA',
                      value: _formatDate(isEditing ? widget.transactionToEdit!.date : DateTime.now()),
                    ),
                  ),
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
                  ...'123456789'.split('').map(
                        (k) => _NumKey(label: k, onTap: () => _numPress(k)),
                  ),
                  _NumKey(
                      label: '.',
                      onTap: () => _numPress('.'),
                      color: AppColors.primary),
                  _NumKey(label: '0', onTap: () => _numPress('0')),
                  _NumKey(
                      label: '⌫',
                      onTap: () => _numPress('del'),
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
                    gradient: _isIncome
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                      colors: [Color(0xFFFF5C5C), Color(0xFFCC3333)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isEditing ? 'Guardar Cambios' : (_isIncome ? 'Guardar Ingreso' : 'Guardar Gasto'),
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(color: activeColor.withOpacity(0.4), width: 1)
              : null,
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
  final String label;
  final String value;
  final bool isInteractive;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    this.isInteractive = false,
  });

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
                Text(label,
                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style:
                        AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isInteractive)
                      Icon(Icons.expand_more_rounded,
                          color: AppColors.textHint, size: 14),
                  ],
                ),
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