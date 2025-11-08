import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String text; // Button label
  final VoidCallback onPressed; // Tap handler
  final bool isLoading; // Show loader when true

  /// Background/text color overrides.
  final Color? color; // legacy/alt bg color
  final Color? backgroundColor; // preferred alias (optional)
  final Color? textColor;

  /// Optional customization
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? color ?? Theme.of(context).colorScheme.primary;
    final Color fg = textColor ?? Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: padding,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

