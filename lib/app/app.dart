import 'package:flutter/material.dart';
import 'package:products_catelogs/core/constants/app_strings.dart';
import 'package:products_catelogs/core/theme/app_theme.dart';
import 'package:products_catelogs/features/auth/presentation/pages/auth_gate.dart';

class ProductsCatalogApp extends StatelessWidget {
  const ProductsCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
