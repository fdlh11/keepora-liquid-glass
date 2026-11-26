import 'package:flutter/material.dart';

class CustomAppDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Color? fillColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final double maxMenuHeight;

  const CustomAppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
    this.fillColor,
    this.borderColor,
    this.textStyle,
    this.maxMenuHeight = 210,
  });

  @override
  State<CustomAppDropdown> createState() => _CustomAppDropdownState();
}

class _CustomAppDropdownState extends State<CustomAppDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _removeOverlayImmediate();
    _animController.dispose();
    super.dispose();
  }

  void _removeOverlayImmediate() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  Future<void> _closeMenu() async {
    if (!_isOpen) return;
    await _animController.reverse();
    _removeOverlayImmediate();
    if (mounted) setState(() {});
  }

  void _toggleMenu() {
    if (!widget.enabled || widget.onChanged == null || widget.items.isEmpty) {
      return;
    }
    if (_isOpen) {
      _closeMenu();
    } else {
      FocusScope.of(context).unfocus();
      _openMenu();
    }
  }

  void _openMenu() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);
    final accentBlue = isDark ? const Color(0xFF60A5FA) : primaryBlue;
    final menuBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final menuBorder =
        isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : Colors.black87;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Tap di luar menu untuk menutup dropdown
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: size.width,
                      constraints: BoxConstraints(
                        maxHeight: widget.maxMenuHeight,
                      ),
                      decoration: BoxDecoration(
                        color: menuBg,
                        borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: widget.items.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            final isSelected = item == widget.value;

                            return InkWell(
                              onTap: () async {
                                widget.onChanged?.call(item);
                                await _closeMenu();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
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
                                        item,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
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
                                        size: 18,
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

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF004AAD);

    final effectiveFill = widget.fillColor ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final effectiveBorder = _isOpen
        ? primaryBlue
        : (widget.borderColor ??
            (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)));
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final hasValue =
        widget.value != null && widget.items.contains(widget.value);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleMenu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: effectiveBorder,
              width: _isOpen ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? widget.value! : widget.hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasValue
                      ? (widget.textStyle ??
                          TextStyle(
                            fontSize: 13.5,
                            color: textPrimary,
                          ))
                      : TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade500,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isOpen ? primaryBlue : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}