// ไฟล์: lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../core/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;
  final _userCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Timer state
  int _countdown = 60;
  Timer? _timer;

  // Password Validation state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void dispose() {
    _timer?.cancel();
    _userCtrl.dispose();
    _pinCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
    });
  }

  void _handleReset() async {
    if (!_hasMinLength || !_hasUppercase || !_hasNumber) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Passwords do not match!'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // จำลองการโหลดส่ง API
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Password reset successful!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // เด้งกลับไปหน้า Login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(children: [

        // ─── Left: Banner (ปรับให้เหมือนหน้า Login) ───
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
              const Text('ACCOUNT RECOVERY PORTAL', style: TextStyle(
                color: Colors.white, fontSize: 32,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(
                'Secure password reset system.\nEnsure you have access to your registered email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            ])),
          ]),
        )),

        // ─── Right: Recovery Form ───
        Expanded(flex: 4, child: Container(
          color: Colors.white,
          child: Center(child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text('Back to Login', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

                Text(
                  _step == 1 ? 'Forgot Password?' : _step == 2 ? 'Security Verification' : 'Create New Password',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                ),
                const SizedBox(height: 8),

                // ── STEP 1: Username ──
                if (_step == 1) ...[
                  Text('Enter your username or Employee ID to receive a reset PIN.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  const SizedBox(height: 40),
                  
                  AppWidgets.formField(
                    label: 'Username / Employee ID',
                    field: TextField(
                      controller: _userCtrl,
                      decoration: AppInputDecoration.standard(
                        hint: 'e.g., admin',
                        prefix: const Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_userCtrl.text.isEmpty) return;
                        setState(() => _step = 2);
                        _startTimer();
                      },
                      style: AppButtonStyles.primary(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Send Reset PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                // ── STEP 2: PIN/OTP ──
                if (_step == 2) ...[
                  RichText(text: TextSpan(style: TextStyle(fontSize: 14, color: Colors.grey.shade500), children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(text: '${_userCtrl.text.substring(0, 1)}***@uih.co.th', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ])),
                  const SizedBox(height: 40),
                  
                  TextField(
                    controller: _pinCtrl, keyboardType: TextInputType.number, maxLength: 6,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, letterSpacing: 24, fontWeight: FontWeight.bold),
                    decoration: AppInputDecoration.standard(
                      hint: '000000',
                    ).copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pinCtrl.text.length == 6) setState(() => _step = 3);
                      },
                      style: AppButtonStyles.primary(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TextButton(
                      onPressed: _countdown == 0 ? _startTimer : null,
                      child: Text(_countdown > 0 ? 'Resend code in ${_countdown}s' : 'Resend Code',
                        style: TextStyle(color: _countdown > 0 ? AppColors.textMuted : AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                // ── STEP 3: New Password ──
                if (_step == 3) ...[
                  Text('Your new password must be different from previous used passwords.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 32),
                  
                  AppWidgets.formField(
                    label: 'New Password',
                    field: TextField(
                      controller: _newPassCtrl, obscureText: _obscureNew, onChanged: _validatePassword,
                      decoration: AppInputDecoration.standard(
                        hint: '••••••••',
                        prefix: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                        suffix: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Password Rules Indicator
                  _buildRequirementRule('At least 8 characters', _hasMinLength),
                  const SizedBox(height: 6),
                  _buildRequirementRule('Contains an uppercase letter', _hasUppercase),
                  const SizedBox(height: 6),
                  _buildRequirementRule('Contains a number', _hasNumber),
                  const SizedBox(height: 24),

                  AppWidgets.formField(
                    label: 'Confirm Password',
                    field: TextField(
                      controller: _confirmPassCtrl, obscureText: _obscureConfirm,
                      decoration: AppInputDecoration.standard(
                        hint: '••••••••',
                        prefix: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                        suffix: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleReset,
                      style: AppButtonStyles.primary(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                
              ],
            ),
          )),
        )),
      ]),
    );
  }

  Widget _buildRequirementRule(String text, bool isMet) {
    return Row(
      children: [
        Icon(isMet ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: isMet ? Colors.green : AppColors.textMuted),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: isMet ? Colors.green.shade700 : AppColors.textMuted)),
      ],
    );
  }
}