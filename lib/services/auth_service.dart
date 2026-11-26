import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Registrasi Akun + Kirim Link Verifikasi Email
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Kirim link verifikasi ke email asli pengguna
        await credential.user!.sendEmailVerification();

        // Simpan data profil ke firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name ?? 'Pengguna Keepora',
          'email': email,
          'role': 'user',
          'is_verified': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mendaftarkan akun. Silakan coba lagi.';
    }
  }

  // Login - wajib email terverif
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload data pengguna untuk memperbarui status verifikasi terbaru
      await credential.user!.reload();
      User? updatedUser = _auth.currentUser;

      // Cek apakah email sudah diverifikasi via link
      if (updatedUser != null && !updatedUser.emailVerified) {
        await updatedUser.sendEmailVerification();
        await _auth.signOut(); // Logout otomatis jika belum verifikasi
        throw 'Email Anda belum diverifikasi. Kami telah mengirimkan ulang tautan verifikasi ke email asli Anda. Silakan periksa inbox/spam email Anda.';
      }

      // Update status verified di Firestore jika sudah terverifikasi
      if (updatedUser != null && updatedUser.emailVerified) {
        await _firestore.collection('users').doc(updatedUser.uid).update({
          'is_verified': true,
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Gagal masuk. Silakan coba lagi.';
    }
  }

  // Lupa Password
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mengirim email reset password.';
    }
  }

  // Keluar Akun (tanpa mereset onboarding)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper pesan error Bahasa Indonesia baku
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan periksa kembali.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid atau domain email tidak dapat digunakan.';
      default:
        return 'Terjadi kesalahan pada layanan autentikasi (${e.code}).';
    }
  }
}