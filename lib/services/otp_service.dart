import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kredensial EmailJS
  static const String _serviceId = 'service_tyymoyy';
  static const String _templateId = 'template_oz33uq5';
  static const String _publicKey = 'kzO2j_1GpbQArup1F';

  // URL Backend Vercel untuk memperbarui password Firebase Auth
  static const String _resetApiUrl = 'https://keepora-api.vercel.app/api/reset-password';

  // Generate OTP 6 digit, simpan ke Firestore, dan kirim via EmailJS
  Future<void> sendOtpToEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('Email tidak terdaftar pada sistem Keepora.');
    }

    final otpCode = (100000 + Random().nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    await _firestore.collection('password_resets').doc(normalizedEmail).set({
      'otp': otpCode,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'verified': false,
    });

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': normalizedEmail,
          'otp_code': otpCode,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('(${response.statusCode}) ${response.body}');
    }
  }

  // Verifikasi kecocokan dan masa berlaku kode OTP
  Future<bool> verifyOtp(String email, String inputOtp) async {
    final normalizedEmail = email.trim().toLowerCase();
    final doc = await _firestore
        .collection('password_resets')
        .doc(normalizedEmail)
        .get();

    if (!doc.exists) {
      throw Exception('Permintaan OTP tidak ditemukan.');
    }

    final data = doc.data()!;
    final savedOtp = data['otp'] as String;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Kode OTP telah kedaluwarsa. Silakan kirim ulang.');
    }

    if (savedOtp != inputOtp) {
      throw Exception('Kode OTP yang Anda masukkan salah.');
    }

    await doc.reference.update({'verified': true});
    return true;
  }

  // Perbarui password akun di Firebase Auth melalui endpoint Vercel
  Future<void> updatePasswordWithOtp(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse(_resetApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Gagal memperbarui kata sandi.');
    }
  }
}