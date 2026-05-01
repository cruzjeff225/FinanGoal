import 'package:flutter/material.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Login — Fase 2',
          style: AppTextStyles.displayMedium,
        ),
      ),
    );
  }
}