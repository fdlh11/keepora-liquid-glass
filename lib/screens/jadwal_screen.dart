import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jadwal_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
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
        bg: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.14),
        text: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
        border: const Color(0xFFEF4444).withValues(alpha: 0.45),
      );
    } else if (diffDays <= 15) {
      return (
        bg: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.16),
        text: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        border: const Color(0xFFF59E0B).withValues(alpha: 0.45),
      );
    } else {
      return (
        bg: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.14),
        text: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
        border: const Color(0xFF10B981).withValues(alpha: 0.45),
      );
    }
  }

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
                  gradient: hasSchedule
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF3B82F6),
                                  primaryBlue,
                                ]
                              : [
                                  const Color(0xFF2563EB),
                                  primaryBlue,
                                ],
                        )
                      : null,
                  boxShadow: hasSchedule
                      ? [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                  border: isToday && !hasSchedule
                      ? Border.all(
                          color: accentBlue,
                          width: 1.5,
                        )
                      : (isSelected && !hasSchedule
                          ? Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : primaryBlue.withValues(alpha: 0.35),
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
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFF94A3B8))),
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
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF475569);
    final accentBlue = isDark ? const Color(0xFF93C5FD) : primaryBlue;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : primaryBlue.withValues(alpha: 0.14);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthWeeks = _getMonthWeeks();
    final twoWeekPageCount = monthWeeks.length ~/ 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
              // Kalender Liquid Glass
              LiquidGlassSurface(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                borderRadius: 22,
                blurSigma: 18,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _gantiBulan(-1),
                          borderRadius: BorderRadius.circular(10),
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
                          borderRadius: BorderRadius.circular(10),
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
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
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
                    Divider(height: 1, color: dividerColor),
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
                    LiquidGlassButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TambahJadwalScreen(),
                          ),
                        );
                      },
                      tintColor: primaryBlue,
                      foregroundColor: isDark ? Colors.white : primaryBlue,
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Jadwal',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 32, 70),
                          child: LiquidGlassSurface(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_note_outlined,
                                  size: 48,
                                  color: accentBlue,
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
                              ],
                            ),
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

                          return LiquidGlassSurface(
                            borderRadius: 20,
                            blurSigma: 14,
                            padding: const EdgeInsets.all(14),
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
                                        color: primaryBlue
                                            .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(20),
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
                                        borderRadius: BorderRadius.circular(20),
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
                                    color: primaryBlue.withValues(
                                      alpha: isDark ? 0.28 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accentBlue.withValues(alpha: 0.35),
                                    ),
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