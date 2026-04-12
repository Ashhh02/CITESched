import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_client/citesched_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';

final facultyDetailsSchedulesProvider =
    FutureProvider.family<List<Schedule>, int>((
      ref,
      facultyId,
    ) async {
      ref.watch(scheduleSyncTriggerProvider);
      return await client.admin.getFacultySchedule(facultyId);
    });

List<ScheduleInfo> _toScheduleInfos(
  List<Schedule> schedules,
  List<ScheduleConflict> conflicts,
) {
  return schedules.map((s) {
    final sConflicts = conflicts
        .where(
          (c) => c.scheduleId == s.id || c.conflictingScheduleId == s.id,
        )
        .toList();
    return ScheduleInfo(schedule: s, conflicts: sConflicts);
  }).toList();
}

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
    final isMobile = MediaQuery.of(context).size.width < 768;
    const maroonColor = Color(0xFF800000);

    // Watch all conflicts and filter for this faculty
    final allConflictsAsync = ref.watch(allConflictsProvider);
    final facultySchedulesAsync = ref.watch(
      facultyDetailsSchedulesProvider(faculty.id!),
    );
    final availabilityAsync = ref.watch(
      facultyAvailabilityProvider(faculty.id!),
    );
    // Use live schedules when available, otherwise fall back to the initial snapshot.
    final facultySchedules = facultySchedulesAsync.maybeWhen(
      data: (all) => all,
      orElse: () => initialSchedules,
    );
    final allConflicts = allConflictsAsync.value ?? <ScheduleConflict>[];
    final facultyConflicts = allConflicts
        .where((c) => c.facultyId == faculty.id)
        .toList();
    final scheduleInfos = _toScheduleInfos(facultySchedules, facultyConflicts);

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
          AdminHeaderContainer(
            primaryColor: const Color(0xFF720045),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF720045).withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeader = constraints.maxWidth < 920;

                if (compactHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.assignment_ind_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: constraints.maxWidth > 260
                                ? constraints.maxWidth - 140
                                : 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Faculty Workspace',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  faculty.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
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
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                          Expanded(
                            child: Column(
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
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
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  LayoutBuilder(
                    builder: (context, c) {
                      final compactStats = c.maxWidth < 860;
                      if (compactStats) {
                        return Column(
                          children: [
                            _buildStatCard(
                              'Total Units',
                              '$totalUnits / ${faculty.maxLoad ?? 0}',
                              Icons.menu_book_rounded,
                              maroonColor,
                              isDark,
                              compact: true,
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              'Assigned Subjects',
                              '${facultySchedules.length}',
                              Icons.subject_rounded,
                              Colors.blue,
                              isDark,
                              compact: true,
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              'Remaining Load',
                              '${(faculty.maxLoad ?? 0) - totalUnits}',
                              Icons.trending_down_rounded,
                              Colors.green,
                              isDark,
                              compact: true,
                            ),
                          ],
                        );
                      }

                      return Row(
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
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Mini Timetable Section
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_view_week_rounded,
                        color: Color(0xFF720045),
                      ),
                      Text(
                        'Weekly Schedule Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullScreenCalendarScaffold(
                              title: 'Weekly Schedule Analysis',
                              backgroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8F9FA),
                              child: WeeklyCalendarView(
                                maroonColor: maroonColor,
                                availabilities:
                                    availabilityAsync.maybeWhen(
                                      data: (d) => d,
                                      orElse: () => null,
                                    ),
                                schedules: scheduleInfos,
                              ),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.fullscreen_rounded),
                        label: Text(
                          'Full Screen',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
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
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                        schedules: scheduleInfos,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => WeeklyCalendarView(
                        maroonColor: maroonColor,
                        schedules: scheduleInfos,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Detailed List
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.list_alt_rounded,
                        color: Color(0xFF720045),
                      ),
                      Text(
                        'Detailed Assignments & Conflicts',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 18 : 20,
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
    {bool compact = false}
  ) {
    final card = Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: compact ? 22 : 28),
          ),
          SizedBox(width: compact ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 11 : 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (compact) return card;
    return Expanded(
      child: card,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 860),
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
        ),
      ),
    );
  }
}
