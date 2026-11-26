import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emailFocus.addListener(() => _scrollToFocused(animate: true));
    _passwordFocus.addListener(() => _scrollToFocused(animate: true));
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scrollToFocused(animate: false);
  }

  void _scrollToFocused({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final FocusNode? active = _passwordFocus.hasFocus
          ? _passwordFocus
          : (_emailFocus.hasFocus ? _emailFocus : null);

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

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showTopNotif(
        context,
        'Silakan isi email dan password Anda.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
    final accentBlue = isDark ? const Color(0xFF93C5FD) : primaryBlue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              22.0,
              16.0,
              22.0,
              isKeyboardOpen ? 100.0 : 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Center(
                  child: LiquidGlassSurface(
                    borderRadius: 36,
                    blurSigma: 18,
                    tintColor: primaryBlue,
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/image/logo.png',
                      width: 145,
                      height: 145,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LiquidGlassSurface(
                  borderRadius: 26,
                  blurSigma: 20,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang',
                        style: GoogleFonts.montserrat(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan masuk untuk mengelola barang pribadi Anda',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Email
                      Text(
                        'Email',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
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
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      Text(
                        'Password',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
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
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan Password Anda...',
                            hintStyle: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            suffixIcon: IconButton(
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/LupaPassword');
                          },
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: accentBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LiquidGlassButton(
                        width: double.infinity,
                        height: 52,
                        borderRadius: 16,
                        tintColor: primaryBlue,
                        foregroundColor: isDark ? Colors.white : primaryBlue,
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                        child: Text(
                          'Masuk',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text.rich(
                        TextSpan(
                          text: 'Belum Punya Akun? ',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Register!',
                              style: TextStyle(
                                color: accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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