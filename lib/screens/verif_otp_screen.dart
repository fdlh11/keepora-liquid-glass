import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/otp_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class VerifOtpScreen extends StatefulWidget {
  const VerifOtpScreen({super.key});

  @override
  State<VerifOtpScreen> createState() => _VerifOtpScreenState();
}

class _VerifOtpScreenState extends State<VerifOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final OtpService _otpService = OtpService();
  bool _isLoading = false;

  String get _email =>
      (ModalRoute.of(context)?.settings.arguments as String?) ?? '';

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      showTopNotif(
        context,
        'Silakan masukkan 6 digit kode OTP secara lengkap.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _otpService.verifyOtp(_email, otp);
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/passwordBaru',
          arguments: _email,
        );
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

  Future<void> _handleResend() async {
    if (_email.isEmpty) return;

    try {
      await _otpService.sendOtpToEmail(_email);
      if (mounted) {
        showTopNotif(
          context,
          'Kode OTP baru telah dikirim ulang ke email Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.76) : const Color(0xFF334155);
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
                          Icons.chat_bubble_outline_rounded,
                          size: 60,
                          color: accentBlue,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Masukkan Kode OTP',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan 6 digit kode OTP yang telah dikirimkan ke email Anda.',
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
                        'Masukkan Kode 6 digit OTP',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return LiquidGlassSurface(
                            width: 44,
                            height: 50,
                            borderRadius: 12,
                            blurSigma: 10,
                            enableShadow: false,
                            child: Center(
                              child: TextField(
                                controller: _controllers[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    FocusScope.of(context).nextFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    FocusScope.of(context).previousFocus();
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: GestureDetector(
                          onTap: _handleResend,
                          child: Text(
                            'Tidak menerima kode? Kirim Ulang',
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
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
                        onPressed: _handleVerify,
                        child: Text(
                          'Verifikasi Kode',
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