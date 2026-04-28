import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/features/admin/widgets/timetable_summary_panel.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final roomScheduleProvider = FutureProvider.family<List<ScheduleInfo>, int>((
  ref,
  roomId,
) async {
  ref.watch(schedulesProvider);
  return await client.timetable.getSchedules(
    TimetableFilterRequest(roomId: roomId),
  );
});

IconData _roomTypeIcon(RoomType type) {
  if (type == RoomType.laboratory) {
    return Icons.computer_rounded;
  }
  return Icons.meeting_room_rounded;
}

Color _roomStatusColor(bool isActive, bool inverted) {
  if (isActive) {
    if (inverted) {
      return Colors.white;
    }
    return Colors.green;
  }
  if (inverted) {
    return Colors.white70;
  }
  return Colors.red;
}

String _scheduleSummary(Schedule schedule) {
  return '${schedule.timeslot?.day ?? "N/A"} | ${schedule.timeslot?.startTime} - ${schedule.timeslot?.endTime} | Section: ${schedule.section} | Faculty: ${schedule.faculty?.name ?? "N/A"}';
}

class RoomDetailsScreen extends ConsumerWidget {
  final Room room;

  const RoomDetailsScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(roomScheduleProvider(room.id!));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    const maroonColor = Color(0xFF720045);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header (Standardized Maroon Gradient Banner)
          AdminHeaderContainer(
            primaryColor: maroonColor,
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            boxShadow: [
              BoxShadow(
                color: maroonColor.withValues(alpha: 0.3),
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
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _roomTypeIcon(room.type),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth > 260
                                ? constraints.maxWidth - 140
                                : 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildStatusChip(room.isActive, inverted: true),
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
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              room.program == Program.both
                                  ? 'Both IT and EMC'
                                  : room.program.name.toUpperCase(),
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
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _roomTypeIcon(room.type),
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildStatusChip(room.isActive, inverted: true),
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
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            room.program == Program.both
                                ? 'Both IT and EMC'
                                : room.program.name.toUpperCase(),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: maroonColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.category_rounded, color: maroonColor),
                        Text(
                          'ROOM CATEGORY:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          room.type.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: maroonColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Row
                  _buildRoomStatsSection(
                    room: room,
                    scheduleAsync: scheduleAsync,
                    cardBg: cardBg,
                  ),

                  const SizedBox(height: 32),

                  _buildRoomScheduleSection(
                    context: context,
                    scheduleAsync: scheduleAsync,
                    cardBg: cardBg,
                    isDark: isDark,
                    maroonColor: maroonColor,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, {bool inverted = false}) {
    final color = _roomStatusColor(isActive, inverted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: inverted
              ? Colors.white.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRoomStatsSection({
    required Room room,
    required AsyncValue<List<ScheduleInfo>> scheduleAsync,
    required Color cardBg,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactStats = constraints.maxWidth < 860;
        final stats = <Widget>[
          _buildSimpleStatCard(
            'Capacity',
            '${room.capacity} students',
            Icons.groups_rounded,
            Colors.blue,
            cardBg,
            compact: compactStats,
          ),
          const SizedBox(width: 16, height: 12),
          scheduleAsync.when(
            loading: () => _buildSimpleStatCard(
              'Occupancy',
              '...',
              Icons.pie_chart_rounded,
              Colors.orange,
              cardBg,
              compact: compactStats,
            ),
            error: (e, s) => _buildSimpleStatCard(
              'Occupancy',
              'Error',
              Icons.pie_chart_rounded,
              Colors.orange,
              cardBg,
              compact: compactStats,
            ),
            data: (schedules) {
              final bookedDays = schedules
                  .where((s) => s.schedule.timeslot != null)
                  .map((s) => s.schedule.timeslot!.day)
                  .toSet()
                  .length;
              return _buildSimpleStatCard(
                'Schedules',
                '${schedules.length} periods / $bookedDays days',
                Icons.calendar_view_week_rounded,
                Colors.orange,
                cardBg,
                compact: compactStats,
              );
            },
          ),
          const SizedBox(width: 16, height: 12),
          scheduleAsync.when(
            loading: () => _buildSimpleStatCard(
              'Weekly Hours',
              '...',
              Icons.timer_rounded,
              Colors.green,
              cardBg,
              compact: compactStats,
            ),
            error: (e, s) => _buildSimpleStatCard(
              'Weekly Hours',
              'Error',
              Icons.timer_rounded,
              Colors.green,
              cardBg,
              compact: compactStats,
            ),
            data: (schedules) => _buildSimpleStatCard(
              'Weekly Hours',
              '${_buildRoomSummary(schedules).totalWeeklyHours.toStringAsFixed(1)} hrs',
              Icons.timer_rounded,
              Colors.green,
              cardBg,
              compact: compactStats,
            ),
          ),
        ];

        if (compactStats) {
          return Column(
            children: [
              stats[0],
              const SizedBox(height: 12),
              stats[2],
              const SizedBox(height: 12),
              stats[4],
            ],
          );
        }

        return Row(
          children: [
            stats[0],
            const SizedBox(width: 16),
            stats[2],
            const SizedBox(width: 16),
            stats[4],
          ],
        );
      },
    );
  }

  Widget _buildRoomScheduleSection({
    required BuildContext context,
    required AsyncValue<List<ScheduleInfo>> scheduleAsync,
    required Color cardBg,
    required bool isDark,
    required Color maroonColor,
    required bool isMobile,
  }) {
    return scheduleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error loading schedule: $err')),
      data: (scheduleInfos) {
        final summary = _buildRoomSummary(scheduleInfos);

        if (scheduleInfos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No classes scheduled for this room.',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          );
        }

        final calendarCard = CalendarViewCard(
          title: 'Room Timetable View',
          maroonColor: maroonColor,
          cardBg: cardBg,
          isDark: isDark,
          calendarHeight: isMobile ? 700 : 980,
          onFullScreen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FullScreenCalendarScaffold(
                title: '${room.name} Schedule',
                backgroundColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8F9FA),
                maxWidth: 1600,
                useMaxWidthConstraint: false,
                child: WeeklyCalendarView(
                  schedules: scheduleInfos,
                  maroonColor: maroonColor,
                  dayWidth: 180,
                ),
              ),
            ),
          ),
          child: WeeklyCalendarView(
            schedules: scheduleInfos,
            maroonColor: maroonColor,
            dayWidth: isMobile ? 160 : 180,
          ),
        );

        final detailsCard = Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduleInfos.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final schedule = scheduleInfos[index].schedule;
              return ListTiles(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: maroonColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  schedule.subject?.name ?? 'Unknown Subject',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _scheduleSummary(schedule),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: scheduleInfos[index].conflicts.isEmpty
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${scheduleInfos[index].conflicts.length} conflict${scheduleInfos[index].conflicts.length == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
              );
            },
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              calendarCard,
              const SizedBox(height: 16),
              TimetableSummaryPanel(summary: summary),
              detailsCard,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            calendarCard,
            const SizedBox(height: 20),
            TimetableSummaryPanel(summary: summary),
            detailsCard,
          ],
        );
      },
    );
  }

  TimetableSummary _buildRoomSummary(List<ScheduleInfo> schedules) {
    double totalUnits = 0;
    double totalWeeklyHours = 0;
    final uniqueSubjects = <int>{};
    int conflictCount = 0;

    for (final info in schedules) {
      final schedule = info.schedule;
      totalUnits += schedule.units ?? 0;
      uniqueSubjects.add(schedule.subjectId);
      if (info.conflicts.isNotEmpty) {
        conflictCount++;
      }

      final timeslot = schedule.timeslot;
      if (timeslot != null) {
        totalWeeklyHours += _hoursFromTimeslot(timeslot);
      }
    }

    return TimetableSummary(
      totalSubjects: uniqueSubjects.length,
      totalUnits: totalUnits,
      totalWeeklyHours: totalWeeklyHours,
      conflictCount: conflictCount,
    );
  }

  double _hoursFromTimeslot(Timeslot timeslot) {
    try {
      final start = DateTime.parse('2000-01-01 ${timeslot.startTime}');
      final end = DateTime.parse('2000-01-01 ${timeslot.endTime}');
      return end.difference(start).inMinutes / 60.0;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildSimpleStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color cardBg, {
    bool compact = false,
  }) {
    final card = Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
            child: Icon(icon, color: color, size: compact ? 22 : 24),
          ),
          SizedBox(width: compact ? 12 : 16),
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
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.bold,
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
}

class ListTiles extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;

  const ListTiles({
    super.key,
    this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 4),
                subtitle,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}
