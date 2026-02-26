import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_client/citesched_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';

class FacultyLoadDetailsScreen extends ConsumerWidget {
  final Faculty faculty;
  final List<Schedule> initialSchedules;

  const FacultyLoadDetailsScreen({
    super.key,
    required this.faculty,
    required this.initialSchedules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maroonColor = const Color(0xFF800000);

    // Watch all conflicts and filter for this faculty
    final allConflictsAsync = ref.watch(allConflictsProvider);
    final allConflicts = allConflictsAsync.value ?? <ScheduleConflict>[];
    final facultyConflicts = allConflicts
        .where((c) => c.facultyId == faculty.id)
        .toList();

    // Filter schedules for this faculty
    final facultySchedules = initialSchedules;

    // Calculate stats
    double totalUnits = 0;
    for (var s in facultySchedules) {
      totalUnits += s.units ?? 0;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Faculty Load: ${faculty.name}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF720045),
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                _buildStatCard(
                  'Total Units',
                  '$totalUnits / ${faculty.maxLoad ?? 0}',
                  Icons.menu_book,
                  maroonColor,
                  isDark,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Assigned Subjects',
                  '${facultySchedules.length}',
                  Icons.subject,
                  Colors.blue,
                  isDark,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Remaining Load',
                  '${(faculty.maxLoad ?? 0) - totalUnits}',
                  Icons.assignment_ind,
                  Colors.green,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Mini Timetable Section
            Text(
              'Weekly Schedule',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 500,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: WeeklyCalendarView(
                maroonColor: maroonColor,
                schedules: facultySchedules.map((s) {
                  final sConflicts = facultyConflicts
                      .where(
                        (c) =>
                            c.scheduleId == s.id ||
                            c.conflictingScheduleId == s.id,
                      )
                      .toList();
                  return ScheduleInfo(schedule: s, conflicts: sConflicts);
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Detailed List
            Text(
              'Assigned Subjects',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildAssignmentsTable(facultySchedules, facultyConflicts, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsTable(
    List<Schedule> schedules,
    List<ScheduleConflict> facultyConflicts,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('SUBJECT')),
          DataColumn(label: Text('SECTION')),
          DataColumn(label: Text('UNITS')),
          DataColumn(label: Text('ROOM')),
          DataColumn(label: Text('SCHEDULE')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: schedules.map((s) {
          final sConflicts = facultyConflicts
              .where(
                (c) => c.scheduleId == s.id || c.conflictingScheduleId == s.id,
              )
              .toList();

          return DataRow(
            cells: [
              DataCell(Text(s.subject?.name ?? 'Unknown')),
              DataCell(Text(s.section)),
              DataCell(Text('${s.units ?? s.subject?.units ?? 0}')),
              DataCell(Text(s.room?.name ?? 'TBA')),
              DataCell(
                Text(
                  s.timeslot != null
                      ? '${s.timeslot!.day.name.substring(0, 3)} ${s.timeslot!.startTime}-${s.timeslot!.endTime}'
                      : 'TBA',
                ),
              ),
              DataCell(
                sConflicts.isEmpty
                    ? const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      )
                    : Tooltip(
                        message: sConflicts
                            .map((c) => '• ${c.message}')
                            .join('\n'),
                        child: Icon(
                          sConflicts.any(
                                (c) =>
                                    c.type != 'capacity_exceeded' &&
                                    c.type != 'faculty_unavailable' &&
                                    c.type != 'program_mismatch',
                              )
                              ? Icons.error_outline
                              : Icons.warning_amber_rounded,
                          color:
                              sConflicts.any(
                                (c) =>
                                    c.type != 'capacity_exceeded' &&
                                    c.type != 'faculty_unavailable' &&
                                    c.type != 'program_mismatch',
                              )
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
