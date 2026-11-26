import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/otp_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
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
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.76) : const Color(0xFF334155);
    final hintColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);
    final accentBlue = isDark ? const Color(0xFF93C5FD) : primaryBlue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: LiquidGlassSurface(
            borderRadius: 14,
            blurSigma: 14,
            padding: const EdgeInsets.all(6),
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 20),
          ),
        ),
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      LiquidGlassSurface(
                        borderRadius: 30,
                        blurSigma: 18,
                        tintColor: primaryBlue,
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          Icons.verified_outlined,
                          size: 60,
                          color: accentBlue,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Masukkan Password Baru',
                        textAlign: TextAlign.center,
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
                const SizedBox(height: 32),
                LiquidGlassSurface(
                  borderRadius: 24,
                  blurSigma: 18,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Baru',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 10,
                        enableShadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          scrollPadding: const EdgeInsets.only(bottom: 140),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan password baru...',
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      LiquidGlassButton(
                        width: double.infinity,
                        height: 52,
                        borderRadius: 16,
                        tintColor: primaryBlue,
                        foregroundColor: isDark ? Colors.white : primaryBlue,
                        isLoading: _isLoading,
                        onPressed: _handleSavePassword,
                        child: Text(
                          'Simpan Password',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}