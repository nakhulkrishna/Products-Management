import 'package:flutter/material.dart';



class AppColors {
  // Light Theme - very soft, gentle colors
  static const lightBackground = Color(0xFFF2F2F2); // Gentle gray
  static const lightCard = Color(0xFFF9F9F9);       // Very soft off-white
  static const lightText = Color(0xFF3A3A3A);       // Soft dark gray, easy on eyes
  static const lightSubText = Color(0xFF7A7A7A);    // Light gray for secondary text

  // Dark Theme - keep as is
  static const darkBackground = Color(0xFF121212);
  static const darkCard = Color(0xFF1E1E1E);
  static const darkText = Color(0xFFE0E0E0);        // Softer white
  static const darkSubText = Color(0xFFB0B0B0);     // Softer gray
}




class TabletColors {
  // Primary & Accent Colors
  static const primaryRed = Color(0xFFD80032);   // Strong red
  static const secondaryRed = Color(0xFFEF233C); // Lighter red / accent

  // Backgrounds
  static const lightBackground = Color(0xFFEDF2F4); // Very light gray / soft background
  static const darkBackground = Color(0xFF2B2D42);  // Dark blue / tablet dark mode background

  // Text / Subtext
  static const lightText = Color(0xFF2B2D42);   // Dark blue for text on light bg
  static const subText = Color(0xFF8D99AE);     // Grayish-blue for secondary text
}
