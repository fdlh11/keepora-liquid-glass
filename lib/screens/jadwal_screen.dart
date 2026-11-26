import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jadwal_service.dart';
import 'detail_jadwal_screen.dart';
import 'tambah_jadwal_screen.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final JadwalService _jadwalService = JadwalService();
  late final PageController _calendarPageController;

  static const double _weekRowHeight = 38.0;

  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  // list bulan
  static const List<String> _bulanIndo = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  // list bulan singkat
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

  // list nama hari
  static const List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);

    final initialPage = _getTargetTwoWeekPageIndex();
    _calendarPageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _calendarPageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatBadgeTanggal(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month]} ${date.year}';
  }

  String _formatCountdownDanJam(DateTime scheduledAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final diffDays = targetDay.difference(today).inDays;

    final jam = scheduledAt.hour.toString().padLeft(2, '0');
    final menit = scheduledAt.minute.toString().padLeft(2, '0');
    final jamStr = '$jam.$menit WIB';

    if (diffDays < 0) {
      return 'Terlewat / $jamStr';
    } else if (diffDays == 0) {
      return 'Hari ini / $jamStr';
    } else {
      return '$diffDays Hari / $jamStr';
    }
  }

  /// Logika warna dinamis berdasarkan kedekatan hari H:
  /// - <= 10 hari (termasuk hari ini & terlewat): Merah
  /// - 11 s/d 20 hari: Oranye
  /// - >= 21 hari: Hijau
  ({Color bg, Color text, Color border}) _getCountdownBadgeStyle(
    DateTime scheduledAt,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final diffDays = targetDay.difference(today).inDays;

    if (diffDays <= 3) {
      return (
        bg: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
        text: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
        border: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
      );
    } else if (diffDays <= 15) {
      return (
        bg: isDark ? const Color(0xFF452700) : const Color(0xFFFEF3C7),
        text: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        border: isDark ? const Color(0xFFD97706) : const Color(0xFFFBBF24),
      );
    } else {
      return (
        bg: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
        text: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
        border: isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC),
      );
    }
  }

  // Menghasilkan daftar minggu dalam 1 bulan dengan jumlah genap (kelipatan 2 minggu)
  List<List<DateTime>> _getMonthWeeks() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    final startMonday =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    final endSunday =
        lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday));

    final totalDays = endSunday.difference(startMonday).inDays + 1;
    int weekCount = (totalDays / 7).ceil();
    if (weekCount.isOdd) {
      weekCount += 1;
    }

    return List.generate(weekCount, (weekIndex) {
      return List.generate(7, (dayIndex) {
        return startMonday.add(Duration(days: weekIndex * 7 + dayIndex));
      });
    });
  }

  int _getTargetTwoWeekPageIndex() {
    final weeks = _getMonthWeeks();
    final targetWeekIndex = weeks.indexWhere(
      (week) => week.any((d) => _isSameDay(d, _selectedDate)),
    );
    if (targetWeekIndex == -1) return 0;
    return targetWeekIndex ~/ 2;
  }

  void _scrollToSelectedTwoWeeks({bool animate = true}) {
    if (!_calendarPageController.hasClients) return;

    final targetPage = _getTargetTwoWeekPageIndex();
    if (animate) {
      _calendarPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _calendarPageController.jumpToPage(targetPage);
    }
  }

  void _gantiBulan(int delta) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
      final now = DateTime.now();
      if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) {
        _selectedDate = DateTime(now.year, now.month, now.day);
      } else {
        _selectedDate = _focusedMonth;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTwoWeeks(animate: true);
    });
  }

  Widget _buildWeekRow({
    required List<DateTime> weekDates,
    required DateTime today,
    required List<DateTime> allScheduledDates,
    required Color primaryBlue,
    required Color accentBlue,
    required Color textPrimary,
    required bool isDark,
  }) {
    return SizedBox(
      height: _weekRowHeight,
      child: Row(
        children: List.generate(7, (col) {
          final date = weekDates[col];
          final bool isToday = _isSameDay(date, today);
          final bool isSelected = _isSameDay(date, _selectedDate);
          final bool hasSchedule =
              allScheduledDates.any((d) => _isSameDay(d, date));
          final bool isCurrentMonth = date.month == _focusedMonth.month;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                final changedMonth = date.month != _focusedMonth.month ||
                    date.year != _focusedMonth.year;
                setState(() {
                  _selectedDate = date;
                  _focusedMonth = DateTime(date.year, date.month, 1);
                });
                if (changedMonth) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToSelectedTwoWeeks(animate: true);
                  });
                }
              },
              child: Container(
                height: 34,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasSchedule ? primaryBlue : Colors.transparent,
                  border: isToday && !hasSchedule
                      ? Border.all(
                          color: accentBlue,
                          width: 1.4,
                        )
                      : (isSelected && !hasSchedule
                          ? Border.all(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                              width: 1.2,
                            )
                          : null),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: (hasSchedule || isToday)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: hasSchedule
                        ? Colors.white
                        : (isCurrentMonth
                            ? textPrimary
                            : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthWeeks = _getMonthWeeks();
    final twoWeekPageCount = monthWeeks.length ~/ 2;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Jadwal Perawatan',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _jadwalService.streamJadwalAktif(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat jadwal: ${snapshot.error}',
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

          final List<DateTime> allScheduledDates = docs.map((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            return (data['scheduledAt'] as Timestamp?)?.toDate() ??
                DateTime.now();
          }).toList();

          final int jumlahJadwalBulanIni = allScheduledDates
              .where((dt) =>
                  dt.year == _focusedMonth.year &&
                  dt.month == _focusedMonth.month)
              .length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _gantiBulan(-1),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${_bulanIndo[_focusedMonth.month]} ${_focusedMonth.year}',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () => _gantiBulan(1),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: _namaHari
                          .map(
                            (hari) => Expanded(
                              child: Center(
                                child: Text(
                                  hari,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),

                    // Scroll vertikal setiap 2 minggu
                    SizedBox(
                      height: _weekRowHeight * 2,
                      child: PageView.builder(
                        controller: _calendarPageController,
                        scrollDirection: Axis.vertical,
                        physics: const PageScrollPhysics(),
                        itemCount: twoWeekPageCount,
                        itemBuilder: (context, pageIndex) {
                          final firstWeek = monthWeeks[pageIndex * 2];
                          final secondWeek = monthWeeks[pageIndex * 2 + 1];
                          return Column(
                            children: [
                              _buildWeekRow(
                                weekDates: firstWeek,
                                today: today,
                                allScheduledDates: allScheduledDates,
                                primaryBlue: primaryBlue,
                                accentBlue: accentBlue,
                                textPrimary: textPrimary,
                                isDark: isDark,
                              ),
                              _buildWeekRow(
                                weekDates: secondWeek,
                                today: today,
                                allScheduledDates: allScheduledDates,
                                primaryBlue: primaryBlue,
                                accentBlue: accentBlue,
                                textPrimary: textPrimary,
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hari ini: ${today.day} ${_bulanSingkat[today.month]}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accentBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$jumlahJadwalBulanIni jadwal bulan ini',
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
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwal Berikutnya',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TambahJadwalScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Jadwal',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note_outlined,
                                size: 56,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Belum Ada Jadwal Perawatan',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tekan tombol + Jadwal di atas untuk menambahkan pengingat perawatan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};
                          final Timestamp? ts =
                              data['scheduledAt'] as Timestamp?;
                          final DateTime scheduledAt =
                              ts?.toDate() ?? DateTime.now();

                          final badgeStyle =
                              _getCountdownBadgeStyle(scheduledAt, isDark);

                          return InkWell(
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
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryBlue,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _formatBadgeTanggal(scheduledAt),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeStyle.bg,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: badgeStyle.border,
                                          ),
                                        ),
                                        child: Text(
                                          _formatCountdownDanJam(scheduledAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: badgeStyle.text,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Text(
                                    (data['title'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  Text(
                                    (data['assetName'] ?? '-').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF172554)
                                          : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (data['maintenanceType'] ?? 'Perawatan')
                                          .toString(),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: accentBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}