import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/asset_service.dart';
import '../utils/custom_app_dropdown.dart';
import '../utils/liquid_glass_button.dart';
import '../utils/liquid_glass_kit.dart';
import '../utils/top_notif.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final AssetService _assetService = AssetService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _conditionDetailController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  File? _selectedImage;
  String? _selectedCategory;
  String? _selectedCondition;
  DateTime? _purchaseDate;
  DateTime? _secondHandPurchaseDate;
  bool _isSaving = false;

  final List<String> _categories = const [
    'Elektronik',
    'Kendaraan',
    'Furnitur',
    'Peralatan Rumah',
    'Gadget',
    'Olahraga & Hobi',
    'Umum',
    'Lainnya',
  ];

  final List<String> _conditionOptions = const [
    'Bagus',
    'Baret',
    'Jelek',
    'Rusak',
  ];

  static const List<String> _bulanSingkat = [
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
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _conditionDetailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _selectedImage != null ||
        _nameController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _purchaseDate != null ||
        _priceController.text.trim().isNotEmpty ||
        _selectedCondition != null ||
        _conditionDetailController.text.trim().isNotEmpty ||
        _secondHandPurchaseDate != null ||
        _notesController.text.trim().isNotEmpty;
  }

  String _getConditionDetailHint() {
    switch (_selectedCondition) {
      case 'Rusak':
        return 'Jelaskan kerusakan barang dan penyebabnya...';
      case 'Baret':
        return 'Jelaskan bagian barang yang baret...';
      case 'Jelek':
        return 'Jelaskan bagian kondisi barang yang kurang baik...';
      default:
        return 'Jelaskan rincian kondisi barang...';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal mengambil foto: $e', isError: true);
      }
    }
  }

  void _showImageSourceSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final iconBg = isDark
        ? const Color(0xFF004AAD).withValues(alpha: 0.25)
        : const Color(0xFFDBEAFE);
    final iconColor =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF004AAD);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: LiquidGlassSurface(
            borderRadius: 24,
            blurSigma: 22,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Pilih Sumber Foto',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: iconColor,
                      ),
                    ),
                    title: Text(
                      'Ambil Foto dari Kamera',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Gunakan kamera perangkat untuk memotret barang',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: iconColor,
                      ),
                    ),
                    title: Text(
                      'Pilih dari Galeri',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Pilih foto barang yang sudah tersimpan di HP',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 6),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                      ),
                      title: Text(
                        'Hapus Foto Terpilih',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.red.shade400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() => _selectedImage = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBackPress() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;

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
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anda memiliki perubahan yang belum disimpan,\nApakah Anda yakin ingin keluar tanpa menyimpan?',
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
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Lanjutkan Edit',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidGlassButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          height: 44,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Text(
                            'Keluar',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 13.5,
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

  String _formatTanggalIndo(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month - 1]} ${date.year}';
  }

  String _formatRibuan(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _pickDate({required bool isSecondHand}) async {
    if (!isSecondHand && _secondHandPurchaseDate != null) return;
    if (isSecondHand && _purchaseDate != null) return;

    final now = DateTime.now();
    final initial = isSecondHand
        ? (_secondHandPurchaseDate ?? now)
        : (_purchaseDate ?? now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF004AAD),
                    onPrimary: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF004AAD),
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isSecondHand) {
          _secondHandPurchaseDate = picked;
          _purchaseDate = null;
        } else {
          _purchaseDate = picked;
          _secondHandPurchaseDate = null;
        }
      });
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      showTopNotif(
        context,
        'Silakan pilih kategori barang terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (_purchaseDate == null && _secondHandPurchaseDate == null) {
      showTopNotif(
        context,
        'Silakan pilih Tanggal Beli (baru) atau Tanggal Pembelian (Barang Second).',
        isError: true,
      );
      return;
    }

    if (_selectedCondition == null) {
      showTopNotif(
        context,
        'Silakan pilih kondisi barang terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (_selectedCondition != 'Bagus' &&
        _conditionDetailController.text.trim().isEmpty) {
      showTopNotif(
        context,
        'Harap isi rincian kondisi untuk barang dengan status $_selectedCondition.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String uploadedPhotoUrl = '';
      if (_selectedImage != null) {
        uploadedPhotoUrl =
            await _assetService.uploadAssetImage(_selectedImage!);
      }

      final rawPrice = _priceController.text.replaceAll('.', '').trim();
      final formattedPrice =
          rawPrice.isEmpty ? 'Rp 0' : 'Rp ${_formatRibuan(rawPrice)}';

      final bool isSecondHand = _secondHandPurchaseDate != null;
      final String activeDateFormatted = isSecondHand
          ? _formatTanggalIndo(_secondHandPurchaseDate!)
          : _formatTanggalIndo(_purchaseDate!);

      await _assetService.addAsset({
        'name': _nameController.text.trim(),
        'category': _selectedCategory!,
        'purchaseType': isSecondHand ? 'Second' : 'Baru',
        'purchaseDate': activeDateFormatted,
        'secondHandPurchaseDate': isSecondHand ? activeDateFormatted : '',
        'purchasePrice': formattedPrice,
        'condition': _selectedCondition!,
        'conditionDetail': _conditionDetailController.text.trim(),
        'notes': _notesController.text.trim(),
        'photoUrl': uploadedPhotoUrl,
        'lastMaintenance': '-',
        'lastMaintenanceCost': 'Rp 0',
        'maintenanceDetail': '',
      });

      if (mounted) {
        showTopNotif(context, 'Barang berhasil ditambahkan.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showTopNotif(context, 'Gagal menyimpan barang: $e', isError: true);
      }
    }
  }

  InputDecoration _glassInputDecoration(
    String hint, {
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;

    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final bool isRegularDisabled = _secondHandPurchaseDate != null;
    final bool isSecondHandDisabled = _purchaseDate != null;

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
              onPressed: _isSaving ? null : _handleBackPress,
            ),
            title: Text(
              'Tambah Barang Baru',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LiquidGlassSurface(
                      width: double.infinity,
                      height: _selectedImage != null ? 190 : null,
                      borderRadius: 16,
                      blurSigma: 14,
                      padding: _selectedImage != null
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(vertical: 22),
                      onTap: _isSaving ? null : _showImageSourceSheet,
                      child: _selectedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: LiquidGlassSurface(
                                    borderRadius: 20,
                                    blurSigma: 14,
                                    tintColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Ganti Foto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(
                                  Icons.photo_camera_outlined,
                                  size: 36,
                                  color: accentBlue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unggah Foto Barang',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: accentBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ambil Foto atau Pilih dari Galeri',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Nama Barang',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LiquidGlassSurface(
                      borderRadius: 14,
                      blurSigma: 14,
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 13.5, color: textPrimary),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Nama barang wajib diisi'
                            : null,
                        decoration:
                            _glassInputDecoration('Masukkan nama barang...'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Kategori',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LiquidGlassSurface(
                      borderRadius: 14,
                      blurSigma: 14,
                      child: CustomAppDropdown(
                        value: _selectedCategory,
                        items: _categories,
                        hint: 'Pilih Kategori Barang...',
                        enabled: !_isSaving,
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                        textStyle: TextStyle(fontSize: 13.5, color: textPrimary),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Pembelian',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isRegularDisabled
                                      ? Colors.grey.shade500
                                      : textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              LiquidGlassSurface(
                                borderRadius: 14,
                                blurSigma: 14,
                                tintColor:
                                    isRegularDisabled ? Colors.grey : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                onTap: isRegularDisabled
                                    ? null
                                    : () => _pickDate(isSecondHand: false),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isRegularDisabled
                                            ? 'Barang second dipilih'
                                            : (_purchaseDate == null
                                                ? 'Tanggal pembelian...'
                                                : _formatTanggalIndo(
                                                    _purchaseDate!)),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isRegularDisabled ||
                                                  _purchaseDate == null
                                              ? Colors.grey.shade500
                                              : textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_purchaseDate != null)
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _purchaseDate = null),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 17,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      )
                                    else ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 17,
                                        color: isRegularDisabled
                                            ? Colors.grey.shade600
                                            : textSecondary,
                                      ),
                                    ],
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
                              Text(
                                'Harga Beli',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              LiquidGlassSurface(
                                borderRadius: 14,
                                blurSigma: 14,
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: textPrimary),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _RibuanFormatter(),
                                  ],
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                          ? 'Wajib diisi'
                                          : null,
                                  decoration: _glassInputDecoration(
                                    '0',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 14,
                                        right: 4,
                                      ),
                                      child: Text(
                                        'Rp',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kondisi Barang',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LiquidGlassSurface(
                      borderRadius: 14,
                      blurSigma: 14,
                      child: CustomAppDropdown(
                        value: _selectedCondition,
                        items: _conditionOptions,
                        hint: 'Pilih Kondisi Barang...',
                        enabled: !_isSaving,
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                        textStyle: TextStyle(fontSize: 13.5, color: textPrimary),
                        onChanged: (val) =>
                            setState(() => _selectedCondition = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rincian Kondisi Barang',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LiquidGlassSurface(
                      borderRadius: 14,
                      blurSigma: 14,
                      child: TextFormField(
                        controller: _conditionDetailController,
                        maxLines: 3,
                        minLines: 2,
                        style: TextStyle(fontSize: 13.5, color: textPrimary),
                        decoration:
                            _glassInputDecoration(_getConditionDetailHint()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tanggal Pembelian (Barang Second)',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isSecondHandDisabled
                            ? Colors.grey.shade500
                            : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LiquidGlassSurface(
                      borderRadius: 14,
                      blurSigma: 14,
                      tintColor: isSecondHandDisabled ? Colors.grey : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      onTap: isSecondHandDisabled
                          ? null
                          : () => _pickDate(isSecondHand: true),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isSecondHandDisabled
                                  ? 'Tanggal pembelian (barang baru) sudah dipilih'
                                  : (_secondHandPurchaseDate == null
                                      ? 'Pilih tanggal pembelian BS...'
                                      : _formatTanggalIndo(
                                          _secondHandPurchaseDate!)),
                              style: TextStyle(
                                fontSize: 13,
                                color: isSecondHandDisabled ||
                                        _secondHandPurchaseDate == null
                                    ? Colors.grey.shade500
                                    : textPrimary,
                              ),
                            ),
                          ),
                          if (_secondHandPurchaseDate != null)
                            GestureDetector(
                              onTap: () => setState(
                                  () => _secondHandPurchaseDate = null),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: isSecondHandDisabled
                                  ? Colors.grey.shade600
                                  : textSecondary,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Catatan Tambahan (Opsional)',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LiquidGlassSurface(
                      borderRadius: 14,
                      blurSigma: 14,
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        minLines: 2,
                        style: TextStyle(fontSize: 13.5, color: textPrimary),
                        decoration: _glassInputDecoration(
                          'Masukkan Catatan Tambahan (opsional)...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    LiquidGlassButton(
                      width: double.infinity,
                      borderRadius: 16,
                      tintColor: primaryBlue,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveAsset,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'Tambah Barang',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
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
      ),
    );
  }
}

class _RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}