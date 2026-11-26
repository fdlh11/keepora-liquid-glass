import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/liquid_glass_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  static const String _onboardingPrefKey = 'keepora_has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.emailVerified) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool(_onboardingPrefKey) ?? false;

    if (!mounted) return;
    if (hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.78) : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LiquidGlassSurface(
                    borderRadius: 44,
                    blurSigma: 22,
                    tintColor: primaryBlue,
                    padding: const EdgeInsets.all(28),
                    child: Image.asset(
                      'assets/image/logo.png',
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Keepora',
                    style: GoogleFonts.montserrat(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mengelola Barang Pribadi Anda Dalam Satu Aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}