// ไฟล์: lib/main.dart
import 'package:flutter/material.dart';

// นำเข้าไฟล์หน้า Login ที่เพิ่งสร้างใหม่
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056B3),
          background: const Color(0xFFF4F6F8),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      // 🚀 จุดที่เปลี่ยน: สั่งให้แอพเริ่มเปิดที่หน้า LoginScreen แทน
      home: const LoginScreen(), 
    );
  }
}