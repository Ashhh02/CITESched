import 'package:citesched_client/citesched_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableSummaryPanel extends StatelessWidget {
  final TimetableSummary? summary;

  const TimetableSummaryPanel({
    super.key,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Total Subjects',
            summary!.totalSubjects.toString(),
            Icons.library_books,
          ),
          _buildSummaryItem(
            'Total Units',
            summary!.totalUnits.toStringAsFixed(1),
            Icons.exposure,
          ),
          _buildSummaryItem(
            'Weekly Hours',
            summary!.totalWeeklyHours.toStringAsFixed(1),
            Icons.timer,
          ),
          const Divider(color: Colors.white24),
          _buildSummaryItem(
            'Conflicts',
            summary!.conflictCount.toString(),
            Icons.warning_amber_rounded,
            valueColor: summary!.conflictCount > 0
                ? Colors.orangeAccent
                : Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
