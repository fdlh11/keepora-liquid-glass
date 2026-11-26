import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jadwal_service.dart';
import '../utils/custom_app_dropdown.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class TambahJadwalScreen extends StatefulWidget {
  const TambahJadwalScreen({super.key});

  @override
  State<TambahJadwalScreen> createState() => _TambahJadwalScreenState();
}

class _TambahJadwalScreenState extends State<TambahJadwalScreen> {
  final JadwalService _jadwalService = JadwalService();
  final TextEditingController _namaJadwalController = TextEditingController();
  final TextEditingController _estimasiBiayaController =
      TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _selectedAssetId;
  String? _selectedAssetName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedJenisPerawatan;
  bool _isLoading = false;

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

  bool get _hasUnsavedChanges {
    return _namaJadwalController.text.trim().isNotEmpty ||
        _selectedAssetId != null ||
        _selectedDate != null ||
        _selectedTime != null ||
        _selectedJenisPerawatan != null ||
        _estimasiBiayaController.text.trim().isNotEmpty ||
        _catatanController.text.trim().isNotEmpty;
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
                    'Anda sedang mengisi jadwal baru. Data yang sudah diisi akan hilang jika Anda keluar.',
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
                              'Lanjutkan Mengisi',
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

  Future<void> _pilihTanggal() async {
    final minDate = _minScheduleDate;
    final initial = (_selectedDate != null && !_selectedDate!.isBefore(minDate))
        ? _selectedDate!
        : minDate;
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
                    primary: Color(0xFF004AAD),
                    onPrimary: Colors.white,
                  )
                : const ColorScheme.light(primary: Color(0xFF004AAD)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pilihJam() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF004AAD),
                    onPrimary: Colors.white,
                  )
                : const ColorScheme.light(primary: Color(0xFF004AAD)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _simpanJadwal() async {
    final namaJadwal = _namaJadwalController.text.trim();

    if (namaJadwal.isEmpty ||
        _selectedAssetId == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedJenisPerawatan == null) {
      showTopNotif(
        context,
        'Harap lengkapi semua kolom wajib terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final pickedDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    if (pickedDay.isBefore(_minScheduleDate)) {
      showTopNotif(
        context,
        'Tanggal jadwal harus untuk masa mendatang (minimal besok).',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final scheduledAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final cleanDigits =
          _estimasiBiayaController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double estimatedCost = double.tryParse(cleanDigits) ?? 0;

      await _jadwalService.tambahJadwal(
        title: namaJadwal,
        assetId: _selectedAssetId!,
        assetName: _selectedAssetName ?? '',
        scheduledAt: scheduledAt,
        maintenanceType: _selectedJenisPerawatan!,
        estimatedCost: estimatedCost,
        notes: _catatanController.text,
      );

      if (mounted) {
        showTopNotif(context, 'Jadwal perawatan berhasil ditambahkan.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal menyimpan jadwal: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    const primaryBlue = Color(0xFF004AAD);

    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

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
              icon: Icon(Icons.arrow_back, color: textPrimary),
              onPressed: _isLoading ? null : _handleBackPress,
            ),
            title: Text(
              'Tambah Jadwal Baru',
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
                  _buildLabel('Nama Jadwal', textPrimary),
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

                  _buildLabel('Nama Barang', textPrimary),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: _jadwalService.streamDaftarBarang(),
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
                          hint: docs.isEmpty
                              ? 'Belum ada data barang'
                              : 'Pilih nama barang',
                          enabled: !_isLoading && docs.isNotEmpty,
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
                            _buildLabel('Tanggal Jadwal', textPrimary),
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
                                      _selectedDate != null
                                          ? _formatTanggal(_selectedDate!)
                                          : 'Pilih Tanggal Jadwal',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _selectedDate != null
                                            ? textPrimary
                                            : Colors.grey.shade500,
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
                            _buildLabel('Jam Jadwal', textPrimary),
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
                                      _selectedTime != null
                                          ? _formatJam(_selectedTime!)
                                          : 'Pilih Jam',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _selectedTime != null
                                            ? textPrimary
                                            : Colors.grey.shade500,
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

                  _buildLabel('Jenis Perawatan', textPrimary),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: CustomAppDropdown(
                      value: _selectedJenisPerawatan,
                      items: _jenisPerawatanList,
                      hint: 'Pilih jenis perawatan',
                      enabled: !_isLoading,
                      fillColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      textStyle: TextStyle(fontSize: 14, color: textPrimary),
                      onChanged: (val) =>
                          setState(() => _selectedJenisPerawatan = val),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Estimasi Biaya Perawatan', textPrimary),
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

                  _buildLabel('Catatan Tambahan (Opsional)', textPrimary),
                  const SizedBox(height: 8),
                  LiquidGlassSurface(
                    borderRadius: 14,
                    blurSigma: 14,
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: _glassInputDecoration(
                        'Masukkan Catatan Tambahan (opsional)...',
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  LiquidGlassButton(
                    width: double.infinity,
                    height: 52,
                    borderRadius: 16,
                    tintColor: primaryBlue,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _simpanJadwal,
                    child: Text(
                      'Tambah Jadwal',
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

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}