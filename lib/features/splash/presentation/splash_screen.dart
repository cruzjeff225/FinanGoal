import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo: scale + fade
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Texto: fade + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    // 1. Logo entra
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // 2. Texto aparece
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // 3. Barra de progreso
    await Future.delayed(const Duration(milliseconds: 400));
    _progressController.forward();

    // 4. Redirigir a login
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      context.goNamed('login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Fondo decorativo: círculos
            _buildBackgroundDecoration(),

            // Contenido principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado
                  _buildLogo(),

                  const SizedBox(height: 20),

                  // Nombre de la app
                  _buildAppName(),

                  const SizedBox(height: 8),

                  // Tagline
                  _buildTagline(),
                ],
              ),
            ),

            // Barra de progreso inferior
            Positioned(
              bottom: 60,
              left: 48,
              right: 48,
              child: _buildProgressBar(),
            ),

            // Version tag
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text('v1.0.0', style: AppTextStyles.caption),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        // Círculo superior izquierdo
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.06),
            ),
          ),
        ),
        // Círculo inferior derecho
        Positioned(
          bottom: -100,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.04),
            ),
          ),
        ),
        // Punto de acento
        Positioned(
          top: 120,
          right: 40,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
            ),
          ),
        ),
        Positioned(
          bottom: 180,
          left: 30,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '₡',
                  style: TextStyle(
                    fontSize: 52,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textOpacity,
          child: SlideTransition(
            position: _textSlide,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Finan',
                    style: AppTextStyles.logoTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: 'Goal',
                    style: AppTextStyles.logoTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textOpacity,
          child: SlideTransition(
            position: _textSlide,
            child: Text(
              'TUS FINANZAS · TU FUTURO',
              style: AppTextStyles.logoSubtitle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _progressValue.value,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 3,
              ),
            ),
          ],
        );
      },
    );
  }
}