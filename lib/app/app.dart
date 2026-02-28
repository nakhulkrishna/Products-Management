import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_catelogs/core/constants/app_strings.dart';
import 'package:products_catelogs/core/theme/app_theme.dart';
import 'package:products_catelogs/features/auth/application/auth_providers.dart';
import 'package:products_catelogs/features/auth/presentation/pages/auth_gate.dart';

class ProductsCatalogApp extends ConsumerWidget {
  const ProductsCatalogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,
      locale: preferences.locale,
      home: const AuthGate(),
    );
  }
}
