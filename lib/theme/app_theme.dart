import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFFF8FAFC),
    primaryColor: Color(0xFF3B82F6),
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 16),
      bodySmall: TextStyle(fontSize: 13, color: Colors.grey),
    ),
  );
}