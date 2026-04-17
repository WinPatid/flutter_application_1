// ไฟล์: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'node_assist_screen.dart';
import 'forgot_password_screen.dart'; // 📍 จุดที่ 1: เพิ่ม Import ตรงนี้ครับ

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api             = ApiService();
  final _usernameCtrl    = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  bool  _obscure         = true;
  bool  _loading         = false;
  String _error          = '';

  Future<void> _handleLogin() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'กรอก Username และ Password ด้วย');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    final result = await _api.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;

    if (result != null && result['error'] == null) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => NodeAssistScreen(currentUser: result),
        transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    } else {
      setState(() { _error = result?['error'] ?? 'Login ไม่สำเร็จ'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(children: [
        Expanded(flex: 5, child: Container(
          color: const Color(0xFF212529),
          child: Stack(children: [
            Positioned.fill(child: Opacity(opacity: 0.1,
              child: GridPaper(color: Colors.white, interval: 100, divisions: 2, subdivisions: 1))),
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
        Expanded(flex: 4, child: Container(
          color: Colors.white,
          child: Center(child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 40),
<<<<<<< HEAD
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Text('System Login', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Please enter your credentials to access the portal.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 40),

                // Error
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMessage,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                    ]),
                  ),

                // Username
                AppWidgets.formField(
                  label: 'Username',
                  field: TextField(
                    controller: _usernameCtrl,
                    decoration: AppInputDecoration.standard(
                      hint: 'e.g., admin',
                      prefix: const Icon(Icons.person_outline,
                        color: AppColors.textMuted, size: 20)),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                AppWidgets.formField(
                  label: 'Password',
                  field: TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: AppInputDecoration.standard(
                      hint: '••••••••',
                      prefix: const Icon(Icons.lock_outline,
                        color: AppColors.textMuted, size: 20),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted, size: 20),
                        onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 📍 จุดที่ 2: แก้ตรงปุ่มให้กดแล้วเด้งไปหน้า ForgotPasswordScreen ครับ
                Align(alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text('Forgot Password?',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: AppButtonStyles.primary(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
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
=======
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('System Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF212529))),
              const SizedBox(height: 8),
              Text('Please enter your credentials to access the portal.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 40),
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20), const SizedBox(width: 10),
                    Expanded(child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ])),
              const Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
              const SizedBox(height: 8),
              TextField(controller: _usernameCtrl, onSubmitted: (_) => _handleLogin(),
                decoration: InputDecoration(
                  hintText: 'e.g., admin', prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                  filled: true, fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2)))),
              const SizedBox(height: 20),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
              const SizedBox(height: 8),
              TextField(controller: _passwordCtrl, obscureText: _obscure, onSubmitted: (_) => _handleLogin(),
                decoration: InputDecoration(
                  hintText: '••••••••', prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
                  filled: true, fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0056B3), width: 2)))),
              const SizedBox(height: 32),
              SizedBox(height: 50, child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Sign In to Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 40),
              const Text('© 2026 Node Assist Pro. All rights reserved.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
>>>>>>> e9e593148938bd62a592a983205949784f35b82c
          )),
        )),
      ]),
    );
  }
}