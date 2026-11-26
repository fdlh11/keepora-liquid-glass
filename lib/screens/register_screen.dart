import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emailFocus.addListener(() => _scrollToFocused(animate: true));
    _passwordFocus.addListener(() => _scrollToFocused(animate: true));
    _confirmPasswordFocus.addListener(() => _scrollToFocused(animate: true));
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scrollToFocused(animate: false);
  }

  void _scrollToFocused({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusNode? active;
      if (_confirmPasswordFocus.hasFocus) {
        active = _confirmPasswordFocus;
      } else if (_passwordFocus.hasFocus) {
        active = _passwordFocus;
      } else if (_emailFocus.hasFocus) {
        active = _emailFocus;
      }

      if (active?.context != null) {
        Scrollable.ensureVisible(
          active!.context!,
          alignment: 0.45,
          duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }

  void _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty && password.isEmpty && confirmPassword.isEmpty) {
      showTopNotif(
        context,
        'Harap isi Email, Password, dan Konfirmasi Password terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (email.isEmpty) {
      showTopNotif(
        context,
        'Email tidak boleh kosong.',
        isError: true,
      );
      _emailFocus.requestFocus();
      return;
    }

    if (!_isValidEmail(email)) {
      showTopNotif(
        context,
        'Gunakan format email asli yang valid.',
        isError: true,
      );
      _emailFocus.requestFocus();
      return;
    }

    if (password.isEmpty) {
      showTopNotif(
        context,
        'Password tidak boleh kosong.',
        isError: true,
      );
      _passwordFocus.requestFocus();
      return;
    }

    if (password.length < 6) {
      showTopNotif(
        context,
        'Password minimal 6 karakter.',
        isError: true,
      );
      _passwordFocus.requestFocus();
      return;
    }

    if (confirmPassword.isEmpty) {
      showTopNotif(
        context,
        'Konfirmasi password tidak boleh kosong.',
        isError: true,
      );
      _confirmPasswordFocus.requestFocus();
      return;
    }

    if (password != confirmPassword) {
      showTopNotif(
        context,
        'Konfirmasi password tidak cocok dengan password Anda.',
        isError: true,
      );
      _confirmPasswordFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _authService.signUp(email: email, password: password);
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        const primaryBlue = Color(0xFF004AAD);
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.45),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (dialogContext, _, _) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  color: Colors.transparent,
                  child: LiquidGlassSurface(
                    borderRadius: 24,
                    blurSigma: 22,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pendaftaran Berhasil!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tautan verifikasi telah dikirimkan ke alamat Email Anda. Silakan periksa inbox atau spam Email Anda untuk memverifikasi akun sebelum masuk.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.78)
                                : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 20),
                        LiquidGlassButton(
                          width: double.infinity,
                          height: 46,
                          borderRadius: 14,
                          tintColor: primaryBlue,
                          foregroundColor: isDark ? Colors.white : primaryBlue,
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (_, anim, _, child) => BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 4 * anim.value,
              sigmaY: 4 * anim.value,
            ),
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.76) : const Color(0xFF334155);
    final textMuted =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              22.0,
              14.0,
              22.0,
              isKeyboardOpen ? 100.0 : 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: LiquidGlassSurface(
                          borderRadius: 34,
                          blurSigma: 18,
                          tintColor: primaryBlue,
                          padding: const EdgeInsets.all(18),
                          child: Image.asset(
                            'assets/image/logo.png',
                            width: 135,
                            height: 135,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 14,
                        padding: const EdgeInsets.all(9),
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                LiquidGlassSurface(
                  borderRadius: 26,
                  blurSigma: 20,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Akun',
                        style: GoogleFonts.montserrat(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan daftar untuk mulai mengelola barang pribadi Anda',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      Text(
                        'Email',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 10,
                        enableShadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan Email Anda...',
                            hintStyle: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      Text(
                        'Password',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 10,
                        enableShadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan Password Anda...',
                            hintStyle: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 44,
                            ),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Konfirmasi Password
                      Text(
                        'Konfirmasi Password',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 10,
                        enableShadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRegister(),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Konfirmasi Password Anda...',
                            hintStyle: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 44,
                            ),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
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
                        onPressed: _handleRegister,
                        child: Text(
                          'Daftar',
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