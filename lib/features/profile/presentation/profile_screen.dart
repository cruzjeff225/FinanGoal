import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_constants.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/features/auth/providers/auth_provider.dart';
import 'package:finan_goal/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:finan_goal/features/transaction/presentation/add_transaction_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  String _name = '', _email = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name  = prefs.getString(AppConstants.keyUserName)  ?? 'Usuario';
      _email = prefs.getString(AppConstants.keyUserEmail) ?? '';
    });
  }

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'U';
  }

  Future<void> _logout() async {
    ref.read(authProvider.notifier).resetState();
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    if (mounted) context.goNamed('login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
              child: Column(
                children: [
                  // Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mi Perfil', style: AppTextStyles.displayMedium),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar + nombre
                  _buildAvatarSection(),
                  const SizedBox(height: 20),

                  // Stats rápidas
                  _buildStatsRow(),
                  const SizedBox(height: 20),

                  // Menú
                  _buildMenu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24, offset: const Offset(0, 8),
            )],
          ),
          child: Center(child: Text(_initials,
              style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white, fontSize: 26))),
        ),
        const SizedBox(height: 12),
        Text(_name, style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text(_email, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text('✦  Plan Gratis',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatBadge(value: '\$12,450', label: 'Balance', color: AppColors.primary),
          const SizedBox(width: 10),
          _StatBadge(value: '24', label: 'Movimientos'),
          const SizedBox(width: 10),
          _StatBadge(value: '3', label: 'Metas', color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    final items = [
      _MenuItem(icon: '🎯', label: 'Mis Metas',
          bg: AppColors.primary.withOpacity(0.12), onTap: () {}),
      _MenuItem(icon: '🔔', label: 'Notificaciones',
          bg: AppColors.accent.withOpacity(0.12),
          badge: '3', onTap: () {}),
      _MenuItem(icon: '🔒', label: 'Seguridad',
          bg: const Color(0xFF8B7FE8).withOpacity(0.12), onTap: () {}),
      _MenuItem(icon: '💎', label: 'Actualizar a Pro',
          bg: AppColors.error.withOpacity(0.08),
          badge: 'Nuevo', badgeColor: AppColors.accent, onTap: () {}),
      _MenuItem(icon: '🚪', label: 'Cerrar sesión',
          bg: AppColors.error.withOpacity(0.10),
          textColor: AppColors.error, onTap: _logout, isLast: true),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: items.map((item) => _MenuTile(item: item)).toList()),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String value, label;
  final Color? color;
  const _StatBadge({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.labelLarge.copyWith(
                fontSize: 16, color: color ?? AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String icon, label;
  final Color bg;
  final String? badge;
  final Color? badgeColor, textColor;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon, required this.label, required this.bg,
    required this.onTap, this.badge, this.badgeColor,
    this.textColor, this.isLast = false,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: item.isLast ? null : Border(
            bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: item.bg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(item.icon,
                  style: const TextStyle(fontSize: 17))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label,
                style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    color: item.textColor ?? AppColors.textPrimary))),
            if (item.badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.badgeColor ?? AppColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(item.badge!,
                    style: AppTextStyles.caption.copyWith(
                        color: item.badgeColor ?? AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            if (!item.isLast)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}