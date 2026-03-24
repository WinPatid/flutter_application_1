// ไฟล์: lib/main.dart
import 'package:flutter/material.dart';

// นำเข้าไฟล์หน้าจอหลักจากโฟลเดอร์ screens
import 'screens/node_assist_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056B3),
          background: const Color(0xFFF4F6F8),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const NodeAssistScreen(), // เรียกใช้หน้าจอที่เราแยกไฟล์ไว้
    );
  }
}