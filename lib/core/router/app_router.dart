import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/features/splash/presentation/splash_screen.dart';
import 'package:finan_goal/features/auth/presentation/login_screen.dart';
import 'package:finan_goal/features/auth/presentation/register_screen.dart';
import 'package:finan_goal/features/home/presentation/home_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}