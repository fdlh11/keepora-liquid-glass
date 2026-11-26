import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6);
    final navBgColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
    final navBorderColor =
        isDark ? Colors.grey.shade800 : const Color(0xFFC7D2FE);

    final List<Widget> pages = [
      HomeScreen(
        onNavigateToJadwal: () => _switchTab(1),
      ),
      const JadwalScreen(),
      const RiwayatScreen(),
      const AkunScreen(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: navBgColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: navBorderColor,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
        isDark ? Colors.grey.shade400 : const Color(0xFF737373);
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(index),
        borderRadius: BorderRadius.circular(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 25,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}