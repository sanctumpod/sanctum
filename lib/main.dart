import 'package:flutter/material.dart';
import 'package:sanctum/screens/login_screen.dart';

void main() {
  runApp(const SanctumApp());
}

class SanctumApp extends StatelessWidget {
  const SanctumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanctum',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginScreen(),
    );
  }
}
