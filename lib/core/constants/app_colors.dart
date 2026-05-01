import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primarios
  static const Color primary = Color(0xFF00C896);
  static const Color primaryLight = Color(0xFF33D9A8);
  static const Color primaryDark = Color(0xFF00A07A);

  // Fondos
  static const Color background = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF1A2E42);
  static const Color surfaceLight = Color(0xFF243D54);

  // Acento
  static const Color accent = Color(0xFFF5C842);

  // Texto
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8FA3B1);
  static const Color textHint = Color(0xFF4D6475);

  // Estados
  static const Color success = Color(0xFF00C896);
  static const Color error = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFF5C842);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C896), Color(0xFF00A07A)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1B2A), Color(0xFF0A1520)],
  );
}