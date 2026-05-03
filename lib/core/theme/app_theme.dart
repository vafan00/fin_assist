import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: const Color.fromARGB(255, 105, 212, 137),
    primaryColor: const Color.fromARGB(255, 28, 167, 0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(0, 0, 0, 0),
      elevation: 0,
      foregroundColor: Colors.black,
    ),
  );
}