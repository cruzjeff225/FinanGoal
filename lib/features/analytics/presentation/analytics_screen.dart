import 'package:flutter/material.dart';
import 'package:finan_goal/core/constants/app_colors.dart';
import 'package:finan_goal/core/constants/app_text_styles.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Analiticas — Proximamente',
          style: AppTextStyles.displayMedium,
        ),
      ),
    );
  }
}

