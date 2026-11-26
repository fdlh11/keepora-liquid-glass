import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jadwal_service.dart';
import '../utils/top_notif.dart';
import '../utils/custom_app_dropdown.dart';

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
    final bool? shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
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
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF004AAD),
                          side: const BorderSide(
                            color: Color(0xFF64A1F4),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                  ),
                ],
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);

    final bgColor = theme.scaffoldBackgroundColor;
    final fieldFillColor = isDark ? theme.colorScheme.surface : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
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
                TextField(
                  controller: _namaJadwalController,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: _inputDecoration(
                    'Masukkan nama jadwal...',
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
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

                    return CustomAppDropdown(
                      value: activeName,
                      items: assetNames,
                      hint: docs.isEmpty
                          ? 'Belum ada data barang'
                          : 'Pilih nama barang',
                      enabled: !_isLoading && docs.isNotEmpty,
                      fillColor: fieldFillColor,
                      borderColor: borderColor,
                      textStyle: TextStyle(fontSize: 14, color: textPrimary),
                      onChanged: (selectedName) {
                        final idx = assetNames.indexOf(selectedName);
                        if (idx != -1) {
                          setState(() {
                            _selectedAssetId = docs[idx].id;
                            _selectedAssetName = selectedName;
                          });
                        }
                      },
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
                          InkWell(
                            onTap: _pilihTanggal,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: fieldFillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
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
                          InkWell(
                            onTap: _pilihJam,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: fieldFillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildLabel('Jenis Perawatan', textPrimary),
                const SizedBox(height: 8),
                CustomAppDropdown(
                  value: _selectedJenisPerawatan,
                  items: _jenisPerawatanList,
                  hint: 'Pilih jenis perawatan',
                  enabled: !_isLoading,
                  fillColor: fieldFillColor,
                  borderColor: borderColor,
                  textStyle: TextStyle(fontSize: 14, color: textPrimary),
                  onChanged: (val) =>
                      setState(() => _selectedJenisPerawatan = val),
                ),

                const SizedBox(height: 16),

                _buildLabel('Estimasi Biaya Perawatan', textPrimary),
                const SizedBox(height: 8),
                TextField(
                  controller: _estimasiBiayaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onBiayaChanged,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: _inputDecoration(
                    '0',
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
                  ).copyWith(
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

                const SizedBox(height: 16),

                _buildLabel('Catatan Tambahan (Opsional)', textPrimary),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatanController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: _inputDecoration(
                    'Masukkan Catatan Tambahan (opsional)...',
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpanJadwal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Tambah Jadwal',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
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

  InputDecoration _inputDecoration(
    String hint, {
    required Color fillColor,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF004AAD), width: 1.4),
      ),
    );
  }
}