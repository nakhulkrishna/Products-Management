import 'package:flutter/material.dart';
import 'package:products_catelogs/theme/colors.dart';

class AppTheme {
  static const _lightScheme = ColorScheme.light(
    primary: AppColors.brandRed,
    secondary: AppColors.brandRedDark,
    surface: AppColors.lightCard,
    error: AppColors.danger,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.lightText,
    onError: Colors.white,
  );

  static const _darkScheme = ColorScheme.dark(
    primary: AppColors.brandRed,
    secondary: AppColors.brandRedDark,
    surface: AppColors.darkCard,
    error: AppColors.danger,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.darkText,
    onError: Colors.white,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    canvasColor: AppColors.lightBackground,
    dividerColor: AppColors.lightBorder,
    splashColor: AppColors.brandRed.withAlpha(18),
    highlightColor: AppColors.brandRed.withAlpha(10),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.brandRed,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
      bodyLarge: TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(
        color: AppColors.lightSubText,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: AppColors.lightSubText,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: AppColors.lightBorder),
      backgroundColor: AppColors.lightMutedSurface,
      selectedColor: AppColors.brandRedSoft,
      labelStyle: const TextStyle(
        color: AppColors.lightSubText,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.brandRed,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.lightText,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      textStyle: const TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      labelStyle: const TextStyle(color: AppColors.lightSubText),
      hintStyle: const TextStyle(
        color: AppColors.lightSubText,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: AppColors.lightSubText,
      suffixIconColor: AppColors.lightSubText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brandRed, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.brandRed.withAlpha(100),
        disabledForegroundColor: Colors.white.withAlpha(200),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightText,
        side: const BorderSide(color: AppColors.lightBorder),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandRed,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandRed,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.lightText),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.lightSubText,
      textColor: AppColors.lightText,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: AppColors.lightBorder, width: 1.4),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandRed;
        }
        return Colors.white;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.lightSubText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    dividerColor: const Color(0xFF2A2A2F),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E23),
      labelStyle: const TextStyle(color: AppColors.darkSubText),
      hintStyle: const TextStyle(color: AppColors.darkSubText),
      prefixIconColor: AppColors.darkSubText,
      suffixIconColor: AppColors.darkSubText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2F2F34)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2F2F34)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brandRed, width: 1.2),
      ),
    ),
  );
}
