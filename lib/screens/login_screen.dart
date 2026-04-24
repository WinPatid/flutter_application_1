// ไฟล์: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'node_assist_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api             = ApiService();
  final _usernameCtrl    = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  bool  _obscurePassword = true;
  bool  _isLoading       = false;
  String _errorMessage   = '';

  Future<void> _handleLogin() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'กรอก Username และ Password ด้วย');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    // จำลองเวลาโหลดให้ดูเนียนๆ 1 วินาที
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 📍 เช็คเงื่อนไขจากฝั่ง Frontend (ใช้ admin / admin)
    if (_usernameCtrl.text.trim() == 'admin' && _passwordCtrl.text == 'admin') {
      
      // สร้างข้อมูล User จำลองเพื่อส่งเข้าไปให้ระบบข้างในทำงานได้
      final mockUser = {
        'id': '999',
        'name': 'Win (Admin)',
        'username': 'admin',
        'roleName': 'Manager',
        'error': null,
      };

      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => NodeAssistScreen(currentUser: mockUser),
        transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    } else {
      // ถ้าพิมพ์ผิด
      setState(() { 
        _errorMessage = 'Username หรือ Password ไม่ถูกต้อง (ให้ลองใช้ admin / admin)'; 
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(children: [
        // ฝั่งซ้าย (Branding)
        Expanded(flex: 5, child: Container(
          color: const Color(0xFF212529),
          child: Stack(children: [
            Positioned.fill(child: Opacity(opacity: 0.1,
              child: const GridPaper(color: Colors.white, interval: 100, divisions: 2, subdivisions: 1))),
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.hub_outlined, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text('NETWORK INTELLIGENCE', style: TextStyle(color: Colors.blueAccent, fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('NODE ASSIST PRO', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
              SizedBox(height: 20),
              Padding(padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text('Enterprise Network Provisioning & Reservation System.\nAuthorized personnel only.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14))),
            ])),
          ]),
        )),
        // ฝั่งขวา (Login Form)
        Expanded(flex: 4, child: Container(
          color: Colors.white,
          child: Center(child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Text('System Login', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))), // ใช้สีแทน AppColors.textPrimary
                const SizedBox(height: 8),
                Text('Please enter your credentials to access the portal.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 40),

                // Error Message Box
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50, // แทน AppColors.dangerLight
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300)),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMessage,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                    ]),
                  ),

                // Username Field
                const Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g., admin',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password Link
                Align(alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text('Forgot Password?',
                      style: TextStyle(color: Color(0xFF0056B3), fontSize: 13)), // แทน AppColors.primary
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056B3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In to Portal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 40),
                Text('© 2026 Node Assist Pro. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          )),
        )),
      ]),
    );
  }
}