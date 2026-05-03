import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const AppWrapper(),
    );
  }
}

/// ================= WRAPPER (WEB + MOBILE) =================

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final width = MediaQuery.of(context).size.width;

    /// 👉 Desktop web layout
    if (isWeb && width > 800) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: const DashboardScreen(),
          ),
        ),
      );
    }

    /// 👉 Mobile / tablet
    return const DashboardScreen();
  }
}