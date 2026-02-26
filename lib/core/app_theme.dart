import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFEC2227);
  static const Color darkGrey = Color(0xFF212529);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryRed,
      scaffoldBackgroundColor: AppColors.darkGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGrey,
        elevation: 0,
      ),
      // Add more theme definitions as needed by the UI
    );
  }
}
