// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color pastelMint = Color(0xFFA8E6CF);
  static const Color pastelSoft = Color(0xFFDCEDC1);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color text = Color(0xFF333333);
  static const Color muted = Color(0xFF6B705C);
  static const Color cardShadow = Color(0x1A000000);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.pastelMint,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pastelMint,
        primary: AppColors.pastelMint,
        secondary: AppColors.pastelSoft,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pastelMint,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 15, color: AppColors.text),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.pastelMint,
        secondary: AppColors.pastelSoft,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pastelMint,
        foregroundColor: Colors.black87,
      ),
    );
  }
}
