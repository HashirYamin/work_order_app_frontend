import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/splash/splash_screen.dart';

class WorkOrderApp extends StatelessWidget {
  const WorkOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Order App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}