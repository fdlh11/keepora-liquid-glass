import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/asset_service.dart';
import 'edit_riwayat_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final AssetService _assetService = AssetService();
  late final Stream<List<QueryDocumentSnapshot>> _historyStream;

  late DateTime _selectedMonthYear;
  String _selectedFilter = 'Semua';

  final List<String> _filters = const [
    'Semua',
    'Perawatan',
    'Perbaikan',
    'Pembersihan',
    'Penggantian Komponen',
    'Pengecekan Rutin',
  ];

  static const List<String> _bulanLengkap = [
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthYear = DateTime(now.year, now.month);
    _historyStream = _assetService.getAllMaintenanceHistoryStream();
  }

  List<DateTime> _generateMonthOptions(List<QueryDocumentSnapshot> docs) {
    final Set<String> keys = {};
    final List<DateTime> result = [];

    void addMonth(DateTime dt) {
      final key = '${dt.year}-${dt.month}';
      if (keys.add(key)) {
        result.add(DateTime(dt.year, dt.month));
      }
    }

    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      addMonth(DateTime(now.year, now.month - i));
    }

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final dt = _extractDate(data);
      addMonth(dt);
    }

    // Urutkan kronologis dari bulan lalu (atas) ke bulan terbaru (bawah)
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  DateTime _extractDate(Map<String, dynamic> data) {
    final completedTs = data['completedAt'] as Timestamp?;
    if (completedTs != null) return completedTs.toDate();

    final createdTs = data['createdAt'] as Timestamp?;
    if (createdTs != null) return createdTs.toDate();

    return DateTime.now();
  }

  int _parseCostToInt(dynamic rawCost) {
    if (rawCost == null) return 0;
    if (rawCost is num) return rawCost.round();
    final digits = rawCost.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  String _formatBadgeDateTime(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_bulanSingkat[dt.month]} ${dt.year} / $jam.$menit WIB';
  }

  String _formatBulanTahun(DateTime dt) {
    return '${_bulanLengkap[dt.month]} ${dt.year}';
  }

  String _normalizeCategory(Map<String, dynamic> data) {
    final raw = (data['maintenanceType'] ?? 'Perawatan').toString().trim();
    for (final option in _filters) {
      if (option != 'Semua' && option.toLowerCase() == raw.toLowerCase()) {
        return option;
      }
    }
    return 'Perawatan';
  }

  void _bukaHalamanEdit(
    String assetId,
    String historyId,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRiwayatScreen(
          assetId: assetId,
          historyId: historyId,
          data: data,
          assetService: _assetService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);

    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final chipBorderUnselected =
        isDark ? Colors.grey.shade700 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Riwayat Biaya & Perawatan',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _historyStream,
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
                  'Gagal memuat riwayat: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final List<QueryDocumentSnapshot> allDocs =
              List<QueryDocumentSnapshot>.from(snapshot.data ?? [])
                ..sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>? ?? {};
                  final dataB = b.data() as Map<String, dynamic>? ?? {};
                  return _extractDate(dataB).compareTo(_extractDate(dataA));
                });

          final monthOptions = _generateMonthOptions(allDocs);
          if (!monthOptions.any(
            (m) =>
                m.year == _selectedMonthYear.year &&
                m.month == _selectedMonthYear.month,
          )) {
            _selectedMonthYear = monthOptions.last;
          }

          int totalMonthlySpend = 0;
          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final dt = _extractDate(data);
            if (dt.year == _selectedMonthYear.year &&
                dt.month == _selectedMonthYear.month) {
              totalMonthlySpend += _parseCostToInt(data['cost']);
            }
          }

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final normalizedType = _normalizeCategory(data);
            if (_selectedFilter == 'Semua') return true;
            return normalizedType == _selectedFilter;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Biru Ringkasan Pengeluaran
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 22),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Pengeluaran bulan ini',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<DateTime>(
                              value: monthOptions.firstWhere(
                                (m) =>
                                    m.year == _selectedMonthYear.year &&
                                    m.month == _selectedMonthYear.month,
                              ),
                              menuMaxHeight: 380,
                              itemHeight: 48,
                              borderRadius: BorderRadius.circular(14),
                              dropdownColor: primaryBlue,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              items: monthOptions.map((monthDate) {
                                return DropdownMenuItem<DateTime>(
                                  value: monthDate,
                                  child: Text(
                                    _formatBulanTahun(monthDate),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMonthYear = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatRupiah(totalMonthlySpend),
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Judul Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Riwayat Perbaikan/Perawatan Terakhir',
                  style: GoogleFonts.montserrat(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips Horizontal Scrollable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_selectedFilter != filter) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? primaryBlue
                                  : chipBorderUnselected,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Daftar Kartu Riwayat
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 54,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum Ada Riwayat',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Riwayat akan otomatis tercatat saat jadwal perawatan ditandai selesai atau dicatat di detail barang.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};

                          final String assetId = (data['assetId'] ??
                                  doc.reference.parent.parent?.id ??
                                  '')
                              .toString();
                          final String assetName =
                              (data['assetName'] ?? 'Barang').toString();
                          final String rawTitle =
                              (data['title'] ?? '').toString().trim();
                          final String detail =
                              (data['detail'] ?? data['notes'] ?? '')
                                  .toString()
                                  .trim();
                          final String displayTitle = rawTitle.isNotEmpty
                              ? rawTitle
                              : (detail.isNotEmpty
                                  ? detail
                                  : 'Perawatan $assetName');
                          final String categoryLabel =
                              _normalizeCategory(data);
                          final DateTime completedDate = _extractDate(data);
                          final int costValue = _parseCostToInt(data['cost']);

                          return Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                              ),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
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
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryBlue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _formatBadgeDateTime(completedDate),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: assetId.isEmpty
                                          ? null
                                          : () => _bukaHalamanEdit(
                                                assetId,
                                                doc.id,
                                                data,
                                              ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 24,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  assetName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? primaryBlue.withValues(alpha: 0.25)
                                            : const Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF60A5FA)
                                              : const Color(0xFF93C5FD),
                                        ),
                                      ),
                                      child: Text(
                                        categoryLabel,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF93C5FD)
                                              : primaryBlue,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Biaya ${_formatRupiah(costValue)}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
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