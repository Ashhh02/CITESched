import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppErrorDialog {
  /// Shows a standardized error dialog for any caught exceptions (including 500 server errors).
  static void show(BuildContext context, dynamic error, {String title = 'Action Failed'}) {
    if (!context.mounted) return;
    
    String message = error.toString();
    // Clean up typical Serverpod or Exception prefixes
    message = message.replaceAll('Exception: ', '').trim();
    message = message.replaceAll('ServerpodClientException: ', '').trim();
    // Sometimes serverpod includes the status code in the string
    message = message.replaceAll('Internal server error (500)', 'Internal Server Error').trim();
    
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
