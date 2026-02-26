import 'package:citesched_client/citesched_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyCalendarView extends StatelessWidget {
  final List<ScheduleInfo> schedules;
  final Function(Schedule)? onEdit;
  final Color maroonColor;
  final bool isInstructorView;
  final Faculty? selectedFaculty;

  const WeeklyCalendarView({
    super.key,
    required this.schedules,
    required this.maroonColor,
    this.isInstructorView = false,
    this.selectedFaculty,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? Colors.white12 : Colors.black12;

    // Config
    const double hourHeight = 100.0;
    const double dayWidth = 150.0;
    const int startHour = 7;
    const int endHour = 21;
    final List<DayOfWeek> days = [
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          width: 80 + (dayWidth * days.length),
          height: hourHeight * (endHour - startHour + 1),
          child: Stack(
            children: [
              // 1. Grid Background & Headers
              _buildGrid(
                context,
                days,
                startHour,
                endHour,
                hourHeight,
                dayWidth,
                gridColor,
              ),

              // 2. Shift Preference Watermarks (Faded vertical labels)
              if (selectedFaculty != null)
                ...days.map(
                  (day) => _buildShiftWatermark(
                    day,
                    days,
                    startHour,
                    hourHeight,
                    dayWidth,
                  ),
                ),

              // 3. Schedule Blocks
              ...schedules.map(
                (info) => _buildScheduleBlock(
                  context,
                  info,
                  days,
                  startHour,
                  hourHeight,
                  dayWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<DayOfWeek> days,
    int startHour,
    int endHour,
    double hourHeight,
    double dayWidth,
    Color gridColor,
  ) {
    final prefRange = _getPreferenceRange();

    return Column(
      children: [
        // Day Headers
        Row(
          children: [
            const SizedBox(width: 80),
            ...days.map(
              (day) => Container(
                width: dayWidth,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isDayHighlighted(day)
                      ? maroonColor.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: gridColor),
                    left: BorderSide(color: gridColor),
                  ),
                ),
                child: Text(
                  _getDayName(day),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _isDayHighlighted(day) ? maroonColor : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Time Rows
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: endHour - startHour + 1,
            itemBuilder: (context, index) {
              final hour = startHour + index;
              final isPreferredTime =
                  prefRange != null &&
                  hour >= prefRange.start &&
                  hour < prefRange.end;

              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: gridColor)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(4),
                      decoration: isPreferredTime
                          ? BoxDecoration(
                              color: Colors.black,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            )
                          : null,
                      child: Column(
                        children: [
                          Text(
                            _formatHour(hour),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isPreferredTime
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          if (isPreferredTime)
                            Text(
                              'PREF',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...days.map(
                      (day) => Container(
                        width: dayWidth,
                        decoration: BoxDecoration(
                          color: isPreferredTime
                              ? Colors.black.withOpacity(0.04)
                              : (_isDayHighlighted(day) &&
                                        _isTimeHighlighted(hour)
                                    ? maroonColor.withOpacity(0.03)
                                    : Colors.transparent),
                          border: Border(left: BorderSide(color: gridColor)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  _PreferenceRange? _getPreferenceRange() {
    if (selectedFaculty == null) return null;

    final shift = selectedFaculty!.shiftPreference;
    if (shift == null) return null;

    switch (shift) {
      case FacultyShiftPreference.morning:
        return _PreferenceRange(7, 12);
      case FacultyShiftPreference.afternoon:
        return _PreferenceRange(13, 18);
      case FacultyShiftPreference.evening:
        return _PreferenceRange(18, 21);
      case FacultyShiftPreference.any:
        return _PreferenceRange(7, 21);
      case FacultyShiftPreference.custom:
        if (selectedFaculty!.preferredHours == null) return null;
        return _parseCustomHours(selectedFaculty!.preferredHours!);
    }
  }

  _PreferenceRange? _parseCustomHours(String hours) {
    try {
      // Expected format: "7:00 AM - 12:00 PM"
      final parts = hours.split('-');
      if (parts.length != 2) return null;

      final startStr = parts[0].trim();
      final endStr = parts[1].trim();

      final startTime = _parseTimeString(startStr);
      final endTime = _parseTimeString(endStr);

      return _PreferenceRange(
        startTime.hour,
        endTime.hour + (endTime.minute > 0 ? 1 : 0),
      );
    } catch (e) {
      debugPrint('Error parsing custom hours: $e');
      return null;
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Format: "7:00 AM" or "12:00 PM"
    final timeParts = timeStr.split(' ');
    final amPm = timeParts[1].toUpperCase();
    final parts = timeParts[0].split(':');

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    if (amPm == 'PM' && hour != 12) hour += 12;
    if (amPm == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildShiftWatermark(
    DayOfWeek day,
    List<DayOfWeek> days,
    int startHour,
    double hourHeight,
    double dayWidth,
  ) {
    final prefRange = _getPreferenceRange();
    if (prefRange == null) return const SizedBox.shrink();

    final dayIndex = days.indexOf(day);
    final double top = 40 + (prefRange.start - startHour) * hourHeight;
    final double height = (prefRange.end - prefRange.start) * hourHeight;
    final double left = 80 + (dayIndex * dayWidth);

    // Build label
    String shiftLabel = '';
    String timeRange = '';
    switch (selectedFaculty?.shiftPreference) {
      case FacultyShiftPreference.morning:
        shiftLabel = 'Morning';
        timeRange = '7AM – 12PM';
        break;
      case FacultyShiftPreference.afternoon:
        shiftLabel = 'Afternoon';
        timeRange = '1PM – 6PM';
        break;
      case FacultyShiftPreference.evening:
        shiftLabel = 'Evening';
        timeRange = '6PM – 9PM';
        break;
      case FacultyShiftPreference.any:
        shiftLabel = 'Any Shift';
        timeRange = 'Flexible';
        break;
      case FacultyShiftPreference.custom:
        shiftLabel = 'Custom';
        timeRange = selectedFaculty?.preferredHours ?? '';
        break;
      default:
        break;
    }

    return Positioned(
      top: top + 4,
      left: left + 4,
      width: dayWidth - 8,
      height: height - 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: maroonColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: maroonColor.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: 16,
                color: maroonColor.withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Preferred',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: maroonColor.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                shiftLabel,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: maroonColor.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              if (timeRange.isNotEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: maroonColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    timeRange,
                    style: GoogleFonts.poppins(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: maroonColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleBlock(
    BuildContext context,
    ScheduleInfo info,
    List<DayOfWeek> days,
    int startHour,
    double hourHeight,
    double dayWidth,
  ) {
    final schedule = info.schedule;
    final timeslot = schedule.timeslot;
    if (timeslot == null) return const SizedBox.shrink();

    final dayIndex = days.indexOf(timeslot.day);
    if (dayIndex == -1) return const SizedBox.shrink();

    final startTime = _parseTime(timeslot.startTime);
    final endTime = _parseTime(timeslot.endTime);

    final double top =
        40 +
        (startTime.hour - startHour + startTime.minute / 60.0) * hourHeight;
    final double height =
        (endTime.hour -
            startTime.hour +
            (endTime.minute - startTime.minute) / 60.0) *
        hourHeight;
    final double left = 80 + (dayIndex * dayWidth);

    final bool hasConflict = info.conflicts.isNotEmpty;

    // Black card design per specification
    final Color blockColor = hasConflict
        ? const Color(0xFF2D0000) // Dark red-black for conflicts
        : Colors.black;

    final Color borderColor = hasConflict
        ? Colors.red.shade400
        : Colors.grey[800]!;

    return Positioned(
      top: top + 2,
      left: left + 4,
      width: dayWidth - 8,
      height: height - 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showScheduleDetails(context, info),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: hasConflict ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                if (hasConflict)
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Label: "Preferred Time"
                Text(
                  'Preferred Time',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Main Text: Faculty Name (Bold)
                Text(
                  selectedFaculty != null
                      ? selectedFaculty!.name
                      : (schedule.faculty?.name ?? 'Unassigned'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // Sub Text: Subject Name
                Text(
                  schedule.subject?.name ?? schedule.subject?.code ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                // Bottom: Time range + conflict icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${timeslot.startTime} – ${timeslot.endTime}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                    if (hasConflict)
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.red[300],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScheduleDetails(BuildContext context, ScheduleInfo info) {
    final schedule = info.schedule;
    final hasConflict = info.conflicts.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasConflict ? Icons.warning_rounded : Icons.event_note,
              color: hasConflict ? Colors.red : maroonColor,
            ),
            const SizedBox(width: 12),
            const Text('Schedule Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Subject', schedule.subject?.name ?? 'N/A'),
            _buildDetailItem('Code', schedule.subject?.code ?? 'N/A'),
            _buildDetailItem(
              'Instructor',
              schedule.faculty?.name ?? 'Unassigned',
            ),
            _buildDetailItem('Room', schedule.room?.name ?? 'N/A'),
            _buildDetailItem('Section', schedule.section),
            _buildDetailItem(
              'Time',
              '${schedule.timeslot?.day.name.toUpperCase()} ${schedule.timeslot?.startTime} - ${schedule.timeslot?.endTime}',
            ),
            if (hasConflict) ...[
              const Divider(height: 24),
              Text(
                'CONFLICT DETECTED:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ...info.conflicts.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${c.message}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit?.call(schedule);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit Schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  bool _isDayHighlighted(DayOfWeek day) {
    if (!isInstructorView) return false;
    return schedules.any((s) => s.schedule.timeslot?.day == day);
  }

  bool _isTimeHighlighted(int hour) {
    if (!isInstructorView) return false;
    return schedules.any((s) {
      final ts = s.schedule.timeslot;
      if (ts == null) return false;
      final start = _parseTime(ts.startTime);
      final end = _parseTime(ts.endTime);
      return hour >= start.hour && hour < end.hour;
    });
  }

  TimeOfDay _parseTime(String time) {
    // Expected format: "08:30" or "14:15"
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Mon';
      case DayOfWeek.tue:
        return 'Tue';
      case DayOfWeek.wed:
        return 'Wed';
      case DayOfWeek.thu:
        return 'Thu';
      case DayOfWeek.fri:
        return 'Fri';
      case DayOfWeek.sat:
        return 'Sat';
      case DayOfWeek.sun:
        return 'Sun';
    }
  }
}

class _PreferenceRange {
  final int start;
  final int end;
  _PreferenceRange(this.start, this.end);
}
