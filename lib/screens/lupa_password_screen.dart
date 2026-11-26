import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/otp_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class LupaPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const LupaPasswordScreen({
    super.key,
    this.initialEmail,
  });

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen> {
  late final TextEditingController _emailController;
  final OtpService _otpService = OtpService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  void _handleSendReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      showTopNotif(
        context,
        'Silakan masukkan alamat email Anda yang valid.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _otpService.sendOtpToEmail(email);
      if (mounted) {
        showTopNotif(
          context,
          'Kode OTP 6 digit telah dikirimkan ke email Anda.',
        );
        Navigator.pushNamed(context, '/verifOTP', arguments: email);
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
    _emailController.dispose();
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
                          Icons.warning_amber_rounded,
                          size: 64,
                          color: accentBlue,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Lupa Password?',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Masukkan Email akun Anda untuk menerima kode OTP pemulihan password.',
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
                        'Email',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 10,
                        enableShadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          scrollPadding: const EdgeInsets.only(bottom: 140),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan Email Anda...',
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
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
                        onPressed: _handleSendReset,
                        child: Text(
                          'Verifikasi Email',
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