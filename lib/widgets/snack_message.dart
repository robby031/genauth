import 'package:flutter/material.dart';

class SnackMessage {
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? backgroundColor,
  }) {
    _showSnack(context, message, icon, backgroundColor: backgroundColor);
  }
}

void _showSnack(
  BuildContext context,
  String message,
  IconData? icon, {
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentMaterialBanner()
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
