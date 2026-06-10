import 'package:flutter/material.dart';

class AttachmentSheet extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? iconBackgroundColor;

  final List<AttachmentOption> options;

  const AttachmentSheet({
    super.key,
    required this.options,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBackgroundColor =
        backgroundColor ?? (isDark ? const Color(0xFF202C33) : Colors.white);
    final resolvedIconColor = iconColor ?? colorScheme.onSurface;
    final resolvedTextColor = textColor ?? colorScheme.onSurface;
    final resolvedIconBackgroundColor = iconBackgroundColor ??
        (isDark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5));

    return Positioned(
      bottom: keyboardHeight + 70,
      left: 8,
      right: 8,
      child: Material(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(22),
        elevation: isDark ? 0 : 6,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final option = options[index];

            return InkWell(
              onTap: option.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resolvedIconBackgroundColor,
                    ),
                    child: Icon(
                      option.icon,
                      size: 22,
                      color: resolvedIconColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: resolvedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AttachmentOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
