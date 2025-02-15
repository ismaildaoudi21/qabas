import 'package:flutter/material.dart';
import 'package:qabas/utils/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Tajwal',
      primaryColor: AppColors.orange1,
      textTheme: const TextTheme().apply(
        fontFamily: 'Tajwal',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: 'Tajwal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}