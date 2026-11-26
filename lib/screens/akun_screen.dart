import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import 'edit_profile_screen.dart';
import 'ekspor_data_perawatan_screen.dart';
import 'login_screen.dart';
import 'ubah_password_screen.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final Stream<DocumentSnapshot> _userStream;
  Map<String, dynamic> _cachedUserData = {};
  String _cachedPhotoStr = '';
  Uint8List? _cachedAvatarBytes;

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    _userStream = uid != null
        ? _firestore.collection('users').doc(uid).snapshots()
        : const Stream.empty();
  }

  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final bool? shouldLogout = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: LiquidGlassSurface(
              borderRadius: 24,
              blurSigma: 22,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Logout Akun',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Apakah Anda yakin untuk Logout? Anda harus Login kembali jika ingin masuk kembali ke Akun ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.78)
                          : const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlassButton(
                          height: 44,
                          borderRadius: 12,
                          tintColor: const Color(0xFFEF4444),
                          foregroundColor: isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Center(
                            child: Text(
                              'Ya, Logout',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LiquidGlassButton(
                          height: 44,
                          borderRadius: 12,
                          tintColor: primaryBlue,
                          foregroundColor: isDark ? Colors.white : primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Center(
                            child: Text(
                              'Batal',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, _, child) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 4 * anim.value,
          sigmaY: 4 * anim.value,
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _openEditProfileScreen({
    required String currentName,
    required String currentBirthDate,
    required String currentPhotoUrl,
    required String email,
  }) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilScreen(
          initialName: currentName,
          initialBirthDate: currentBirthDate,
          initialPhotoUrl: currentPhotoUrl,
          email: email,
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  void _openExportPdfScreen({
    required String ownerName,
    required String ownerEmail,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EksporDataPerawatanScreen(
          ownerName: ownerName,
          ownerEmail: ownerEmail,
        ),
      ),
    );
  }

  void _openChangePasswordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UbahPasswordScreen()),
    );
  }

  Widget _buildProfileAvatar(String photoUrl, Color accentBlue) {
    if (photoUrl.isEmpty) {
      return Icon(Icons.person_rounded, size: 38, color: accentBlue);
    }

    if (photoUrl.startsWith('data:image')) {
      if (_cachedPhotoStr != photoUrl) {
        _cachedPhotoStr = photoUrl;
        try {
          final base64Part = photoUrl.split(',').last;
          _cachedAvatarBytes = base64Decode(base64Part);
        } catch (_) {
          _cachedAvatarBytes = null;
        }
      }

      if (_cachedAvatarBytes == null) {
        return Icon(Icons.person_rounded, size: 38, color: accentBlue);
      }

      return ClipOval(
        child: Image.memory(
          _cachedAvatarBytes!,
          width: 78,
          height: 78,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.person_rounded, size: 38, color: accentBlue),
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        photoUrl,
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.person_rounded, size: 38, color: accentBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final user = _auth.currentUser;
    final fallbackName =
        (user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : (user?.email?.split('@').first ?? 'Pengguna Keepora');
    final email = user?.email ?? '-';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.76) : const Color(0xFF334155);
    final accentBlue = isDark ? const Color(0xFF93C5FD) : primaryBlue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Pengaturan Akun',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.data() != null) {
            _cachedUserData =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
          }

          final displayName =
              (_cachedUserData['name'] ?? fallbackName).toString();
          final birthDate = (_cachedUserData['birthDate'] ?? '').toString();
          final photoUrl = (_cachedUserData['photoUrl'] ?? '').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kartu Profil Liquid Glass
                LiquidGlassSurface(
                  width: double.infinity,
                  borderRadius: 24,
                  blurSigma: 18,
                  tintColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: _buildProfileAvatar(photoUrl, accentBlue),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _openEditProfileScreen(
                                currentName: displayName,
                                currentBirthDate: birthDate,
                                currentPhotoUrl: photoUrl,
                                email: email,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withValues(
                                    alpha: isDark ? 0.30 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: accentBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: accentBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Laporan & Tampilan',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 10),

                _buildMenuTile(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Ekspor Laporan PDF',
                  textColor: titleColor,
                  iconColor: accentBlue,
                  onTap: () => _openExportPdfScreen(
                    ownerName: displayName,
                    ownerEmail: email,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: subtitleColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),

                _buildMenuTile(
                  icon: isDark
                      ? Icons.dark_mode_outlined
                      : Icons.wb_sunny_outlined,
                  label: 'Tampilan',
                  textColor: titleColor,
                  iconColor: accentBlue,
                  onTap: () => setAppTheme(!isDark),
                  trailing: SizedBox(
                    height: 28,
                    child: Switch(
                      value: isDark,
                      activeThumbColor: Colors.white,
                      activeTrackColor: primaryBlue,
                      onChanged: (value) => setAppTheme(value),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Akun & Keamanan',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 10),

                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Ubah Password',
                  textColor: titleColor,
                  iconColor: accentBlue,
                  onTap: _openChangePasswordScreen,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: subtitleColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 36),

                LiquidGlassSurface(
                  width: double.infinity,
                  height: 54,
                  borderRadius: 16,
                  blurSigma: 14,
                  tintColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: _confirmLogout,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: GoogleFonts.montserrat(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return LiquidGlassSurface(
      width: double.infinity,
      height: 54,
      borderRadius: 16,
      blurSigma: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 21, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}