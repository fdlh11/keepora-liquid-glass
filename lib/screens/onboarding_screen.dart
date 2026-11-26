import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

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
    const primaryBlue = Color(0xFF0056C6);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor =
        isDark ? Colors.grey.shade400 : Colors.black54;
    final skipColor = isDark ? const Color(0xFF60A5FA) : primaryBlue;
    final inactiveDotColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Tombol lewati
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _currentIndex < _onboardingData.length - 1
                      ? TextButton(
                          onPressed: _finishOnboarding,
                          child: Text(
                            'Lewati',
                            style: TextStyle(
                              color: skipColor,
                              fontSize: 14,
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
                        Lottie.asset(
                          item['animation']!,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 36),

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
                            fontSize: 13,
                            color: subtitleColor,
                            height: 1.4,
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
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentIndex == index ? 24.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? primaryBlue
                        : inactiveDotColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Tombol lanjut/mulai
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex == _onboardingData.length - 1
                        ? 'Mulai'
                        : 'Lanjut',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}