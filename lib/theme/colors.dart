import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const brandRed = Color(0xFFD61F2C);
  static const brandRedDark = Color(0xFFAB1621);
  static const brandRedSoft = Color(0xFFFFE7EA);

  // Light palette (primary mode)
  static const lightBackground = Color(0xFFF8F8FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightMutedSurface = Color(0xFFF2F2F6);
  static const lightBorder = Color(0xFFE7E7ED);
  static const lightText = Color(0xFF19171C);
  static const lightSubText = Color(0xFF6F6A75);

  // Semantic helpers
  static const success = Color(0xFF138A4B);
  static const warning = Color(0xFFCC7A00);
  static const danger = Color(0xFFC42033);

  // Dark palette (kept for compatibility)
  static const darkBackground = Color(0xFF111113);
  static const darkCard = Color(0xFF1A1A1D);
  static const darkText = Color(0xFFF3F3F5);
  static const darkSubText = Color(0xFFB7B7BD);
}

class TabletColors {
  static const primaryRed = AppColors.brandRed;
  static const secondaryRed = AppColors.brandRedDark;
  static const lightBackground = AppColors.lightBackground;
  static const darkBackground = AppColors.darkBackground;
  static const lightText = AppColors.lightText;
  static const subText = AppColors.lightSubText;
}
