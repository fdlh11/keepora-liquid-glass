import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const String _onboardingPrefKey = 'keepora_has_seen_onboarding';

  final List _onboardingData = [
    {
      'animation': 'assets/animations/task_checklist.json',
      'title': 'Pantau Perawatan Barang',
      'subtitle':
          'Mencatat dan memantau riwayat perawatan rutin barang pribadi Anda dengan mudah.',
    },
    {
      'animation': 'assets/animations/timer.json',
      'title': 'Jangan Lewatkan Jadwal',
      'subtitle':
          'Dapatkan pengingat tepat waktu untuk perawatan laptop, kendaraan, atau barang pribadi Anda.',
    },
    {
      'animation': 'assets/animations/data_analysis.json',
      'title': 'Atur Biaya Perawatan',
      'subtitle':
          'Pantau total biaya perawatan bulanan agar pengeluaran Anda tetap terkontrol.',
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingPrefKey, true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onNext() {
    if (_currentIndex < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.76) : const Color(0xFF334155);
    final accentBlue = isDark ? const Color(0xFF93C5FD) : primaryBlue;
    final inactiveDotColor = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : primaryBlue.withValues(alpha: 0.22);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Tombol lewati kaca
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _currentIndex < _onboardingData.length - 1
                        ? LiquidGlassSurface(
                            borderRadius: 20,
                            blurSigma: 12,
                            enableShadow: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            onTap: _finishOnboarding,
                            child: Text(
                              'Lewati',
                              style: TextStyle(
                                color: accentBlue,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),

              // Slide onboarding
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onboardingData.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = _onboardingData[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LiquidGlassSurface(
                            borderRadius: 32,
                            blurSigma: 20,
                            padding: const EdgeInsets.all(24),
                            child: Lottie.asset(
                              item['animation']!,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Judul Slide
                          Text(
                            item['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle Deskripsi
                          Text(
                            item['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: subtitleColor,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indikator slide
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_onboardingData.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentIndex == index ? 26.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? accentBlue
                          : inactiveDotColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Tombol lanjut/mulai LiquidGlassButton
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: LiquidGlassButton(
                  width: double.infinity,
                  height: 52,
                  borderRadius: 18,
                  tintColor: primaryBlue,
                  foregroundColor: isDark ? Colors.white : primaryBlue,
                  onPressed: _onNext,
                  child: Text(
                    _currentIndex == _onboardingData.length - 1
                        ? 'Mulai'
                        : 'Lanjut',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}