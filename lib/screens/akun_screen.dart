import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/auth_service.dart';
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

  // Button Logout
  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
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
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda yakin untuk Logout? Anda harus Login kembali jika ingin masuk kembali ke Akun ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Ya, Logout',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF004AAD),
                          side: const BorderSide(
                            color: Color(0xFF64A1F4),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          maxLines: 1,
                          textAlign: TextAlign.center,
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

  Widget _buildProfileAvatar(String photoUrl) {
    if (photoUrl.isEmpty) {
      return const SizedBox.shrink();
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

      if (_cachedAvatarBytes == null) return const SizedBox.shrink();

      return ClipOval(
        child: Image.memory(
          _cachedAvatarBytes!,
          width: 78,
          height: 78,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6);
    final cardBgColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6);
    final borderColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade400;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final itemTextColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                        child: _buildProfileAvatar(photoUrl),
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _openEditProfileScreen(
                                currentName: displayName,
                                currentBirthDate: birthDate,
                                currentPhotoUrl: photoUrl,
                                email: email,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: Colors.white,
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

                // Button ekspor laporan pdf
                _buildMenuTile(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Ekspor Laporan PDF',
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textColor: itemTextColor,
                  onTap: () => _openExportPdfScreen(
                    ownerName: displayName,
                    ownerEmail: email,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: itemTextColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),

                // button tampilan mode gelap / terang
                _buildMenuTile(
                  icon: isDark
                      ? Icons.dark_mode_outlined
                      : Icons.wb_sunny_outlined,
                  label: 'Tampilan',
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textColor: itemTextColor,
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

                // Button ubah password
                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Ubah Password',
                  cardBgColor: cardBgColor,
                  borderColor: borderColor,
                  textColor: itemTextColor,
                  onTap: _openChangePasswordScreen,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: itemTextColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 36),

                InkWell(
                  onTap: _confirmLogout,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.1),
                    ),
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
    required Color cardBgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}