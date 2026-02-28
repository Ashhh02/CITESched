import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_client/citesched_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';

final facultyDetailsSchedulesProvider = FutureProvider.family<List<Schedule>, int>((
  ref,
  facultyId,
) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.admin.getFacultySchedule(facultyId);
});

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
    final facultySchedulesAsync = ref.watch(
      facultyDetailsSchedulesProvider(faculty.id!),
    );
    final availabilityAsync = ref.watch(
      facultyAvailabilityProvider(faculty.id!),
    );
    final allConflicts = allConflictsAsync.value ?? <ScheduleConflict>[];
    final facultyConflicts = allConflicts
        .where((c) => c.facultyId == faculty.id)
        .toList();

    // Filter schedules for this faculty (live from schedules table)
    final facultySchedules = facultySchedulesAsync.maybeWhen(
      data: (all) => all,
      orElse: () => <Schedule>[],
    );

    // Calculate stats
    double totalUnits = 0;
    for (var s in facultySchedules) {
      totalUnits += s.units ?? 0;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header (Standardized Maroon Gradient Banner)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF720045), const Color(0xFF8e005b)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF720045).withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Faculty Workspace',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          faculty.name,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        faculty.facultyId,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Units',
                        '$totalUnits / ${faculty.maxLoad ?? 0}',
                        Icons.menu_book_rounded,
                        maroonColor,
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Assigned Subjects',
                        '${facultySchedules.length}',
                        Icons.subject_rounded,
                        Colors.blue,
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Remaining Load',
                        '${(faculty.maxLoad ?? 0) - totalUnits}',
                        Icons.trending_down_rounded,
                        Colors.green,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Mini Timetable Section
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_week_rounded,
                        color: const Color(0xFF720045),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Weekly Schedule Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 500,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: availabilityAsync.when(
                      data: (availabilities) => WeeklyCalendarView(
                        maroonColor: maroonColor,
                        availabilities: availabilities,
                        schedules: facultySchedules.map((s) {
                          final sConflicts = facultyConflicts
                              .where(
                                (c) =>
                                    c.scheduleId == s.id ||
                                    c.conflictingScheduleId == s.id,
                              )
                              .toList();
                          return ScheduleInfo(
                            schedule: s,
                            conflicts: sConflicts,
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => WeeklyCalendarView(
                        maroonColor: maroonColor,
                        schedules: facultySchedules.map((s) {
                          final sConflicts = facultyConflicts
                              .where(
                                (c) =>
                                    c.scheduleId == s.id ||
                                    c.conflictingScheduleId == s.id,
                              )
                              .toList();
                          return ScheduleInfo(
                            schedule: s,
                            conflicts: sConflicts,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Detailed List
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        color: const Color(0xFF720045),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Detailed Assignments & Conflicts',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAssignmentsTable(
                    facultySchedules,
                    facultyConflicts,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
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
