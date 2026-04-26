import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppErrorDialog {
  /// Shows a standardized error dialog for any caught exceptions (including 500 server errors).
  static void show(
    BuildContext context,
    dynamic error, {
    String title = 'Action Failed',
    String? actionLabel,
  }) {
    if (!context.mounted) return;

    final rawMessage = error?.toString().trim().isNotEmpty == true
        ? error.toString().trim()
        : 'Unknown error';
    final errorType = error?.runtimeType.toString() ?? 'UnknownError';
    final message = actionLabel == null || actionLabel.trim().isEmpty
        ? '$errorType: $rawMessage'
        : 'Action: $actionLabel\nError Type: $errorType\nDetails: $rawMessage';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
