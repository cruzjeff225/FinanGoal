import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/core/widgets/app_button.dart';
import 'package:finan_goal/core/widgets/app_text_field.dart';
import 'package:finan_goal/core/widgets/password_strength_indicator.dart';
import 'package:finan_goal/features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Para indicador de fortaleza de contaseña
  String _passwordValue = '';

  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  // Elementos: header, nombre, email, password, confirm, button+footer
  static const int _elementCount = 6;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _passwordController.addListener(() {
      setState(() => _passwordValue = _passwordController.text);
    });
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    final step = 0.12;
    _fadeAnims = List.generate(_elementCount, (i) {
      final start = (i * step).clamp(0.0, 0.7);
      final end = (start + 0.38).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_elementCount, (i) {
      final start = (i * step).clamp(0.0, 0.7);
      final end = (start + 0.38).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => FadeTransition(
    opacity: _fadeAnims[index],
    child: SlideTransition(position: _slideAnims[index], child: child),
  );

  // Lógica de registro
  Future<void> _onRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      _showSuccessAndNavigate();
    }
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1600),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¡Cuenta creada!',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                Text('Bienvenido a FinanGoal 🎉',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) context.goNamed('home');
    });
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior con botón atrás
              _buildTopBar(),

              // Formulario scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Header
                        _animated(0, _buildHeader()),

                        const SizedBox(height: 32),

                        // Nombre
                        _animated(
                          1,
                          AppTextField(
                            label: 'Nombre completo',
                            hint: 'Luis García',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              if (v.trim().length < 3) {
                                return 'Mínimo 3 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Email
                        _animated(
                          2,
                          AppTextField(
                            label: 'Correo electrónico',
                            hint: 'tucorreo@email.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              if (!RegExp(
                                  r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v)) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Contraseña + indicador de fortaleza
                        _animated(
                          3,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                label: 'Contraseña',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                isPassword: true,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Ingresa una contraseña';
                                  }
                                  if (v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              PasswordStrengthIndicator(
                                password: _passwordValue,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Confirmar contraseña
                        _animated(
                          4,
                          AppTextField(
                            label: 'Confirmar contraseña',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _confirmController,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: _onRegister,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirma tu contraseña';
                              }
                              if (v != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Error banner
                        if (authState.status == AuthStatus.error &&
                            authState.errorMessage != null)
                          _buildErrorBanner(authState.errorMessage!),

                        const SizedBox(height: 28),

                        // Botón registrar
                        _animated(
                          5,
                          AppButton(
                            label: 'Crear cuenta',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _onRegister,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footer — términos
                        _animated(5, _buildTermsFooter()),

                        const SizedBox(height: 32),
                      ],
                    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(authProvider.notifier).resetState();
              context.goNamed('login');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crea tu cuenta ✨', style: AppTextStyles.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Empieza a tomar control de tus finanzas hoy',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsFooter() {
    return Center(
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.caption,
          children: [
            const TextSpan(text: 'Al registrarte aceptas nuestros '),
            TextSpan(
              text: 'Términos',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' y '),
            TextSpan(
              text: 'Privacidad',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}