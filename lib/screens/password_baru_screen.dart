import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/otp_service.dart';
import '../utils/top_notif.dart';

class PasswordBaruScreen extends StatefulWidget {
  const PasswordBaruScreen({super.key});

  @override
  State<PasswordBaruScreen> createState() => _PasswordBaruScreenState();
}

class _PasswordBaruScreenState extends State<PasswordBaruScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final OtpService _otpService = OtpService();
  bool _obscureText = true;
  bool _isLoading = false;

  String get _email =>
      (ModalRoute.of(context)?.settings.arguments as String?) ?? '';

  Future<void> _handleSavePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 6) {
      showTopNotif(
        context,
        'Password baru minimal harus terdiri dari 6 karakter.',
        isError: true,
      );
      return;
    }

    if (_email.isEmpty) {
      showTopNotif(
        context,
        'Sesi email tidak ditemukan. Silakan ulangi dari awal.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _otpService.updatePasswordWithOtp(_email, newPassword);

      if (mounted) {
        showTopNotif(
          context,
          'Password baru berhasil disimpan! Silakan masuk.',
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0056C6);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.black54;
    final fieldFillColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.black38;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.black45;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 80,
                      color: textPrimary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Masukkan Password Baru',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat password baru yang kuat dan mudah Anda ingat untuk akun Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Password Baru',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Masukkan password baru...',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: fieldFillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: iconColor,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 12.0,
            bottom: 24.0 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSavePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Simpan Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}