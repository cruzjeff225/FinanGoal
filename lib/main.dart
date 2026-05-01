import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finan_goal/core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Barra de estado transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1B2A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Bloquear orientación a portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: FinanGoalApp(),
    ),
  );
}

class FinanGoalApp extends StatelessWidget {
  const FinanGoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FinanGoal',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C896),
          surface: Color(0xFF1A2E42),
          background: Color(0xFF0D1B2A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    );
  }
}