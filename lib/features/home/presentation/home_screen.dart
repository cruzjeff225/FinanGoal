import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_constants.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/home/presentation/widgets/balance_card.dart';
import 'package:finan_goal/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:finan_goal/features/home/presentation/widgets/income_expense_row.dart';
import 'package:finan_goal/features/home/presentation/widgets/savings_goal_card.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/features/transaction/presentation/add_transaction_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _userName = '';

  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  // Datos mock — Fase 5 los conectará con SQLite real
  static const double _balance = 12450.00;
  static const double _income = 5200;
  static const double _expense = 2750;

  final List<Map<String, dynamic>> _goals = [
    {'emoji': '🏖️', 'name': 'Vacaciones', 'current': 1500.0, 'target': 3000.0},
    {'emoji': '🚗', 'name': 'Auto nuevo', 'current': 8000.0, 'target': 25000.0},
    {'emoji': '🏠', 'name': 'Casa propia', 'current': 3200.0, 'target': 50000.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _setupAnimations();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(AppConstants.keyUserName) ?? 'Usuario';
    setState(() => _userName = fullName.split(' ').first);
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    const count = 5;
    _fadeAnims = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.6);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.6);
      return Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top bar ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _animated(0, _buildTopBar()),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Balance card ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _animated(
                    1,
                    BalanceCard(balance: _balance, changePercent: 3.2),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Income / Expense ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _animated(
                    2,
                    IncomeExpenseRow(income: _income, expense: _expense),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Goals header ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _animated(3, _buildSectionHeader()),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Goals list ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _animated(
                        4,
                        SavingsGoalCard(
                          emoji: _goals[index]['emoji'],
                          name: _goals[index]['name'],
                          current: _goals[index]['current'],
                          target: _goals[index]['target'],
                        ),
                      ),
                    ),
                    childCount: _goals.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $_userName 👋',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text('Mi Dashboard', style: AppTextStyles.displayMedium),
            ],
          ),
        ),
        // Avatar
        Container(
          width: 44,
          height: 44,
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
          child: Center(
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Metas de Ahorro 🎯', style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
        GestureDetector(
          onTap: () {}, // Fase 6 — Metas
          child: Text(
            'Ver todo',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}