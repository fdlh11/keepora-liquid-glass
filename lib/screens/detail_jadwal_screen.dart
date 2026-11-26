import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jadwal_service.dart';
import '../utils/custom_app_dropdown.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class DetailJadwalScreen extends StatefulWidget {
  final String scheduleId;
  final Map<String, dynamic> data;

  const DetailJadwalScreen({
    super.key,
    required this.scheduleId,
    required this.data,
  });

  @override
  State<DetailJadwalScreen> createState() => _DetailJadwalScreenState();
}

class _DetailJadwalScreenState extends State<DetailJadwalScreen> {
  final JadwalService _jadwalService = JadwalService();
  late Map<String, dynamic> _currentData;
  bool _isProcessing = false;

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
    _currentData = Map<String, dynamic>.from(widget.data);
  }

  String _formatTanggal(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month]} ${date.year}';
  }

  String _formatJam(DateTime date) {
    final jam = date.hour.toString().padLeft(2, '0');
    final menit = date.minute.toString().padLeft(2, '0');
    return '$jam:$menit WIB';
  }

  String _formatRupiah(num value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Future<void> _bukaHalamanEdit() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditJadwalScreen(
          scheduleId: widget.scheduleId,
          data: _currentData,
          jadwalService: _jadwalService,
        ),
      ),
    );

    if (updatedData != null && mounted) {
      setState(() {
        _currentData = updatedData;
      });
    }
  }

  Future<void> _konfirmasiHapus() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Hapus Jadwal',
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
                    'Hapus Jadwal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jadwal ini akan dihapus permanen. Apakah Anda yakin ingin melanjutkan?',
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
                          onPressed: () => Navigator.pop(dialogContext, true),
                          height: 44,
                          borderRadius: 12,
                          tintColor: const Color(0xFFDC2626),
                          foregroundColor: isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: const Text(
                            'Ya, Hapus',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _jadwalService.hapusJadwal(widget.scheduleId);
      if (mounted) {
        showTopNotif(context, 'Jadwal berhasil dihapus.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal menghapus jadwal: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _selesaikanJadwalLangsung() async {
    setState(() => _isProcessing = true);
    try {
      await _jadwalService.tandaiSelesai(
        scheduleId: widget.scheduleId,
        scheduleData: _currentData,
      );

      if (mounted) {
        showTopNotif(
          context,
          'Jadwal selesai & dipindahkan ke Riwayat Perawatan.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal menyelesaikan jadwal: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;

    final Timestamp? ts = _currentData['scheduledAt'] as Timestamp?;
    final DateTime scheduledAt = ts?.toDate() ?? DateTime.now();
    final String notes = (_currentData['notes'] ?? '').toString();
    final num estimatedCost = (_currentData['estimatedCost'] as num?) ?? 0;

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textPrimary),
          ),
          title: Text(
            'Detail Jadwal',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _isProcessing ? null : _bukaHalamanEdit,
              icon: Icon(Icons.edit_outlined, color: accentBlue),
              tooltip: 'Edit Jadwal',
            ),
            IconButton(
              onPressed: _isProcessing ? null : _konfirmasiHapus,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus Jadwal',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nama Jadwal', isDark),
              const SizedBox(height: 6),
              _buildReadOnlyBox(
                (_currentData['title'] ?? '-').toString(),
                isDark,
              ),
              const SizedBox(height: 16),
              _buildLabel('Nama Barang', isDark),
              const SizedBox(height: 6),
              _buildReadOnlyBox(
                (_currentData['assetName'] ?? '-').toString(),
                isDark,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tanggal Jadwal', isDark),
                        const SizedBox(height: 6),
                        _buildReadOnlyBox(_formatTanggal(scheduledAt), isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Jam Jadwal', isDark),
                        const SizedBox(height: 6),
                        _buildReadOnlyBox(_formatJam(scheduledAt), isDark),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLabel('Jenis Perawatan', isDark),
              const SizedBox(height: 6),
              _buildReadOnlyBox(
                (_currentData['maintenanceType'] ?? 'Perawatan').toString(),
                isDark,
              ),
              const SizedBox(height: 16),
              _buildLabel('Estimasi Biaya Perawatan', isDark),
              const SizedBox(height: 6),
              _buildReadOnlyBox(_formatRupiah(estimatedCost), isDark),
              const SizedBox(height: 16),
              _buildLabel('Catatan Tambahan (Opsional)', isDark),
              const SizedBox(height: 6),
              _buildReadOnlyBox(
                notes.isEmpty ? '-' : notes,
                isDark,
                minHeight: 90,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: LiquidGlassButton(
              width: double.infinity,
              height: 52,
              borderRadius: 16,
              tintColor: primaryBlue,
              isLoading: _isProcessing,
              onPressed: _isProcessing ? null : _selesaikanJadwalLangsung,
              child: Text(
                'Tandai Selesai',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildReadOnlyBox(String value, bool isDark, {double minHeight = 48}) {
    return LiquidGlassSurface(
      width: double.infinity,
      borderRadius: 14,
      blurSigma: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight - 26),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

class EditJadwalScreen extends StatefulWidget {
  final String scheduleId;
  final Map<String, dynamic> data;
  final JadwalService jadwalService;

  const EditJadwalScreen({
    super.key,
    required this.scheduleId,
    required this.data,
    required this.jadwalService,
  });

  @override
  State<EditJadwalScreen> createState() => _EditJadwalScreenState();
}

class _EditJadwalScreenState extends State<EditJadwalScreen> {
  late TextEditingController _namaJadwalController;
  late TextEditingController _estimasiBiayaController;
  late TextEditingController _catatanController;

  String? _selectedAssetId;
  String? _selectedAssetName;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedJenisPerawatan;
  bool _isSaving = false;

  late String _initialTitle;
  late String _initialAssetId;
  late DateTime _initialDate;
  late TimeOfDay _initialTime;
  late String _initialMaintenanceType;
  late String _initialCostDigits;
  late String _initialNotes;

  final List<String> _jenisPerawatanList = const [
    'Perawatan',
    'Perbaikan',
    'Pembersihan',
    'Penggantian Komponen',
    'Pengecekan Rutin',
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

  DateTime get _minScheduleDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  String _formatRibuan(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void _onBiayaChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatRibuan(digits);
    if (formatted != value) {
      _estimasiBiayaController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initialTitle = (widget.data['title'] ?? '').toString();
    _namaJadwalController = TextEditingController(text: _initialTitle);

    final num existingCost = (widget.data['estimatedCost'] as num?) ?? 0;
    _initialCostDigits =
        existingCost > 0 ? existingCost.round().toString() : '';
    _estimasiBiayaController = TextEditingController(
      text: existingCost > 0 ? _formatRibuan(_initialCostDigits) : '',
    );

    _initialNotes = (widget.data['notes'] ?? '').toString();
    _catatanController = TextEditingController(text: _initialNotes);

    _initialAssetId = (widget.data['assetId'] ?? '').toString();
    _selectedAssetId = _initialAssetId;
    _selectedAssetName = (widget.data['assetName'] ?? '').toString();

    final Timestamp? ts = widget.data['scheduledAt'] as Timestamp?;
    final DateTime dt = ts?.toDate() ?? DateTime.now();
    _initialDate = DateTime(dt.year, dt.month, dt.day);
    _initialTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    _selectedDate = _initialDate;
    _selectedTime = _initialTime;

    final existingType =
        (widget.data['maintenanceType'] ?? 'Perawatan').toString();
    _initialMaintenanceType = _jenisPerawatanList.contains(existingType)
        ? existingType
        : _jenisPerawatanList.first;
    _selectedJenisPerawatan = _initialMaintenanceType;
  }

  bool get _hasUnsavedChanges {
    final currentCostDigits =
        _estimasiBiayaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return _namaJadwalController.text.trim() != _initialTitle.trim() ||
        (_selectedAssetId ?? '') != _initialAssetId ||
        _selectedDate.year != _initialDate.year ||
        _selectedDate.month != _initialDate.month ||
        _selectedDate.day != _initialDate.day ||
        _selectedTime.hour != _initialTime.hour ||
        _selectedTime.minute != _initialTime.minute ||
        _selectedJenisPerawatan != _initialMaintenanceType ||
        currentCostDigits != _initialCostDigits ||
        _catatanController.text.trim() != _initialNotes.trim();
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
                    'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar tanpa menyimpan?',
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
                              'Lanjutkan Edit',
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

  String _formatTanggal(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month]} ${date.year}';
  }

  String _formatJam(TimeOfDay time) {
    final jam = time.hour.toString().padLeft(2, '0');
    final menit = time.minute.toString().padLeft(2, '0');
    return '$jam:$menit WIB';
  }

  Future<void> _pilihTanggal() async {
    final minDate = _minScheduleDate;
    final initial = _selectedDate.isBefore(minDate) ? minDate : _selectedDate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF60A5FA),
                    surface: Color(0xFF1E1E1E),
                  )
                : const ColorScheme.light(primary: Color(0xFF004AAD)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pilihJam() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF60A5FA),
                    surface: Color(0xFF1E1E1E),
                  )
                : const ColorScheme.light(primary: Color(0xFF004AAD)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _simpanPerubahan() async {
    final namaJadwal = _namaJadwalController.text.trim();
    if (namaJadwal.isEmpty || (_selectedAssetId ?? '').isEmpty) {
      showTopNotif(
        context,
        'Nama jadwal dan nama barang wajib diisi.',
        isError: true,
      );
      return;
    }

    final pickedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (pickedDay.isBefore(_minScheduleDate)) {
      showTopNotif(
        context,
        'Tanggal jadwal harus untuk masa mendatang (minimal besok).',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final cleanDigits =
          _estimasiBiayaController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double estimatedCost = double.tryParse(cleanDigits) ?? 0;

      await widget.jadwalService.updateJadwal(
        scheduleId: widget.scheduleId,
        title: namaJadwal,
        assetId: _selectedAssetId!,
        assetName: _selectedAssetName ?? '',
        scheduledAt: scheduledAt,
        maintenanceType: _selectedJenisPerawatan,
        estimatedCost: estimatedCost,
        notes: _catatanController.text,
      );

      if (mounted) {
        final updatedMap = {
          ...widget.data,
          'title': namaJadwal,
          'assetId': _selectedAssetId!,
          'assetName': _selectedAssetName ?? '',
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'maintenanceType': _selectedJenisPerawatan,
          'estimatedCost': estimatedCost,
          'notes': _catatanController.text,
        };
        showTopNotif(context, 'Detail jadwal berhasil diperbarui.');
        Navigator.pop(context, updatedMap);
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal memperbarui jadwal: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _namaJadwalController.dispose();
    _estimasiBiayaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  InputDecoration _glassInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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
              'Edit Detail Jadwal',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Jadwal', isDark),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _namaJadwalController,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration:
                          _glassInputDecoration('Masukkan nama jadwal...'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Nama Barang', isDark),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: widget.jadwalService.streamDaftarBarang(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final assetNames = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        return (data?['name'] ?? 'Tanpa Nama').toString();
                      }).toList();

                      String? activeName;
                      if (_selectedAssetId != null &&
                          docs.any((d) => d.id == _selectedAssetId)) {
                        final selectedDoc =
                            docs.firstWhere((d) => d.id == _selectedAssetId);
                        final selectedData =
                            selectedDoc.data() as Map<String, dynamic>?;
                        activeName = (selectedData?['name'] ?? '').toString();
                      }

                      return LiquidGlassSurface(
                        borderRadius: 14,
                        blurSigma: 14,
                        child: CustomAppDropdown(
                          value: activeName,
                          items: assetNames,
                          hint: _selectedAssetName?.isNotEmpty == true
                              ? _selectedAssetName!
                              : (docs.isEmpty
                                  ? 'Belum ada data barang'
                                  : 'Pilih nama barang'),
                          enabled: !_isSaving && docs.isNotEmpty,
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          textStyle:
                              TextStyle(fontSize: 14, color: textPrimary),
                          onChanged: (selectedName) {
                            final idx = assetNames.indexOf(selectedName);
                            if (idx != -1) {
                              setState(() {
                                _selectedAssetId = docs[idx].id;
                                _selectedAssetName = selectedName;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Tanggal Jadwal', isDark),
                            const SizedBox(height: 8),
                            LiquidGlassSurface(
                              height: 48,
                              borderRadius: 14,
                              blurSigma: 14,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onTap: _pilihTanggal,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatTanggal(_selectedDate),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Jam Jadwal', isDark),
                            const SizedBox(height: 8),
                            LiquidGlassSurface(
                              height: 48,
                              borderRadius: 14,
                              blurSigma: 14,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onTap: _pilihJam,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatJam(_selectedTime),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Jenis Perawatan', isDark),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: CustomAppDropdown(
                      value: _selectedJenisPerawatan,
                      items: _jenisPerawatanList,
                      hint: 'Pilih jenis perawatan',
                      enabled: !_isSaving,
                      fillColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      textStyle: TextStyle(fontSize: 14, color: textPrimary),
                      onChanged: (val) {
                        setState(() => _selectedJenisPerawatan = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Estimasi Biaya Perawatan', isDark),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _estimasiBiayaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onBiayaChanged,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: _glassInputDecoration('0').copyWith(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 4),
                          child: Text(
                            'Rp',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Catatan Tambahan (Opsional)', isDark),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration:
                          _glassInputDecoration('Masukkan catatan tambahan...'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LiquidGlassButton(
                    width: double.infinity,
                    height: 52,
                    borderRadius: 16,
                    tintColor: primaryBlue,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _simpanPerubahan,
                    child: Text(
                      'Perbarui',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}