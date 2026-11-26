import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/liquid_glass_kit.dart';
import 'akun_screen.dart';
import 'home_screen.dart';
import 'jadwal_screen.dart';
import 'riwayat_screen.dart';

class NavbarScreen extends StatefulWidget {
  final int initialIndex;

  const NavbarScreen({super.key, this.initialIndex = 0});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      HomeScreen(
        onNavigateToJadwal: () => _switchTab(1),
      ),
      const JadwalScreen(),
      const RiwayatScreen(),
      const AkunScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: LiquidGlassSurface(
          height: 68,
          borderRadius: 36,
          blurSigma: 22,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                label: 'Beranda',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.calendar_today_outlined,
                label: 'Jadwal',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.access_time_rounded,
                label: 'Riwayat',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                label: 'Akun',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final activeColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF004AAD);
    final inactiveColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(index),
        borderRadius: BorderRadius.circular(36),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? const Color(0xFF60A5FA).withValues(alpha: 0.16)
                    : const Color(0xFF004AAD).withValues(alpha: 0.10))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}