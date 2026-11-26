import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/asset_service.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class EksporDataPerawatanScreen extends StatefulWidget {
  final String ownerName;
  final String ownerEmail;

  const EksporDataPerawatanScreen({
    super.key,
    required this.ownerName,
    required this.ownerEmail,
  });

  @override
  State<EksporDataPerawatanScreen> createState() =>
      _EksporDataPerawatanScreenState();
}

class _EksporDataPerawatanScreenState extends State<EksporDataPerawatanScreen> {
  final AssetService _assetService = AssetService();

  static const String _allAssetsValue = '__ALL__';
  String _selectedAssetId = _allAssetsValue;
  late DateTime _selectedMonthYear;
  bool _isExporting = false;

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthYear = DateTime(now.year, now.month);
  }

  // format bulan/tahun
  String _formatBulanTahun(DateTime date) {
    return '${_bulanIndo[date.month]} ${date.year}';
  }

  // format tanggal
  String _formatTanggalIndo(DateTime date) {
    return '${date.day} ${_bulanIndo[date.month]} ${date.year}';
  }

  String _formatRibuan(int number) {
    final digits = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  int _parseCostToInt(dynamic rawCost) {
    if (rawCost == null) return 0;
    if (rawCost is num) return rawCost.round();
    final digits = rawCost.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  DateTime? _extractDate(Map<String, dynamic> data) {
    final completedTs = data['completedAt'] as Timestamp?;
    if (completedTs != null) return completedTs.toDate();

    final createdTs = data['createdAt'] as Timestamp?;
    if (createdTs != null) return createdTs.toDate();

    final rawStr = (data['maintenanceDate'] ?? '').toString().trim();
    final parts = rawStr.split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final monthIdx = _bulanIndo.indexWhere(
        (b) => b.isNotEmpty && b.toLowerCase() == parts[1].toLowerCase(),
      );
      final year = int.tryParse(parts[2]);
      if (day != null && monthIdx != -1 && year != null) {
        return DateTime(year, monthIdx, day);
      }
    }
    return null;
  }

  Future<void> _showMonthYearPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;
    int tempYear = _selectedMonthYear.year;
    int tempMonth = _selectedMonthYear.month;

    final picked = await showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pilih Rentang Bulan',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LiquidGlassSurface(
                    borderRadius: 24,
                    blurSigma: 22,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pilih Rentang Bulan',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => setDialogState(() => tempYear--),
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '$tempYear',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: accentBlue,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setDialogState(() => tempYear++),
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 12,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.3,
                          ),
                          itemBuilder: (context, index) {
                            final monthNum = index + 1;
                            final isSelected = tempMonth == monthNum;
                            return LiquidGlassSurface(
                              borderRadius: 12,
                              blurSigma: 10,
                              tintColor: isSelected ? primaryBlue : null,
                              onTap: () =>
                                  setDialogState(() => tempMonth = monthNum),
                              child: Center(
                                child: Text(
                                  _bulanIndo[monthNum].substring(0, 3),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? accentBlue
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: LiquidGlassButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                height: 42,
                                borderRadius: 12,
                                child: const Text(
                                  'Batal',
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
                                onPressed: () => Navigator.pop(
                                  dialogContext,
                                  DateTime(tempYear, tempMonth),
                                ),
                                height: 42,
                                borderRadius: 12,
                                tintColor: primaryBlue,
                                child: const Text(
                                  'Pilih',
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
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedMonthYear = picked);
    }
  }

  // format/ field pdf
  Future<void> _downloadPdf({
    required List<QueryDocumentSnapshot> filteredDocs,
    required String selectedAssetLabel,
    required int totalCost,
  }) async {
    if (_isExporting) return;

    if (filteredDocs.isEmpty) {
      showTopNotif(
        context,
        'Tidak ada data perawatan untuk filter yang dipilih.',
        isError: true,
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final List<List<String>> tableRows = [];
      for (int i = 0; i < filteredDocs.length; i++) {
        final data = filteredDocs[i].data() as Map<String, dynamic>? ?? {};
        final title =
            (data['title'] ?? data['detail'] ?? 'Perawatan').toString();
        final assetName = (data['assetName'] ?? '-').toString();
        final type = (data['maintenanceType'] ?? 'Perawatan').toString();
        final dt = _extractDate(data);
        final dateStr = dt != null
            ? _formatTanggalIndo(dt)
            : (data['maintenanceDate'] ?? '-').toString();
        final costInt = _parseCostToInt(data['cost']);

        tableRows.add([
          '${i + 1}',
          dateStr,
          assetName,
          title,
          type,
          'Rp ${_formatRibuan(costInt)}',
        ]);
      }

      final pdf = pw.Document();
      final primaryPdfColor = PdfColor.fromHex('#004AAD');
      final lightBlueBg = PdfColor.fromHex('#DBEAFE');
      final zebraRowBg = PdfColor.fromHex('#F8FAFC');
      final borderPdfColor = PdfColor.fromHex('#CBD5E1');
      final printedDate = _formatTanggalIndo(DateTime.now());
      final periodeLabel = _formatBulanTahun(_selectedMonthYear);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryPdfColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LAPORAN RIWAYAT PERAWATAN',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Keepora - Barang: $selectedAssetLabel | Bulan: $periodeLabel',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          widget.ownerName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          widget.ownerEmail,
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Dicetak: $printedDate',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
            ],
          ),
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderPdfColor, width: 0.6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Laporan Riwayat Perawatan - Keepora',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                color: lightBlueBg,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Perawatan: ${filteredDocs.length} Perawatan ($selectedAssetLabel)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryPdfColor,
                    ),
                  ),
                  pw.Text(
                    'Total Biaya: Rp ${_formatRibuan(totalCost)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryPdfColor,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'No',
                'Tanggal',
                'Nama Barang',
                'Rincian Perawatan',
                'Jenis',
                'Biaya',
              ],
              data: tableRows,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9.5,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryPdfColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              oddRowDecoration: pw.BoxDecoration(color: zebraRowBg),
              border: pw.TableBorder.all(color: borderPdfColor, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),
                1: const pw.FixedColumnWidth(72),
                2: const pw.FlexColumnWidth(2.2),
                3: const pw.FlexColumnWidth(2.8),
                4: const pw.FixedColumnWidth(68),
                5: const pw.FixedColumnWidth(78),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
              },
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final monthStr = _selectedMonthYear.month.toString().padLeft(2, '0');
      final fileName =
          'Laporan_Perawatan_Keepora_${_selectedMonthYear.year}$monthStr.pdf';

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      if (mounted) {
        showTopNotif(
          context,
          'Gagal membuat laporan PDF: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF004AAD);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: _isExporting ? null : () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textPrimary),
          ),
          title: Text(
            'Ekspor Data Perawatan',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _assetService.getAssetsStream(),
          builder: (context, assetsSnapshot) {
            final assetDocs = assetsSnapshot.data?.docs ?? [];
            final Map<String, String> assetNameMap = {
              _allAssetsValue: 'Semua Barang',
            };
            for (final doc in assetDocs) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              assetNameMap[doc.id] = (data['name'] ?? 'Barang').toString();
            }

            if (!assetNameMap.containsKey(_selectedAssetId)) {
              _selectedAssetId = _allAssetsValue;
            }
            final selectedAssetLabel =
                assetNameMap[_selectedAssetId] ?? 'Semua Barang';

            return StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _assetService.getAllMaintenanceHistoryStream(),
              builder: (context, historySnapshot) {
                final allHistoryDocs = historySnapshot.data ?? [];

                final filteredDocs = allHistoryDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final docAssetId = (data['assetId'] ??
                          doc.reference.parent.parent?.id ??
                          '')
                      .toString();

                  if (_selectedAssetId != _allAssetsValue &&
                      docAssetId != _selectedAssetId) {
                    return false;
                  }

                  final dt = _extractDate(data);
                  if (dt == null) return false;
                  return dt.year == _selectedMonthYear.year &&
                      dt.month == _selectedMonthYear.month;
                }).toList()
                  ..sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>? ?? {};
                    final dataB = b.data() as Map<String, dynamic>? ?? {};
                    final dateA = _extractDate(dataA) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final dateB = _extractDate(dataB) ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return dateB.compareTo(dateA);
                  });

                int totalCost = 0;
                for (final doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  totalCost += _parseCostToInt(data['cost']);
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Format Laporan
                            Text(
                              'Format Laporan',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LiquidGlassSurface(
                              width: double.infinity,
                              height: 50,
                              borderRadius: 14,
                              blurSigma: 14,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 21,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dokumen PDF',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Pilih Barang
                            Text(
                              'Pilih Barang',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LiquidGlassSurface(
                              width: double.infinity,
                              height: 50,
                              borderRadius: 14,
                              blurSigma: 14,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedAssetId,
                                  isExpanded: true,
                                  dropdownColor: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: textSecondary,
                                    size: 24,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                  items: assetNameMap.entries.map((entry) {
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(
                                        entry.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isExporting
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setState(
                                                () => _selectedAssetId = val);
                                          }
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Rentang Waktu
                            Text(
                              'Rentang Waktu',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LiquidGlassSurface(
                              width: double.infinity,
                              height: 50,
                              borderRadius: 14,
                              blurSigma: 14,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              onTap:
                                  _isExporting ? null : _showMonthYearPicker,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Bulan ${_formatBulanTahun(_selectedMonthYear)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Estimasi Laporan
                            Text(
                              'Estimasi Laporan',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LiquidGlassSurface(
                              width: double.infinity,
                              borderRadius: 16,
                              blurSigma: 16,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ringkasan Laporan',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildSummaryRow(
                                    label: 'Total Perawatan',
                                    value: '${filteredDocs.length} Perawatan',
                                    textColor: textSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildSummaryRow(
                                    label: 'Total Biaya',
                                    value: 'Rp ${_formatRibuan(totalCost)}',
                                    textColor: textSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildSummaryRow(
                                    label: 'Barang',
                                    value: selectedAssetLabel,
                                    textColor: textSecondary,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildSummaryRow(
                                    label: 'Bulan',
                                    value: _formatBulanTahun(_selectedMonthYear),
                                    textColor: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: LiquidGlassButton(
                          width: double.infinity,
                          height: 52,
                          borderRadius: 16,
                          tintColor: primaryBlue,
                          isLoading: _isExporting,
                          onPressed: _isExporting
                              ? null
                              : () => _downloadPdf(
                                    filteredDocs: filteredDocs,
                                    selectedAssetLabel: selectedAssetLabel,
                                    totalCost: totalCost,
                                  ),
                          child: Text(
                            'Unduh Laporan',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(fontSize: 13.5, color: textColor),
          ),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.5, color: textColor),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: 13.5, color: textColor),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}