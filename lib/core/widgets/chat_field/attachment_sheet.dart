import 'package:flutter/material.dart';

class AttachmentSheet extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color iconBackgroundColor;

  final List<AttachmentOption> options;

  const AttachmentSheet({
    super.key,
    required this.options,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.textColor = Colors.black,
    this.iconBackgroundColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      bottom: keyboardHeight + 70,
      left: 8,
      right: 8,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final option = options[index];

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: option.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(option.icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.label,
                    style: TextStyle(fontSize: 11, color: textColor),
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
