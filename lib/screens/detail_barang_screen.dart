import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/asset_service.dart';
import '../utils/custom_app_dropdown.dart';
import '../utils/top_notif.dart';

class DetailBarangScreen extends StatefulWidget {
  final String assetId;

  const DetailBarangScreen({super.key, required this.assetId});

  @override
  State<DetailBarangScreen> createState() => _DetailBarangScreenState();
}

class _DetailBarangScreenState extends State<DetailBarangScreen>
    with SingleTickerProviderStateMixin {
  final AssetService _assetService = AssetService();
  final ImagePicker _picker = ImagePicker();
  late final Stream<QuerySnapshot> _assetsStream;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _conditionDetailController =
      TextEditingController();
  final TextEditingController _maintenanceDetailController =
      TextEditingController();

  // Controller & Overlay untuk Dropdown Pill Kategori
  final LayerLink _categoryLayerLink = LayerLink();
  final GlobalKey _categoryChipKey = GlobalKey();
  OverlayEntry? _categoryOverlayEntry;
  bool _isCategoryMenuOpen = false;
  late final AnimationController _catAnimController;
  late final Animation<double> _catFadeAnim;
  late final Animation<double> _catScaleAnim;

  bool _isInitialized = false;
  bool _isSaving = false;
  Map<String, dynamic>? _cachedAssetData;
  File? _newSelectedImage;

  String _selectedCategory = 'Umum';
  String _selectedCondition = 'Bagus';
  String _purchaseDate = '';
  DateTime? _selectedPurchaseDate;

  String _initialName = '';
  String _initialCategory = 'Umum';
  String _initialPurchaseDate = '';
  String _initialPurchasePriceDigits = '';
  String _initialCondition = 'Bagus';
  String _initialConditionDetail = '';
  String _initialMaintenanceDetail = '';

  static const List<String> _defaultCategories = [
    'Elektronik',
    'Kendaraan',
    'Furnitur',
    'Peralatan Rumah',
    'Gadget',
    'Olahraga & Hobi',
    'Umum',
    'Lainnya',
  ];

  static const List<String> _conditionOptions = [
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

  static const Map<String, int> _mapBulanKeAngka = {
    'jan': 1,
    'januari': 1,
    'feb': 2,
    'februari': 2,
    'mar': 3,
    'maret': 3,
    'apr': 4,
    'april': 4,
    'mei': 5,
    'jun': 6,
    'juni': 6,
    'jul': 7,
    'juli': 7,
    'agu': 8,
    'agustus': 8,
    'sep': 9,
    'september': 9,
    'okt': 10,
    'oktober': 10,
    'nov': 11,
    'november': 11,
    'des': 12,
    'desember': 12,
  };

  @override
  void initState() {
    super.initState();
    _assetsStream = _assetService.getAssetsStream();
    _catAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _catFadeAnim = CurvedAnimation(
      parent: _catAnimController,
      curve: Curves.easeOut,
    );
    _catScaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _catAnimController, curve: Curves.easeOutCubic),
    );

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && mounted) {
        if (_nameController.text.trim().isEmpty) {
          setState(() {
            _nameController.text = _initialName;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _removeCategoryOverlayImmediate();
    _catAnimController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _purchasePriceController.dispose();
    _conditionDetailController.dispose();
    _maintenanceDetailController.dispose();
    super.dispose();
  }

  void _removeCategoryOverlayImmediate() {
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
    _isCategoryMenuOpen = false;
  }

  Future<void> _closeCategoryMenu() async {
    if (!_isCategoryMenuOpen) return;
    await _catAnimController.reverse();
    _removeCategoryOverlayImmediate();
    if (mounted) setState(() {});
  }

  void _toggleCategoryMenu(List<String> categoryOptions) {
    if (_isSaving) return;
    if (_isCategoryMenuOpen) {
      _closeCategoryMenu();
      return;
    }

    FocusScope.of(context).unfocus();
    final renderBox =
        _categoryChipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final chipSize = renderBox.size;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;
    final menuBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final menuBorder =
        isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    const double menuWidth = 190;

    _categoryOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeCategoryMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _categoryLayerLink,
              showWhenUnlinked: false,
              offset: Offset(chipSize.width - menuWidth, chipSize.height + 6),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _catFadeAnim,
                  child: ScaleTransition(
                    scale: _catScaleAnim,
                    alignment: Alignment.topRight,
                    child: Container(
                      width: menuWidth,
                      constraints: const BoxConstraints(maxHeight: 205),
                      decoration: BoxDecoration(
                        color: menuBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: menuBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.45 : 0.12,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: categoryOptions.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final cat = categoryOptions[index];
                            final isSelected = cat == _selectedCategory;

                            return InkWell(
                              onTap: () async {
                                setState(() => _selectedCategory = cat);
                                await _closeCategoryMenu();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                color: isSelected
                                    ? primaryBlue.withValues(
                                        alpha: isDark ? 0.22 : 0.08,
                                      )
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? accentBlue
                                              : textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: accentBlue,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_categoryOverlayEntry!);
    setState(() => _isCategoryMenuOpen = true);
    _catAnimController.forward();
  }

  Future<void> _pickNewImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _newSelectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        showTopNotif(context, 'Gagal mengambil foto: $e', isError: true);
      }
    }
  }

  void _showPhotoPreviewDialog(String currentPhotoUrl) {
    final bool hasAnyPhoto =
        _newSelectedImage != null || currentPhotoUrl.trim().isNotEmpty;
    if (!hasAnyPhoto) return;

    Widget buildFullWidthPreview() {
      if (_newSelectedImage != null) {
        return Image.file(
          _newSelectedImage!,
          width: double.infinity,
          fit: BoxFit.contain,
        );
      }

      if (currentPhotoUrl.startsWith('data:image')) {
        try {
          final base64Part = currentPhotoUrl.split(',').last;
          final bytes = base64Decode(base64Part);
          return Image.memory(
            bytes,
            width: double.infinity,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      }

      return Image.network(
        currentPhotoUrl,
        width: double.infinity,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup Preview Foto',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(dialogContext),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: SizedBox(
                        width: double.infinity,
                        child: buildFullWidthPreview(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
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
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showPhotoActionSheet(String currentPhotoUrl) {
    if (_isSaving) return;
    _removeCategoryOverlayImmediate();
    FocusScope.of(context).unfocus();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? theme.colorScheme.surface : Colors.white;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconBg = isDark
        ? const Color(0xFF004AAD).withValues(alpha: 0.25)
        : const Color(0xFFDBEAFE);
    final iconColor =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF004AAD);

    final bool hasPhoto =
        _newSelectedImage != null || currentPhotoUrl.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'Foto Barang',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (hasPhoto) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.visibility_outlined,
                        color: iconColor,
                      ),
                    ),
                    title: Text(
                      'Lihat Foto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Tampilkan preview foto barang ukuran penuh',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showPhotoPreviewDialog(currentPhotoUrl);
                    },
                  ),
                  const SizedBox(height: 6),
                ],
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
                    'Ganti Foto dari Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil foto baru menggunakan kamera perangkat',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickNewImage(ImageSource.camera);
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
                    'Ganti Foto dari Galeri',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih foto barang lain yang tersimpan di HP',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickNewImage(ImageSource.gallery);
                  },
                ),
                if (_newSelectedImage != null) ...[
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
                        Icons.undo_rounded,
                        color: Colors.red.shade400,
                      ),
                    ),
                    title: Text(
                      'Batalkan Foto Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.red.shade400,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _newSelectedImage = null);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTanggalSingkat(DateTime date) {
    return '${date.day} ${_bulanSingkat[date.month - 1]} ${date.year}';
  }

  DateTime? _parseTanggalIndo(String dateStr) {
    final parts = dateStr.trim().split(' ');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _mapBulanKeAngka[parts[1].toLowerCase()];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _singkatkanTanggalString(String rawDate) {
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty || trimmed == '-') return trimmed;
    final parsed = _parseTanggalIndo(trimmed);
    if (parsed != null) return _formatTanggalSingkat(parsed);
    return trimmed;
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

  String _extractDigits(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  List<String> _getCategoryOptions() {
    final options = List<String>.from(_defaultCategories);
    if (_selectedCategory.isNotEmpty && !options.contains(_selectedCategory)) {
      options.insert(0, _selectedCategory);
    }
    return options;
  }

  List<String> _getConditionDropdownOptions() {
    final options = List<String>.from(_conditionOptions);
    if (_selectedCondition.isNotEmpty && !options.contains(_selectedCondition)) {
      options.insert(0, _selectedCondition);
    }
    return options;
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

  bool get _hasUnsavedChanges {
    final currentPriceDigits = _extractDigits(_purchasePriceController.text);
    return _newSelectedImage != null ||
        _nameController.text.trim() != _initialName.trim() ||
        _selectedCategory.trim() != _initialCategory.trim() ||
        _purchaseDate.trim() != _initialPurchaseDate.trim() ||
        currentPriceDigits != _initialPurchasePriceDigits ||
        _selectedCondition.trim() != _initialCondition.trim() ||
        _conditionDetailController.text.trim() !=
            _initialConditionDetail.trim() ||
        _maintenanceDetailController.text.trim() !=
            _initialMaintenanceDetail.trim();
  }

  Future<void> _pickPurchaseDate() async {
    _removeCategoryOverlayImmediate();
    final now = DateTime.now();
    final initial = _selectedPurchaseDate ?? now;
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
        _selectedPurchaseDate = picked;
        _purchaseDate = _formatTanggalSingkat(picked);
      });
    }
  }

  Future<void> _handleBackPress() async {
    _removeCategoryOverlayImmediate();
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

  Future<void> _confirmDeleteAsset() async {
    _removeCategoryOverlayImmediate();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? confirmed = await showDialog<bool>(
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
                'Hapus Barang',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda ingin menghapus barang ini dari daftar? Semua riwayat perawatan juga akan terhapus.',
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
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _assetService.deleteAsset(widget.assetId);
      if (mounted) {
        showTopNotif(context, 'Barang berhasil dihapus.');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveChanges(String purchaseType) async {
    _removeCategoryOverlayImmediate();
    if (_isSaving) return;

    final updatedName = _nameController.text.trim();
    if (updatedName.isEmpty) {
      showTopNotif(
        context,
        'Nama barang tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    final updatedCondition = _selectedCondition.trim();
    final updatedConditionDetail = _conditionDetailController.text.trim();

    if (updatedCondition != 'Bagus' && updatedConditionDetail.isEmpty) {
      showTopNotif(
        context,
        'Harap isi rincian kondisi untuk barang dengan status $updatedCondition.',
        isError: true,
      );
      return;
    }

    _nameFocusNode.unfocus();
    setState(() => _isSaving = true);

    try {
      String? updatedPhotoUrl;
      if (_newSelectedImage != null) {
        updatedPhotoUrl =
            await _assetService.uploadAssetImage(_newSelectedImage!);
      }

      final rawPriceDigits = _extractDigits(_purchasePriceController.text);
      final formattedPrice = rawPriceDigits.isEmpty
          ? 'Rp 0'
          : 'Rp ${_formatRibuan(rawPriceDigits)}';
      final updatedCategory = _selectedCategory.trim();
      final updatedDate = _singkatkanTanggalString(_purchaseDate.trim());
      final updatedDetail = _maintenanceDetailController.text.trim();

      final Map<String, dynamic> updatePayload = {
        'name': updatedName,
        'category': updatedCategory,
        'purchaseDate': updatedDate,
        'purchasePrice': formattedPrice,
        'condition': updatedCondition,
        'conditionDetail': updatedConditionDetail,
        'maintenanceDetail': updatedDetail,
      };

      if (updatedPhotoUrl != null) {
        updatePayload['photoUrl'] = updatedPhotoUrl;
      }

      if (purchaseType == 'Second') {
        updatePayload['secondHandPurchaseDate'] = updatedDate;
      }

      await _assetService.updateAsset(widget.assetId, updatePayload);

      _newSelectedImage = null;
      _initialName = updatedName;
      _initialCategory = updatedCategory;
      _initialPurchaseDate = updatedDate;
      _initialPurchasePriceDigits = rawPriceDigits;
      _initialCondition = updatedCondition;
      _initialConditionDetail = updatedConditionDetail;
      _initialMaintenanceDetail = updatedDetail;

      if (mounted) {
        showTopNotif(context, 'Perubahan berhasil disimpan.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showTopNotif(
          context,
          'Gagal menyimpan perubahan: $e',
          isError: true,
        );
      }
    }
  }

  Widget _infoCard({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _editableBoxDecoration(
    String hint,
    bool isDark, {
    String? prefixText,
  }) {
    final borderColor =
        isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
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

  Widget _buildAssetPhoto(String photoUrl, bool isDark) {
    if (_newSelectedImage != null) {
      return Image.file(
        _newSelectedImage!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    if (photoUrl.isEmpty) return _photoPlaceholder(isDark);

    if (photoUrl.startsWith('data:image')) {
      try {
        final base64Part = photoUrl.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _photoPlaceholder(isDark),
        );
      } catch (_) {
        return _photoPlaceholder(isDark);
      }
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _photoPlaceholder(isDark),
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
        isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : Colors.black;

    return StreamBuilder<QuerySnapshot>(
      stream: _assetsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final matched = docs.where((d) => d.id == widget.assetId).toList();

        if (matched.isNotEmpty) {
          _cachedAssetData = matched.first.data() as Map<String, dynamic>? ?? {};
        }

        if (_cachedAssetData == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: bgColor,
              body: const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            );
          }
          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(backgroundColor: bgColor),
            body: const Center(child: Text('Data barang tidak ditemukan.')),
          );
        }

        final data = _cachedAssetData!;
        final rawName = (data['name'] ?? '-').toString();
        final rawCategory = (data['category'] ?? 'Umum').toString();
        final photoUrl = (data['photoUrl'] ?? '').toString();
        final purchaseType = (data['purchaseType'] ?? 'Baru').toString();
        final rawPurchaseDate = (data['purchaseDate'] ?? '-').toString();
        final rawPurchasePrice = (data['purchasePrice'] ?? 'Rp 0').toString();
        final lastMaintenance = _singkatkanTanggalString(
          (data['lastMaintenance'] ?? '-').toString(),
        );
        final lastMaintenanceCost =
            (data['lastMaintenanceCost'] ?? 'Rp 0').toString();

        if (!_isInitialized) {
          _initialName = rawName;
          _nameController.text = rawName;

          _initialCategory = rawCategory.isEmpty ? 'Umum' : rawCategory;
          _selectedCategory = _initialCategory;

          _selectedPurchaseDate = _parseTanggalIndo(rawPurchaseDate);
          _initialPurchaseDate = _singkatkanTanggalString(rawPurchaseDate);
          _purchaseDate = _initialPurchaseDate;

          _initialPurchasePriceDigits = _extractDigits(rawPurchasePrice);
          _purchasePriceController.text =
              _formatRibuan(_initialPurchasePriceDigits);

          final rawCond = (data['condition'] ?? '').toString().trim();
          _initialCondition = rawCond.isEmpty ? 'Bagus' : rawCond;
          _selectedCondition = _initialCondition;

          _initialConditionDetail =
              (data['conditionDetail'] ?? '').toString();
          _conditionDetailController.text = _initialConditionDetail;

          _initialMaintenanceDetail =
              (data['maintenanceDetail'] ?? '').toString();
          _maintenanceDetailController.text = _initialMaintenanceDetail;
          _isInitialized = true;
        }

        final categoryOptions = _getCategoryOptions();
        final conditionDropdownOptions = _getConditionDropdownOptions();

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
                'Detail Barang',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Hapus Barang',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: _isSaving ? null : _confirmDeleteAsset,
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _showPhotoActionSheet(photoUrl),
                    child: Container(
                      width: double.infinity,
                      height: 205,
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFE5E7EB),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildAssetPhoto(photoUrl, isDark),
                          if (_newSelectedImage != null ||
                              photoUrl.trim().isNotEmpty)
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.62),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_camera_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Lihat / Ganti Foto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                enabled: !_isSaving,
                                maxLines: null,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _nameFocusNode.unfocus(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CompositedTransformTarget(
                              link: _categoryLayerLink,
                              child: GestureDetector(
                                key: _categoryChipKey,
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    _toggleCategoryMenu(categoryOptions),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF172554)
                                        : const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isCategoryMenuOpen
                                          ? primaryBlue
                                          : (isDark
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF93C5FD)),
                                      width: _isCategoryMenuOpen ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    _selectedCategory,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF60A5FA)
                                          : primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Informasi Pembelian',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    purchaseType == 'Second'
                                        ? 'Tanggal Pembelian (Second)'
                                        : 'Tanggal Pembelian',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap:
                                        _isSaving ? null : _pickPurchaseDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _purchaseDate.isEmpty
                                                  ? 'Pilih tanggal...'
                                                  : _purchaseDate,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Harga Pembelian',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 48,
                                    child: TextField(
                                      controller: _purchasePriceController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _RibuanFormatter(),
                                      ],
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      decoration: _editableBoxDecoration(
                                        '0',
                                        isDark,
                                        prefixText: 'Rp ',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Kondisi Barang',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomAppDropdown(
                          value: _selectedCondition,
                          items: conditionDropdownOptions,
                          hint: 'Pilih kondisi barang...',
                          enabled: !_isSaving,
                          fillColor: surfaceColor,
                          borderColor: borderColor,
                          textStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onChanged: (val) {
                            setState(() => _selectedCondition = val);
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Rincian Kondisi Barang',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _conditionDetailController,
                          maxLines: 3,
                          minLines: 2,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.35,
                          ),
                          decoration: _editableBoxDecoration(
                            _getConditionDetailHint(),
                            isDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Catatan Perawatan Terakhir',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                label: 'Tanggal Perawatan Terakhir',
                                value: lastMaintenance,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _infoCard(
                                label: 'Biaya Perawatan Terakhir',
                                value: lastMaintenanceCost,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Rincian Perawatan',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _maintenanceDetailController,
                          maxLines: 3,
                          minLines: 2,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.35,
                          ),
                          decoration: _editableBoxDecoration(
                            'Belum ada catatan perawatan.',
                            isDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _saveChanges(purchaseType),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Simpan Perubahan',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 42,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 6),
        Text(
          'Ketuk untuk Unggah Foto Barang',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
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