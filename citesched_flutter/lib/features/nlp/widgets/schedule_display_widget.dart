import 'package:citesched_client/citesched_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleDisplayWidget extends StatelessWidget {
  final List<Schedule> schedules;
  final String title;

  const ScheduleDisplayWidget({
    super.key,
    required this.schedules,
    this.title = 'Schedule',
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Text(
          'No schedules found',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: {
          0: const FixedColumnWidth(100),
          1: const FixedColumnWidth(150),
          2: const FixedColumnWidth(100),
          3: const FixedColumnWidth(100),
          4: const FixedColumnWidth(100),
        },
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: const Color(0xFF720045).withOpacity(0.3),
            ),
            children: [
              _buildHeaderCell('Subject'),
              _buildHeaderCell('Faculty'),
              _buildHeaderCell('Room'),
              _buildHeaderCell('Time'),
              _buildHeaderCell('Section'),
            ],
          ),
          // Data rows
          ...schedules.map((schedule) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white12,
                  ),
                ),
              ),
              children: [
                _buildDataCell(schedule.subject?.code ?? '-'),
                _buildDataCell(schedule.faculty?.name ?? '-'),
                _buildDataCell(schedule.room?.name ?? '-'),
                _buildDataCell(
                  '${schedule.timeslot?.startTime ?? '-'} - ${schedule.timeslot?.endTime ?? '-'}',
                ),
                _buildDataCell(schedule.section),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 11,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
