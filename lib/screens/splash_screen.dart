import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF004AAD),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/image/logo.png',
                width: 260,
                height: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Nama Aplikasi
              Text(
                'Keepora',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Mengelola Barang Pribadi Anda Dalam Satu Aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}