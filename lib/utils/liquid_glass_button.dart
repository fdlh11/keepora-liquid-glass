import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidGlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? tintColor;
  final Color? foregroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final double? width;
  final double? height;
  final bool isLoading;

  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tintColor,
    this.foregroundColor,
    this.borderRadius = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.blurSigma = 18,
    this.width,
    this.height,
    this.isLoading = false,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (_pressController.value > 0) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (_pressController.value > 0) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final Color effectiveTint =
        widget.tintColor ?? (isDark ? Colors.white : const Color(0xFF004AAD));

    // Gradien kaca bening dengan kontras tinggi tanpa BackdropFilter per-frame
    final List<Color> glassGradientColors = widget.tintColor != null
        ? [
            widget.tintColor!.withValues(alpha: isDark ? 0.36 : 0.24),
            widget.tintColor!.withValues(alpha: isDark ? 0.18 : 0.12),
          ]
        : isDark
            ? [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.08),
              ]
            : [
                Colors.white.withValues(alpha: 0.88),
                const Color(0xFFE0ECFF).withValues(alpha: 0.68),
              ];

    final Color contentColor = isDisabled
        ? (isDark ? Colors.white38 : Colors.black38)
        : (widget.foregroundColor ??
            (isDark ? Colors.white : const Color(0xFF004AAD)));

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: isDisabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.onPressed?.call();
                },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
                  blurRadius: 14,
                  spreadRadius: -1,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: effectiveTint.withValues(alpha: isDark ? 0.08 : 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: _ClearLiquidBorderPainter(
                borderRadius: widget.borderRadius,
                isDark: isDark,
              ),
              child: Container(
                padding: widget.padding,
                alignment: widget.width != null ? Alignment.center : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: glassGradientColors,
                  ),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: contentColor,
                          strokeWidth: 2.4,
                        ),
                      )
                    : DefaultTextStyle.merge(
                        style: TextStyle(color: contentColor),
                        child: IconTheme.merge(
                          data: IconThemeData(color: contentColor),
                          child: widget.child,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearLiquidBorderPainter extends CustomPainter {
  final double borderRadius;
  final bool isDark;

  _ClearLiquidBorderPainter({
    required this.borderRadius,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(borderRadius),
    );

    if (!isDark) {
      final baseOutlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF004AAD).withValues(alpha: 0.24);
      canvas.drawRRect(rrect, baseOutlinePaint);
    }

    final specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.45),
              ]
            : [
                Colors.white.withValues(alpha: 0.95),
                const Color(0xFF004AAD).withValues(alpha: 0.12),
                const Color(0xFF004AAD).withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.85),
              ],
        stops: const [0.0, 0.35, 0.68, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, specularPaint);
  }

  @override
  bool shouldRepaint(covariant _ClearLiquidBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark;
  }
}