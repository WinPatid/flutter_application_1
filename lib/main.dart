// ไฟล์: lib/main.dart
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const NodeAssistApp());
}

class NodeAssistApp extends StatelessWidget {
  const NodeAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node Assist PRO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}