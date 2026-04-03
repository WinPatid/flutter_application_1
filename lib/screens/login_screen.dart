// ไฟล์: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme.dart';
import 'node_assist_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  void _handleLogin() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    await Future.delayed(const Duration(milliseconds: 1200));

    if (_usernameCtrl.text == 'admin' && _passwordCtrl.text == 'admin') {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const NodeAssistScreen(),
          transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
      }
    } else {
      setState(() {
        _errorMessage = 'Access Denied. Invalid credentials.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(children: [

        // ─── Left: Banner ───
        Expanded(flex: 5, child: Container(
          color: AppColors.sidebarBg,
          child: Stack(children: [
            Positioned.fill(child: Opacity(opacity: 0.06,
              child: GridPaper(color: Colors.white, interval: 100, divisions: 2, subdivisions: 1))),
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              // SVG Logo
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 140,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),

              const SizedBox(height: 32),
              const Text('United Information Highway co. ltd', style: TextStyle(
                color: Colors.blueAccent, fontSize: 13,
                letterSpacing: 4, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('NODE ASSIST PRO', style: TextStyle(
                color: Colors.white, fontSize: 36,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(
                'Enterprise Network Provisioning & Reservation System.\nAuthorized personnel only.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ])),
          ]),
        )),

        // ─── Right: Login Form ───
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

                Align(alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
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
          )),
        )),
      ]),
    );
  }
}