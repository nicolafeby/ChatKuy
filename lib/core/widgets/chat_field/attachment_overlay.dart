import 'package:flutter/material.dart';
import 'attachment_sheet.dart';

class AttachmentOverlay {
  static OverlayEntry? _overlayEntry;

  static bool get isShowing => _overlayEntry != null;

  static void show({
    required BuildContext context,
    required AttachmentSheet sheet,
  }) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              /// tap area luar untuk close
              Positioned.fill(
                child: GestureDetector(
                  onTap: hide,
                  child: Container(color: Colors.transparent),
                ),
              ),

              /// attachment menu
              sheet,
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
