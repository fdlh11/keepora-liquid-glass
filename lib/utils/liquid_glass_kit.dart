import 'dart:ui';
import 'package:flutter/material.dart';

/// Latar belakang ambient dengan soft mesh orbs yang di-cache via RepaintBoundary
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Di-cache GPU agar tidak ikut di-repaint saat scroll atau mengetik
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              children: [
                // Base gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              Color(0xFF070B14),
                              Color(0xFF0D1526),
                              Color(0xFF090E1A),
                            ]
                          : const [
                              Color(0xFFEAF2FF),
                              Color(0xFFF4F8FF),
                              Color(0xFFE2ECFF),
                            ],
                    ),
                  ),
                ),
                // Ambient orb kanan atas (Biru Keepora)
                Positioned(
                  top: -90,
                  right: -70,
                  child: _AmbientOrb(
                    size: 280,
                    color: isDark
                        ? const Color(0xFF004AAD).withValues(alpha: 0.36)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.24),
                  ),
                ),
                // Ambient orb tengah kiri (Cyan lembut)
                Positioned(
                  top: 240,
                  left: -100,
                  child: _AmbientOrb(
                    size: 260,
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.24)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.22),
                  ),
                ),
                // Ambient orb kanan bawah (Indigo)
                Positioned(
                  bottom: -80,
                  right: -60,
                  child: _AmbientOrb(
                    size: 300,
                    color: isDark
                        ? const Color(0xFF1D4ED8).withValues(alpha: 0.28)
                        : const Color(0xFF60A5FA).withValues(alpha: 0.22),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Konten layar
        child,
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel kaca utama:
/// - blurSigma >= 18 (Dialog, BottomSheet, Navbar): memakai real BackdropFilter (capped max 12 agar ringan)
/// - blurSigma < 18 (Form input, kartu list, box info): memakai Simulated Liquid Glass tanpa GPU offscreen pass
class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? tintColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableShadow;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blurSigma = 14,
    this.tintColor,
    this.width,
    this.height,
    this.onTap,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool useRealBlur = blurSigma >= 18;
    final double effectiveSigma = blurSigma > 12 ? 12.0 : blurSigma;

    final Color effectiveTint =
        tintColor ?? (isDark ? Colors.white : const Color(0xFF004AAD));

    // Jika tanpa real blur, sedikit naikkan opasitas kaca agar tetap kontras & bening
    final List<Color> gradientColors = tintColor != null
        ? [
            tintColor!.withValues(
              alpha: isDark
                  ? (useRealBlur ? 0.34 : 0.38)
                  : (useRealBlur ? 0.24 : 0.26),
            ),
            tintColor!.withValues(
              alpha: isDark
                  ? (useRealBlur ? 0.16 : 0.20)
                  : (useRealBlur ? 0.10 : 0.14),
            ),
          ]
        : isDark
            ? [
                Colors.white.withValues(alpha: useRealBlur ? 0.14 : 0.12),
                Colors.white.withValues(alpha: useRealBlur ? 0.06 : 0.06),
              ]
            : [
                Colors.white.withValues(alpha: useRealBlur ? 0.78 : 0.88),
                const Color(0xFFEFF5FF)
                    .withValues(alpha: useRealBlur ? 0.58 : 0.72),
              ];

    Widget glassBody = CustomPaint(
      foregroundPainter: LiquidSpecularBorderPainter(
        borderRadius: borderRadius,
        isDark: isDark,
        tintColor: tintColor,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: child,
      ),
    );

    if (useRealBlur) {
      glassBody = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveSigma,
            sigmaY: effectiveSigma,
          ),
          child: glassBody,
        ),
      );
    }

    Widget surface = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.07),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: effectiveTint.withValues(alpha: isDark ? 0.05 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: glassBody,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: surface,
        ),
      );
    }

    return surface;
  }
}

/// Painter kilau cahaya specular yang selaras dengan LiquidGlassButton
class LiquidSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final bool isDark;
  final Color? tintColor;

  LiquidSpecularBorderPainter({
    required this.borderRadius,
    required this.isDark,
    this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.65),
      Radius.circular(borderRadius),
    );

    final Color baseOutlineColor =
        tintColor ?? (isDark ? Colors.white : const Color(0xFF004AAD));

    if (!isDark) {
      final baseOutlinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = baseOutlineColor.withValues(alpha: 0.18);
      canvas.drawRRect(rrect, baseOutlinePaint);
    }

    final specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.62),
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.38),
              ]
            : [
                Colors.white.withValues(alpha: 0.96),
                baseOutlineColor.withValues(alpha: 0.12),
                baseOutlineColor.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.85),
              ],
        stops: const [0.0, 0.35, 0.68, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, specularPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidSpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark ||
        oldDelegate.tintColor != tintColor;
  }
}