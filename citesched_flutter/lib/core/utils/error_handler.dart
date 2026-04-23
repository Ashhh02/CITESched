import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppErrorDialog {
  static const String _genericServerErrorMessage =
      'The server ran into an unexpected error. Please try again. If it keeps happening, check the backend logs for the exact cause.';

  static String message(
    dynamic error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    var resolved = error.toString().trim();
    if (resolved.isEmpty) return fallback;

    resolved = resolved.replaceAll(RegExp(r'^Error:\s*'), '').trim();
    resolved = resolved.replaceAll('Exception: ', '').trim();
    resolved = resolved.replaceAll('ServerpodClientException: ', '').trim();
    resolved = resolved.replaceAll('Bad state: ', '').trim();

    if (resolved.contains('statusCode = 401') ||
        resolved.contains('statusCode=401')) {
      return 'Your session has expired or you are not authorized. Please log in again.';
    }

    if (resolved.contains('statusCode = 403') ||
        resolved.contains('statusCode=403')) {
      return 'You do not have permission to perform this action.';
    }

    if (resolved.contains('statusCode = 404') ||
        resolved.contains('statusCode=404')) {
      return 'The requested record or endpoint could not be found.';
    }

    if (resolved.contains('statusCode = 409') ||
        resolved.contains('statusCode=409')) {
      return 'This action conflicts with existing data. Please refresh and try again.';
    }

    if (resolved.contains('XMLHttpRequest error') ||
        resolved.contains('Connection closed before full header was received') ||
        resolved.contains('Connection refused')) {
      return 'Unable to connect to the server. Please make sure the backend is running.';
    }

    if (resolved.contains('Internal server error') ||
        resolved.contains('Internal Server Error') ||
        resolved.contains('statusCode = 500') ||
        resolved.contains('statusCode=500')) {
      return _genericServerErrorMessage;
    }

    return resolved.isEmpty ? fallback : resolved;
  }

  static Widget inline(
    dynamic error, {
    TextStyle? style,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Center(
      child: Padding(
        padding: padding,
        child: Text(
          message(error),
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }

  /// Shows a standardized error dialog for any caught exceptions (including 500 server errors).
  static void show(
    BuildContext context,
    dynamic error, {
    String title = 'Action Failed',
  }) {
    if (!context.mounted) return;

    final resolvedMessage = message(error);

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
          resolvedMessage,
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
