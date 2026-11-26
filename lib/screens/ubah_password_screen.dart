import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';
import 'lupa_password_screen.dart';

class UbahPasswordScreen extends StatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  State<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _oldPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  Future<void> _handleBackPress() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? shouldLeave = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Perubahan Belum Disimpan',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LiquidGlassSurface(
              borderRadius: 24,
              blurSigma: 22,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Perubahan Belum Disimpan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anda memiliki perubahan yang belum disimpan, Apakah Anda yakin ingin keluar tanpa menyimpan?',
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
                        child: LiquidGlassButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          height: 44,
                          borderRadius: 12,
                          tintColor: const Color(0xFF004AAD),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Lanjutkan ubah',
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: LiquidGlassButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          height: 44,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: const Text(
                            'Keluar',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
    );

    if (shouldLeave == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _openForgotPasswordFlow() {
    final currentEmail = _auth.currentUser?.email ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LupaPasswordScreen(initialEmail: currentEmail),
      ),
    );
  }

  bool _isValidNewPassword(String pass) {
    if (pass.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
    final hasLower = RegExp(r'[a-z]').hasMatch(pass);
    final hasDigit = RegExp(r'[0-9]').hasMatch(pass);
    return hasUpper && hasLower && hasDigit;
  }

  Future<void> _submitChangePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty) {
      showTopNotif(
        context,
        'Masukkan password lama terlebih dahulu.',
        isError: true,
      );
      return;
    }
    if (!_isValidNewPassword(newPass)) {
      showTopNotif(
        context,
        'Password baru minimal 8 karakter dengan kombinasi huruf kapital, huruf kecil, dan angka.',
        isError: true,
      );
      return;
    }
    if (newPass == oldPass) {
      showTopNotif(
        context,
        'Password baru harus berbeda dari password lama.',
        isError: true,
      );
      return;
    }
    if (newPass != confirmPass) {
      showTopNotif(
        context,
        'Konfirmasi password baru tidak cocok.',
        isError: true,
      );
      return;
    }

    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      showTopNotif(context, 'Sesi pengguna tidak ditemukan.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? shouldChange = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Konfirmasi Ubah Password',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LiquidGlassSurface(
              borderRadius: 24,
              blurSigma: 22,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Konfirmasi Ubah Password',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Apakah Anda yakin ingin mengubah password?\nPastikan Anda mengingat password baru yang telah dibuat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlassButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          height: 44,
                          borderRadius: 12,
                          tintColor: const Color(0xFF004AAD),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ubah Password',
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: LiquidGlassButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          height: 44,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (shouldChange != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      if (mounted) {
        showTopNotif(context, 'Password berhasil diperbarui.');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Gagal mengubah password: ${e.message}';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Password lama yang Anda masukkan salah.';
        } else if (e.code == 'weak-password') {
          message = 'Password baru terlalu lemah.';
        }
        showTopNotif(context, message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _glassInputDecoration({
    required String hint,
    required bool isDark,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: IconButton(
        onPressed: onToggleObscure,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: LiquidGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              onPressed: _isSaving ? null : _handleBackPress,
              icon: Icon(Icons.arrow_back, color: textPrimary),
            ),
            title: Text(
              'Ubah Password',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Lama',
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOld,
                      enabled: !_isSaving,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: _glassInputDecoration(
                        hint: 'Masukkan password lama...',
                        isDark: isDark,
                        obscure: _obscureOld,
                        onToggleObscure: () =>
                            setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _openForgotPasswordFlow,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Lupa Password?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: accentBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Password Baru',
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      enabled: !_isSaving,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: _glassInputDecoration(
                        hint: 'Masukkan password baru...',
                        isDark: isDark,
                        obscure: _obscureNew,
                        onToggleObscure: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Konfirmasi Password Baru',
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      enabled: !_isSaving,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: _glassInputDecoration(
                        hint: 'Konfirmasi password baru...',
                        isDark: isDark,
                        obscure: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  LiquidGlassSurface(
                    width: double.infinity,
                    borderRadius: 16,
                    blurSigma: 14,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syarat Kata Sandi Baru',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRequirementItem(
                          'Minimal 8 karakter',
                          textSecondary,
                        ),
                        const SizedBox(height: 3),
                        _buildRequirementItem(
                          'Kombinasi huruf kapital, huruf kecil & angka',
                          textSecondary,
                        ),
                        const SizedBox(height: 3),
                        _buildRequirementItem(
                          'Berbeda dari sandi lama',
                          textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: LiquidGlassButton(
                width: double.infinity,
                height: 52,
                borderRadius: 16,
                tintColor: primaryBlue,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submitChangePassword,
                child: Text(
                  'Ubah Password',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              fontSize: 12.5,
              color: textColor,
              height: 1.35,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}