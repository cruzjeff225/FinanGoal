import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';
import 'package:finan_goal/core/widgets/app_button.dart';
import 'package:finan_goal/core/widgets/app_text_field.dart';
import 'package:finan_goal/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Elementos: header, email, password, button, footer
    const intervals = [
      [0.0, 0.4],
      [0.15, 0.55],
      [0.25, 0.65],
      [0.35, 0.75],
      [0.50, 0.90],
    ];

    _fadeAnims = intervals
        .map(
          (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i[0], i[1], curve: Curves.easeOut),
        ),
      ),
    )
        .toList();

    _slideAnims = intervals
        .map(
          (i) => Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i[0], i[1], curve: Curves.easeOutCubic),
        ),
      ),
    )
        .toList();

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      context.goNamed('home');
    }
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Header
                  _animated(0, _buildHeader()),

                  const SizedBox(height: 40),

                  // Email
                  _animated(
                    1,
                    AppTextField(
                      label: 'Correo electrónico',
                      hint: 'tucorreo@email.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password
                  _animated(
                    2,
                    AppTextField(
                      label: 'Contraseña',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _onLogin,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Error Message
                  if (authState.status == AuthStatus.error &&
                      authState.errorMessage != null)
                    _buildErrorBanner(authState.errorMessage!),

                  const SizedBox(height: 28),

                  // Login Button
                  _animated(
                    3,
                    AppButton(
                      label: 'Iniciar sesión',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onLogin,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  _animated(4, _buildDivider()),

                  const SizedBox(height: 28),

                  // Register Link
                  _animated(4, _buildRegisterLink()),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini logo
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(
            child: Text('\$', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 24),
        Text('Bienvenido de\nvuelta 👋', style: AppTextStyles.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para continuar con tus finanzas',
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

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.surfaceLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('¿No tienes cuenta?', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.surfaceLight)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return AppButton(
      label: 'Crear cuenta gratis',
      isOutlined: true,
      onPressed: () {
        ref.read(authProvider.notifier).resetState();
        context.goNamed('register');
      },
    );
  }
}