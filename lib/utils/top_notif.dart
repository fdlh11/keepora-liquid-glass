import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

OverlayEntry? _activeTopNotif;
Timer? _topNotifTimer;
VoidCallback? _activeDismissCallback;

void showTopNotif(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  _topNotifTimer?.cancel();
  _activeTopNotif?.remove();
  _activeTopNotif = null;
  _activeDismissCallback = null;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;

  void removeEntry() {
    if (_activeTopNotif == entry) {
      entry.remove();
      _activeTopNotif = null;
      _activeDismissCallback = null;
    }
  }

  entry = OverlayEntry(
    builder: (ctx) => _TopNotifWidget(
      message: message,
      isError: isError,
      onRegisterDismiss: (dismissFn) {
        _activeDismissCallback = dismissFn;
      },
      onRemoved: removeEntry,
    ),
  );

  _activeTopNotif = entry;
  overlay.insert(entry);

  _topNotifTimer = Timer(duration, () {
    if (_activeTopNotif == entry) {
      if (_activeDismissCallback != null) {
        _activeDismissCallback!();
      } else {
        removeEntry();
      }
    }
  });
}

class _TopNotifWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final ValueChanged<VoidCallback> onRegisterDismiss;
  final VoidCallback onRemoved;

  const _TopNotifWidget({
    required this.message,
    required this.isError,
    required this.onRegisterDismiss,
    required this.onRemoved,
  });

  @override
  State<_TopNotifWidget> createState() => _TopNotifWidgetState();
}

class _TopNotifWidgetState extends State<_TopNotifWidget> {
  bool _isVisible = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onRegisterDismiss(_dismissSmoothly);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  void _dismissSmoothly() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _topNotifTimer?.cancel();

    setState(() => _isVisible = false);

    Future.delayed(const Duration(milliseconds: 220), () {
      widget.onRemoved();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 10;
    final bgColor =
        widget.isError ? const Color(0xFFDC2626) : const Color(0xFF004AAD);

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, -1.2),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                _dismissSmoothly();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismissSmoothly,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
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
}