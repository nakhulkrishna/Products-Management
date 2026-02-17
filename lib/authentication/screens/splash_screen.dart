import 'package:flutter/material.dart';
import 'package:products_catelogs/authentication/provider/authentication_provider.dart';
import 'package:products_catelogs/authentication/screens/authentication_screen.dart';
import 'package:products_catelogs/authentication/screens/reg.dart';
import 'package:products_catelogs/dashboard/screen/dash_board_reponsive.dart';
import 'package:products_catelogs/theme/colors.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeFromSplash();
  }

  Future<void> _routeFromSplash() async {
    final userProvider = context.read<UserProvider>();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final destination = await userProvider.resolveStartupDestination();
    if (!mounted) return;

    late final Widget page;
    switch (destination) {
      case AuthStartDestination.dashboard:
        page = const ResponsiveDashboard();
        break;
      case AuthStartDestination.registration:
        page = const RegistrationScreen();
        break;
      case AuthStartDestination.login:
        page = const LoginScreen();
        break;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topColor = AppColors.brandRed.withValues(alpha: 0.20);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, theme.scaffoldBackgroundColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 52,
                color: AppColors.brandRed,
              ),
              const SizedBox(height: 14),
              Text(
                "Red Rose Admin",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.brandRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
