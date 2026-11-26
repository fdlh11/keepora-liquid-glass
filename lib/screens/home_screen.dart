import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/asset_service.dart';
import 'detail_barang_screen.dart';
import 'notifikasi_screen.dart';
import 'tambah_barang_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToJadwal;

  const HomeScreen({super.key, this.onNavigateToJadwal});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AssetService _assetService = AssetService();
  final TextEditingController _searchController = TextEditingController();

  late final Stream<QuerySnapshot> _assetsStream;
  late final Stream<QuerySnapshot> _upcomingSchedulesStream;
  final Map<String, Uint8List> _base64Cache = {};

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _hasShownOverdueDialog = false;

  // List kategori disamakan dengan DetailBarangScreen
  final List<String> _categories = const [
    'Semua',
    'Elektronik',
    'Kendaraan',
    'Furnitur',
    'Peralatan Rumah',
    'Gadget',
    'Olahraga & Hobi',
    'Umum',
    'Lainnya',
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

  @override
  void initState() {
    super.initState();
    _assetsStream = _assetService.getAssetsStream();
    _upcomingSchedulesStream = _createUpcomingSchedulesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _base64Cache.clear();
    super.dispose();
  }

  Stream<QuerySnapshot> _createUpcomingSchedulesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('schedules')
        .snapshots();
  }

  Uint8List? _getCachedBytes(String rawPhoto) {
    if (_base64Cache.containsKey(rawPhoto)) {
      return _base64Cache[rawPhoto];
    }
    try {
      final base64Part = rawPhoto.split(',').last;
      final bytes = base64Decode(base64Part);
      _base64Cache[rawPhoto] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseScheduleDate(Map<String, dynamic> data) {
    final ts = data['scheduledAt'] as Timestamp?;
    if (ts != null) return ts.toDate();
    final tsAlt = data['scheduledTimestamp'] as Timestamp?;
    if (tsAlt != null) return tsAlt.toDate();
    return null;
  }

  String _formatTanggalLengkap(DateTime dt) {
    return '${dt.day} ${_bulanLengkap[dt.month]} ${dt.year}';
  }

  String _formatCountdownLabel(DateTime scheduledAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays < 0) return 'Terlambat ${diffDays.abs()} Hari';
    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Besok';
    return '$diffDays Hari Lagi';
  }

  String _formatOverdueDuration(DateTime scheduledAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays <= 0) return 'Terlewat hari ini';
    return 'Terlambat $diffDays hari';
  }

  void _showOverdueMaintenanceDialog(
    List<QueryDocumentSnapshot> overdueDocs,
  ) {
    if (!mounted || overdueDocs.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textSecondary =
        isDark ? Colors.grey.shade300 : const Color(0xFF4B5563);

    final firstData =
        overdueDocs.first.data() as Map<String, dynamic>? ?? {};
    final String firstTitle =
        (firstData['title'] ?? 'Perawatan Terjadwal').toString();
    final String firstAsset =
        (firstData['assetName'] ?? 'Barang Pribadi').toString();
    final DateTime? firstDate = _parseScheduleDate(firstData);
    final int totalOverdue = overdueDocs.length;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Peringatan Jadwal Terlewat',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) {
        return Center(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            backgroundColor: dialogBg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                          : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    totalOverdue == 1
                        ? 'Jadwal Perawatan Terlewat'
                        : 'Ada $totalOverdue Jadwal Terlewat',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalOverdue == 1
                        ? 'Anda memiliki 1 jadwal perawatan yang sudah melewati tenggat dan belum ditandai selesai:'
                        : 'Anda memiliki $totalOverdue jadwal perawatan yang melewati tenggat. Segera cek atau tandai selesai:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFDC2626).withValues(alpha: 0.45)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                firstTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            if (firstDate != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF7F1D1D)
                                          .withValues(alpha: 0.45)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatOverdueDuration(firstDate),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstAsset,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        if (totalOverdue > 1) ...[
                          const SizedBox(height: 6),
                          Text(
                            '+ ${totalOverdue - 1} jadwal terlewat lainnya',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? const Color(0xFF60A5FA)
                                  : primaryBlue,
                              side: const BorderSide(
                                color: Color(0xFF64A1F4),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Nanti Saja',
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
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              widget.onNavigateToJadwal?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Lihat Jadwal',
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
      },
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  IconData _getMaintenanceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'perbaikan':
        return Icons.build_outlined;
      case 'pembersihan':
        return Icons.cleaning_services_outlined;
      case 'penggantian komponen':
        return Icons.settings_suggest_outlined;
      case 'pengecekan rutin':
        return Icons.fact_check_outlined;
      default:
        return Icons.water_drop_outlined;
    }
  }

  Color _getConditionTextColor(String condition, bool isDark) {
    final lower = condition.toLowerCase();
    if (lower.contains('rusak') || lower.contains('buruk')) {
      return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    }
    if (lower.contains('baret') ||
        lower.contains('jelek') ||
        lower.contains('perlu') ||
        lower.contains('kurang') ||
        lower.contains('sedang')) {
      return isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
    }
    return isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);
  }

  Color _getConditionBgColor(String condition, bool isDark) {
    final lower = condition.toLowerCase();
    if (lower.contains('rusak') || lower.contains('buruk')) {
      return isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
          : const Color(0xFFFEE2E2);
    }
    if (lower.contains('baret') ||
        lower.contains('jelek') ||
        lower.contains('perlu') ||
        lower.contains('kurang') ||
        lower.contains('sedang')) {
      return isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.35)
          : const Color(0xFFFEF3C7);
    }
    return isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
        : const Color(0xFFDCFCE7);
  }

  Color _getConditionBorderColor(String condition, bool isDark) {
    final lower = condition.toLowerCase();
    if (lower.contains('rusak') || lower.contains('buruk')) {
      return isDark
          ? const Color(0xFFDC2626).withValues(alpha: 0.5)
          : const Color(0xFFFECACA);
    }
    if (lower.contains('baret') ||
        lower.contains('jelek') ||
        lower.contains('perlu') ||
        lower.contains('kurang') ||
        lower.contains('sedang')) {
      return isDark
          ? const Color(0xFFD97706).withValues(alpha: 0.5)
          : const Color(0xFFFDE68A);
    }
    return isDark
        ? const Color(0xFF15803D).withValues(alpha: 0.5)
        : const Color(0xFFBBF7D0);
  }

  Widget _buildAssetThumbnail(
    String docId,
    Map<String, dynamic> data,
    bool isDark,
    Color accentBlue,
  ) {
    final String rawPhoto =
        (data['photoUrl'] ?? data['imageUrl'] ?? '').toString().trim();

    Widget fallbackBox() {
      return Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: accentBlue,
          size: 32,
        ),
      );
    }

    if (rawPhoto.isEmpty) return fallbackBox();

    if (rawPhoto.startsWith('data:image')) {
      final bytes = _getCachedBytes(rawPhoto);
      if (bytes == null) return fallbackBox();

      return ClipRRect(
        key: ValueKey('img_$docId'),
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          bytes,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallbackBox(),
        ),
      );
    }

    return ClipRRect(
      key: ValueKey('img_$docId'),
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        rawPhoto,
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallbackBox(),
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
        isDark ? Colors.grey.shade800 : const Color(0xFFD1D5DB);
    final cardBorderColor =
        isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textSecondary =
        isDark ? Colors.grey.shade300 : const Color(0xFF374151);
    final textMuted = isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _upcomingSchedulesStream,
              builder: (context, schedSnapshot) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final schedDocs = schedSnapshot.data?.docs ?? [];

                final activeSchedules = schedDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final status =
                      (data['status'] ?? '').toString().toLowerCase();
                  final isCompleted = data['isCompleted'] == true ||
                      status == 'selesai' ||
                      status == 'completed';
                  return !isCompleted && _parseScheduleDate(data) != null;
                }).toList()
                  ..sort((a, b) {
                    final dtA =
                        _parseScheduleDate(a.data() as Map<String, dynamic>)!;
                    final dtB =
                        _parseScheduleDate(b.data() as Map<String, dynamic>)!;
                    return dtA.compareTo(dtB);
                  });

                if (schedSnapshot.hasData && !_hasShownOverdueDialog) {
                  _hasShownOverdueDialog = true;
                  final overdueDocs = activeSchedules.where((doc) {
                    final dt = _parseScheduleDate(
                        doc.data() as Map<String, dynamic>)!;
                    return dt.isBefore(now);
                  }).toList();

                  if (overdueDocs.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showOverdueMaintenanceDialog(overdueDocs);
                    });
                  }
                }

                final urgentCount = activeSchedules.where((doc) {
                  final dt =
                      _parseScheduleDate(doc.data() as Map<String, dynamic>)!;
                  final target = DateTime(dt.year, dt.month, dt.day);
                  return target.difference(today).inDays <= 3;
                }).length;

                final hasUpcoming = activeSchedules.isNotEmpty;
                final Map<String, dynamic> nextData = hasUpcoming
                    ? (activeSchedules.first.data() as Map<String, dynamic>? ??
                        {})
                    : {};
                final DateTime? nextDate =
                    hasUpcoming ? _parseScheduleDate(nextData) : null;
                final String schedTitle = hasUpcoming
                    ? (nextData['title'] ?? 'Perawatan Terjadwal').toString()
                    : 'Belum Ada Jadwal Mendatang';
                final String schedAsset = hasUpcoming
                    ? (nextData['assetName'] ?? '-').toString()
                    : 'Ketuk untuk menambah jadwal perawatan';
                final String schedType = hasUpcoming
                    ? (nextData['maintenanceType'] ?? 'Perawatan').toString()
                    : 'Perawatan';

                return StreamBuilder<QuerySnapshot>(
                  stream: _assetsStream,
                  builder: (context, assetSnapshot) {
                    final allDocs = assetSnapshot.data?.docs ?? [];
                    final filteredDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();
                      final category = (data['category'] ?? '').toString();

                      final matchesSearch =
                          _searchQuery.isEmpty || name.contains(_searchQuery);
                      final matchesCategory = _selectedCategory == 'Semua' ||
                          category == _selectedCategory;

                      return matchesSearch && matchesCategory;
                    }).toList();

                    return CustomScrollView(
                      slivers: [
                        // Header Judul + Lonceng Polos & Tagline Muat Satu Baris
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'KEEPORA',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF3F3D3C),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const NotifikasiScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              Icons.notifications_none_rounded,
                                              size: 26,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF3F3D3C),
                                            ),
                                            if (urgentCount > 0)
                                              Positioned(
                                                top: -3,
                                                right: -4,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEF4444),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 15,
                                                    minHeight: 15,
                                                  ),
                                                  child: Text(
                                                    urgentCount > 9
                                                        ? '9+'
                                                        : '$urgentCount',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Mengelola barang pribadi Anda dalam satu aplikasi',
                                      maxLines: 1,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : const Color(0xFF3F3D3C),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Search Bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(
                                () => _searchQuery = val.toLowerCase().trim(),
                              ),
                              style:
                                  TextStyle(fontSize: 13.5, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Cari Barang Pribadi',
                                hintStyle: TextStyle(
                                  fontSize: 13.5,
                                  color: textMuted,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: textMuted,
                                  size: 23,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: textSecondary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFF8FAFC),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: primaryBlue,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Section Perawatan Mendatang
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: widget.onNavigateToJadwal,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Perawatan Mendatang',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.north_east_rounded,
                                        size: 20,
                                        color: accentBlue,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: widget.onNavigateToJadwal,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryBlue.withValues(
                                            alpha: isDark ? 0.35 : 0.22,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.access_time_rounded,
                                                    size: 14,
                                                    color: primaryBlue,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    hasUpcoming &&
                                                            nextDate != null
                                                        ? _formatCountdownLabel(
                                                            nextDate,
                                                          )
                                                        : 'Jadwal Kosong',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: primaryBlue,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (hasUpcoming && nextDate != null)
                                              Text(
                                                _formatTanggalLengkap(nextDate),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.16,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                hasUpcoming
                                                    ? _getMaintenanceIcon(
                                                        schedType,
                                                      )
                                                    : Icons
                                                        .event_available_outlined,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    schedTitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    schedAsset,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white
                                                          .withValues(
                                                        alpha: 0.88,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Section Header Daftar Barang + Counter
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'Daftar Barang',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${filteredDocs.length} barang',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chip Kategori
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              itemCount: _categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategory == category;

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (_selectedCategory != category) {
                                      setState(
                                          () => _selectedCategory = category);
                                    }
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryBlue
                                          : surfaceColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryBlue
                                            : borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 14)),

                        // Daftar Card Barang
                        if (assetSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !assetSnapshot.hasData)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child:
                                  CircularProgressIndicator(color: primaryBlue),
                            ),
                          )
                        else if (assetSnapshot.hasError)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Terjadi kesalahan saat memuat data: ${assetSnapshot.error}',
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ),
                          )
                        else if (filteredDocs.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(32, 24, 32, 130),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 52,
                                      color: textMuted,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      allDocs.isEmpty
                                          ? 'Belum ada barang tersimpan'
                                          : 'Barang tidak ditemukan',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      allDocs.isEmpty
                                          ? 'Tambahkan barang pertama Anda lewat tombol + Barang di pojok kanan bawah.'
                                          : 'Coba ubah kata kunci pencarian atau filter kategori.',
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
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 165),
                            sliver: SliverList.separated(
                              itemCount: filteredDocs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data =
                                    doc.data() as Map<String, dynamic>? ?? {};

                                final name =
                                    (data['name'] ?? 'Tanpa Nama').toString();
                                final category =
                                    (data['category'] ?? 'Lainnya').toString();
                                final condition =
                                    (data['condition'] ?? 'Bagus').toString();
                                final conditionDetail =
                                    (data['conditionDetail'] ?? '')
                                        .toString()
                                        .trim();
                                final lastMaint =
                                    (data['lastMaintenance'] ?? '-').toString();

                                final showConditionDetail =
                                    conditionDetail.isNotEmpty;

                                final condTextColor =
                                    _getConditionTextColor(condition, isDark);
                                final condBgColor =
                                    _getConditionBgColor(condition, isDark);
                                final condBorderColor =
                                    _getConditionBorderColor(condition, isDark);

                                return InkWell(
                                  key: ValueKey('asset_card_${doc.id}'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailBarangScreen(assetId: doc.id),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(18),
                                      border:
                                          Border.all(color: cardBorderColor),
                                      boxShadow: [
                                        if (!isDark)
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        _buildAssetThumbnail(
                                          doc.id,
                                          data,
                                          isDark,
                                          accentBlue,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF172554,
                                                              )
                                                            : const Color(
                                                                0xFFDBEAFE,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          20,
                                                        ),
                                                        border: Border.all(
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF1D4ED8,
                                                                )
                                                              : const Color(
                                                                  0xFF93C5FD,
                                                                ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        category,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: accentBlue,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 9,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: condBgColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: condBorderColor,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 5,
                                                          height: 5,
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                condTextColor,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          condition,
                                                          style: TextStyle(
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                condTextColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 20,
                                                    color: textSecondary,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Perawatan Terakhir : $lastMaint',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                              ),
                                              if (showConditionDetail) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  conditionDetail,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
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
                );
              },
            ),

            // Tombol mengambang + Barang tetap di atas navbar
            Positioned(
              right: 20,
              bottom: 98,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TambahBarangScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'Barang',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}