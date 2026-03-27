import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ScaleFlowApp());
}

class ScaleFlowApp extends StatelessWidget {
  const ScaleFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
