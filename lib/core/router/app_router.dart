import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finan_goal/features/splash/presentation/splash_screen.dart';
import 'package:finan_goal/features/auth/presentation/login_screen.dart';
import 'package:finan_goal/features/auth/presentation/register_screen.dart';
import 'package:finan_goal/features/home/presentation/home_screen.dart';
import 'package:finan_goal/features/analytics/presentation/analytics_screen.dart';
import 'package:finan_goal/features/profile/presentation/profile_screen.dart';
import 'package:finan_goal/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:finan_goal/features/transaction/presentation/add_transaction_sheet.dart';

class AppRouter {
  AppRouter._();

  // Transición slide horizontal estilo iOS
  static CustomTransitionPage _iosSlide<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    bool fromRight = true,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Pantalla entrante — slide desde la derecha
        final enterTween = Tween<Offset>(
          begin: fromRight ? const Offset(1, 0) : const Offset(-1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        // Pantalla saliente — slide leve hacia la izquierda (efecto iOS)
        final exitTween = Tween<Offset>(
          begin: Offset.zero,
          end: fromRight ? const Offset(-0.25, 0) : const Offset(0.25, 0),
        ).chain(CurveTween(curve: Curves.easeInCubic));

        return SlideTransition(
          position: animation.drive(enterTween),
          child: SlideTransition(
            position: secondaryAnimation.drive(exitTween),
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (c, s) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (c, s) => _iosSlide(
          context: c, state: s, child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (c, s) => _iosSlide(
          context: c, state: s, child: const RegisterScreen(),
        ),
      ),

      // Shell para navegación persistente
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                // Detectamos la dirección del deslizamiento
                if ((details.primaryVelocity ?? 0).abs() < 400) return;
                
                int direction = details.primaryVelocity! > 0 ? -1 : 1;
                int nextIndex = navigationShell.currentIndex + direction;

                // Saltamos el botón central (índice 2)
                if (nextIndex == 2) nextIndex += direction;

                if (nextIndex >= 0 && nextIndex <= 4) {
                  navigationShell.goBranch(nextIndex);
                }
              },
              child: navigationShell,
            ),
            extendBody: true,
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                if (index == 2) {
                  AddTransactionSheet.show(context);
                  return;
                }
                navigationShell.goBranch(index);
              },
            ),
          );
        },
        branches: [
          // Index 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (c, s) => const HomeScreen(),
              ),
            ],
          ),
          // Index 1: Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                name: 'analytics',
                builder: (c, s) => const AnalyticsScreen(),
              ),
            ],
          ),
          // Index 2: Placeholder para el FAB
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/placeholder',
                builder: (c, s) => const SizedBox(),
              ),
            ],
          ),
          // Index 3: Goals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                name: 'goals',
                builder: (c, s) => const Center(child: Text('Metas - Proximamente')),
              ),
            ],
          ),
          // Index 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (c, s) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}