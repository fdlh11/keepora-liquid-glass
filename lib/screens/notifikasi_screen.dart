import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jadwal_service.dart';
import '../utils/liquid_glass_kit.dart';
import 'detail_jadwal_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final JadwalService _jadwalService = JadwalService();

  static const List<String> _bulanSingkat = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _formatTanggalJam(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_bulanSingkat[dt.month]} ${dt.year} - $jam:$menit WIB';
  }

  ({String label, String message, Color badgeBg, Color badgeText})
      _getReminderMeta(
    DateTime scheduledAt,
    String maintenanceType,
    String assetName,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final diffDays = targetDay.difference(today).inDays;
    final lowerType = maintenanceType.toLowerCase();

    if (diffDays < 0) {
      return (
        label: 'Terlewat ${diffDays.abs()} Hari',
        message: '$maintenanceType untuk barang $assetName telah melewati tenggat',
        badgeBg: const Color(0xFFDC2626),
        badgeText: Colors.white,
      );
    } else if (diffDays == 0) {
      return (
        label: 'Hari Ini',
        message: 'Waktunya melakukan $lowerType untuk barang $assetName',
        badgeBg: const Color(0xFFD97706),
        badgeText: Colors.white,
      );
    } else if (diffDays == 1) {
      final needsBudget = lowerType.contains('perbaikan') ||
          lowerType.contains('penggantian');
      return (
        label: 'Besok',
        message: needsBudget
            ? 'Siapkan biaya $lowerType untuk barang $assetName'
            : 'Jadwal $lowerType untuk barang $assetName dilaksanakan besok',
        badgeBg: isDark ? const Color(0xFF2563EB) : const Color(0xFF004AAD),
        badgeText: Colors.white,
      );
    } else {
      return (
        label: '$diffDays Hari Lagi',
        message: 'Jadwal $lowerType untuk barang $assetName dijadwalkan',
        badgeBg: const Color(0xFF15803D),
        badgeText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF475569);
    final accentBlue = isDark ? const Color(0xFF93C5FD) : primaryBlue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: LiquidGlassSurface(
            borderRadius: 14,
            blurSigma: 14,
            padding: const EdgeInsets.all(6),
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_rounded, color: textPrimary, size: 20),
          ),
        ),
        title: Text(
          'Notifikasi Jadwal',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _jadwalService.streamJadwalAktif(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Gagal memuat notifikasi: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              final docs = [...(snapshot.data?.docs ?? [])]..sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>? ?? {};
                  final dataB = b.data() as Map<String, dynamic>? ?? {};
                  final tsA = (dataA['scheduledAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final tsB = (dataB['scheduledAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  return tsA.compareTo(tsB);
                });

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: LiquidGlassSurface(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: primaryBlue.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 34,
                              color: accentBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Pengingat',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Semua jadwal perawatan aktif Anda akan muncul otomatis di sini sebagai pengingat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final title =
                      (data['title'] ?? 'Perawatan Barang').toString();
                  final assetName = (data['assetName'] ?? '-').toString();
                  final type =
                      (data['maintenanceType'] ?? 'Perawatan').toString();
                  final scheduledAt =
                      (data['scheduledAt'] as Timestamp?)?.toDate() ??
                          DateTime.now();

                  final meta =
                      _getReminderMeta(scheduledAt, type, assetName, isDark);

                  return LiquidGlassSurface(
                    borderRadius: 18,
                    blurSigma: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailJadwalScreen(
                            scheduleId: doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: accentBlue,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: meta.badgeBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      meta.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: meta.badgeText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meta.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: accentBlue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatTanggalJam(scheduledAt),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: accentBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}