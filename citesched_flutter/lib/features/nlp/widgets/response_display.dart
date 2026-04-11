import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays structured NLP responses based on intent type
class ResponseDisplay extends StatelessWidget {
  final NLPIntent intent;
  final String message;
  final List<Schedule>? schedules;
  final Map<String, dynamic>? metadata;

  const ResponseDisplay({
    super.key,
    required this.intent,
    required this.message,
    this.schedules,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        // Main message
        Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),

        // Structured data based on intent
        if (intent == NLPIntent.conflict)
          _buildConflictDisplay(context)
        else if (intent == NLPIntent.facultyLoad)
          _buildOverloadDisplay(context)
        else if (intent == NLPIntent.schedule)
          _buildScheduleDisplay(context)
        else if (intent == NLPIntent.roomStatus)
          _buildRoomDisplay(context),
      ],
    );
  }

  Widget _buildConflictDisplay(BuildContext context) {
    final conflictData = metadata;
    if (conflictData == null) return SizedBox.shrink();

    final roomConflicts = conflictData['room'] as int? ?? 0;
    final facultyConflicts = conflictData['faculty'] as int? ?? 0;
    final totalConflicts = conflictData['count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade300, size: 20),
              const SizedBox(width: 8),
              Text(
                'Conflict Summary',
                style: GoogleFonts.poppins(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          _buildConflictItem('Total', totalConflicts),
          if (roomConflicts > 0)
            _buildConflictItem('Room Conflicts', roomConflicts),
          if (facultyConflicts > 0)
            _buildConflictItem('Faculty Conflicts', facultyConflicts),
          if (totalConflicts > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminLayout(initialIndex: 6),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_rounded, size: 16),
                label: Text(
                  'Resolve Conflicts',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.red.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverloadDisplay(BuildContext context) {
    if (metadata == null) return SizedBox.shrink();

    final isOverloaded = metadata!['isOverloaded'] as bool? ?? false;
    final totalUnits = metadata!['totalUnits'] as double?;
    final maxLoad = metadata!['maxLoad'] as int?;

    if (totalUnits == null || maxLoad == null) return SizedBox.shrink();

    final overloadPercentage = (totalUnits / maxLoad) * 100;
    final barColor = isOverloaded ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.1),
        border: Border.all(color: barColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              Icon(
                isOverloaded ? Icons.trending_up : Icons.check_circle,
                color: barColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOverloaded ? 'Overload Alert' : 'Load Status',
                style: GoogleFonts.poppins(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      '${totalUnits.toStringAsFixed(1)} / $maxLoad units',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: overloadPercentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${overloadPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDisplay(BuildContext context) {
    if (schedules == null || schedules!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue.shade300, size: 20),
            const SizedBox(width: 8),
            Text(
              'No schedules found',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF720045).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFF720045).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Schedule (${schedules!.length} classes)',
                style: GoogleFonts.poppins(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: schedules!.length,
            itemBuilder: (context, index) {
              final schedule = schedules![index];
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildScheduleItem(schedule),
              );
            },
          ),
          if (metadata?['showTimetable'] == true)
            _buildTimetablePreview(context),
        ],
      ),
    );
  }

  Widget _buildTimetablePreview(BuildContext context) {
    final scheduleInfos = schedules!
        .map((s) => ScheduleInfo(schedule: s, conflicts: const []))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Timetable Preview',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: WeeklyCalendarView(
            schedules: scheduleInfos,
            maroonColor: const Color(0xFF720045),
            isStudentView: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenCalendarScaffold(
                    title: 'Timetable',
                    backgroundColor: const Color(0xFF0F172A),
                    child: WeeklyCalendarView(
                      schedules: scheduleInfos,
                      maroonColor: const Color(0xFF720045),
                      isStudentView: true,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.fullscreen_rounded, size: 16),
            label: Text(
              'Full Screen',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            schedule.subject?.code ?? 'N/A',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: _buildScheduleDetail(
                  '👨‍🏫',
                  schedule.faculty?.name ?? 'Unassigned',
                ),
              ),
              Expanded(
                child: _buildScheduleDetail(
                  '🏫',
                  schedule.room?.name ?? 'No Room',
                ),
              ),
            ],
          ),
          _buildScheduleDetail(
            '⏰',
            '${schedule.timeslot?.startTime ?? '?'} - ${schedule.timeslot?.endTime ?? '?'}',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetail(String emoji, String text) {
    return Row(
      spacing: 6,
      children: [
        Text(emoji, style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomDisplay(BuildContext context) {
    if (metadata == null) return SizedBox.shrink();

    final capacity = metadata!['capacity'] as int?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.meeting_room, color: Colors.orange.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Room Details',
                  style: GoogleFonts.poppins(
                    color: Colors.orange.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (capacity != null)
                  Text(
                    'Capacity: $capacity students',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
