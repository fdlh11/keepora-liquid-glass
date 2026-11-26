import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/asset_service.dart';
import '../utils/top_notif.dart';
import '../utils/custom_app_dropdown.dart';

class EditRiwayatScreen extends StatefulWidget {
  final String assetId;
  final String historyId;
  final Map<String, dynamic> data;
  final AssetService assetService;

  const EditRiwayatScreen({
    super.key,
    required this.assetId,
    required this.historyId,
    required this.data,
    required this.assetService,
  });

  @override
  State<EditRiwayatScreen> createState() => _EditRiwayatScreenState();
}

class _EditRiwayatScreenState extends State<EditRiwayatScreen> {
  late TextEditingController _namaJadwalController;
  late TextEditingController _biayaController;
  late TextEditingController _catatanController;

  late String _selectedJenisPerawatan;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  late String _initialTitle;
  late String _initialJenisPerawatan;
  late DateTime _initialDate;
  late TimeOfDay _initialTime;
  late String _initialCostDigits;
  late String _initialNotes;

  final List<String> _jenisPerawatanOptions = const [
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

  @override
  void initState() {
    super.initState();
    final rawTitle = (widget.data['title'] ?? '').toString().trim();
    final rawDetail =
        (widget.data['detail'] ?? widget.data['notes'] ?? '').toString().trim();
    final assetName = (widget.data['assetName'] ?? '').toString();

    _initialTitle = rawTitle.isNotEmpty
        ? rawTitle
        : (rawDetail.isNotEmpty ? rawDetail : 'Perawatan $assetName');
    _namaJadwalController = TextEditingController(text: _initialTitle);

    final rawCost = widget.data['cost'];
    final int initialCost = rawCost is num
        ? rawCost.round()
        : int.tryParse(
              (rawCost ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
    _initialCostDigits = initialCost.toString();
    _biayaController = TextEditingController(
      text: _formatThousand(initialCost),
    );

    _initialNotes = rawDetail;
    _catatanController = TextEditingController(text: _initialNotes);

    final rawType =
        (widget.data['maintenanceType'] ?? 'Perawatan').toString().trim();
    _initialJenisPerawatan = _jenisPerawatanOptions.firstWhere(
      (item) => item.toLowerCase() == rawType.toLowerCase(),
      orElse: () => _jenisPerawatanOptions.first,
    );
    _selectedJenisPerawatan = _initialJenisPerawatan;

    final ts = (widget.data['completedAt'] as Timestamp?) ??
        (widget.data['createdAt'] as Timestamp?);
    final dt = ts?.toDate() ?? DateTime.now();
    _initialDate = DateTime(dt.year, dt.month, dt.day);
    _initialTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    _selectedDate = _initialDate;
    _selectedTime = _initialTime;
  }

  @override
  void dispose() {
    _namaJadwalController.dispose();
    _biayaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final rawDigits = _biayaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final currentCostDigits = (int.tryParse(rawDigits) ?? 0).toString();

    return _namaJadwalController.text.trim() != _initialTitle.trim() ||
        _selectedJenisPerawatan != _initialJenisPerawatan ||
        _selectedDate.year != _initialDate.year ||
        _selectedDate.month != _initialDate.month ||
        _selectedDate.day != _initialDate.day ||
        _selectedTime.hour != _initialTime.hour ||
        _selectedTime.minute != _initialTime.minute ||
        currentCostDigits != _initialCostDigits ||
        _catatanController.text.trim() != _initialNotes.trim();
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
                'Anda sedang mengedit riwayat. Data yang sudah diisi akan hilang jika Anda keluar.',
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

  String _formatThousand(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatTanggal(DateTime dt) {
    return '${dt.day} ${_bulanSingkat[dt.month]} ${dt.year}';
  }

  String _formatJam(TimeOfDay time) {
    final jam = time.hour.toString().padLeft(2, '0');
    final menit = time.minute.toString().padLeft(2, '0');
    return '$jam:$menit WIB';
  }

  Future<void> _pilihTanggal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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
                    primary: Color(0xFF004AAD),
                    onPrimary: Colors.white,
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
    if (namaJadwal.isEmpty) {
      showTopNotif(context, 'Nama jadwal wajib diisi.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final digits =
          _biayaController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final int costInt = int.tryParse(digits) ?? 0;

      await widget.assetService.updateMaintenanceRecord(
        assetId: widget.assetId,
        historyId: widget.historyId,
        title: namaJadwal,
        maintenanceType: _selectedJenisPerawatan,
        maintenanceDate: _formatTanggal(_selectedDate),
        completedAtDate: combinedDateTime,
        cost: costInt,
        detail: _catatanController.text,
      );

      if (mounted) {
        showTopNotif(context, 'Riwayat perawatan berhasil diperbarui.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal memperbarui riwayat: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final assetName = (widget.data['assetName'] ?? '-').toString();

    final bgColor = theme.scaffoldBackgroundColor;
    final fieldFillColor = isDark ? theme.colorScheme.surface : Colors.white;
    final textPrimary = theme.colorScheme.onSurface;
    final textFieldColor =
        isDark ? Colors.grey.shade200 : Colors.grey.shade800;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;

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
            onPressed: _isSaving ? null : _handleBackPress,
          ),
          title: Text(
            'Edit Riwayat Perawatan',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nama Jadwal', textPrimary),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaJadwalController,
                  style: TextStyle(fontSize: 13.5, color: textFieldColor),
                  decoration: _inputDecoration(
                    'Masukkan nama jadwal...',
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Nama Barang', textPrimary),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: fieldFillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    assetName,
                    style: TextStyle(fontSize: 13.5, color: textFieldColor),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('Jenis Perawatan', textPrimary),
                const SizedBox(height: 8),
                CustomAppDropdown(
                  value: _selectedJenisPerawatan,
                  items: _jenisPerawatanOptions,
                  hint: 'Pilih jenis perawatan',
                  enabled: !_isSaving,
                  fillColor: fieldFillColor,
                  borderColor: borderColor,
                  textStyle: TextStyle(fontSize: 13.5, color: textFieldColor),
                  onChanged: (val) {
                    setState(() => _selectedJenisPerawatan = val);
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
                          _buildLabel('Tanggal Perawatan', textPrimary),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pilihTanggal,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: fieldFillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatTanggal(_selectedDate),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: textFieldColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
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
                          _buildLabel('Jam Perawatan', textPrimary),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pilihJam,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: fieldFillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatJam(_selectedTime),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: textFieldColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
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
                _buildLabel('Biaya Perawatan', textPrimary),
                const SizedBox(height: 8),
                TextField(
                  controller: _biayaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _RibuanInputFormatter(),
                  ],
                  style: TextStyle(fontSize: 13.5, color: textFieldColor),
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
                          fontSize: 13.5,
                          color: textFieldColor,
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
                  style: TextStyle(fontSize: 13.5, color: textFieldColor),
                  decoration: _inputDecoration(
                    'Masukkan catatan tambahan...',
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(height: 44),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpanPerubahan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Simpan Perubahan',
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

class _RibuanInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final number = int.parse(digits);
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}