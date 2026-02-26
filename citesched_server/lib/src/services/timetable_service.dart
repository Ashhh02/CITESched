import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

class TimetableService {
  final ConflictService _conflictService = ConflictService();

  Future<List<ScheduleInfo>> fetchSchedulesWithFilters(
    Session session,
    TimetableFilterRequest filter,
  ) async {
    // Build query based on filters
    var query = Schedule.db.find(
      session,
      where: (t) {
        Expression where = t.isActive.equals(true);

        if (filter.program != null) {
          where &= t.subject.program.equals(filter.program);
        }

        // Section filter
        if (filter.section != null && filter.section!.isNotEmpty) {
          where &= t.section.equals(filter.section);
        }

        // Year Level filter
        if (filter.yearLevel != null) {
          where &= t.subject.yearLevel.equals(filter.yearLevel);
        }

        // Faculty filter
        if (filter.facultyId != null) {
          where &= t.facultyId.equals(filter.facultyId);
        }

        // Room filter
        if (filter.roomId != null) {
          where &= t.roomId.equals(filter.roomId);
        }

        // Load Type filter is handled post-query since loadTypes is a List

        return where;
      },
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );

    var schedules = await query;

    // Map to ScheduleInfo and check for conflicts
    var result = <ScheduleInfo>[];
    for (var s in schedules) {
      var conflicts = await _conflictService.validateSchedule(
        session,
        s,
        excludeScheduleId: s.id,
      );

      // If hasConflicts filter is set, filter accordingly
      if (filter.hasConflicts != null) {
        if (filter.hasConflicts! && conflicts.isEmpty) continue;
        if (!filter.hasConflicts! && conflicts.isNotEmpty) continue;
      }

      // Filter by loadType (post-query since loadTypes is a List)
      if (filter.loadType != null) {
        if (!(s.loadTypes?.contains(filter.loadType) ?? false)) continue;
      }

      result.add(
        ScheduleInfo(
          schedule: s,
          conflicts: conflicts,
        ),
      );
    }

    return result;
  }

  Future<TimetableSummary> fetchSectionSummary(
    Session session,
    TimetableFilterRequest filter,
  ) async {
    // Similar query but specifically for summary
    var schedulesInfo = await fetchSchedulesWithFilters(session, filter);

    double totalUnits = 0;
    double totalWeeklyHours = 0;
    Set<int> uniqueSubjects = {};
    int conflictCount = 0;

    for (var info in schedulesInfo) {
      var s = info.schedule;
      totalUnits += s.units ?? 0;

      // Calculate hours from timeslot if available
      if (s.timeslot != null) {
        try {
          var start = DateTime.parse('2000-01-01 ${s.timeslot!.startTime}');
          var end = DateTime.parse('2000-01-01 ${s.timeslot!.endTime}');
          totalWeeklyHours += end.difference(start).inMinutes / 60.0;
        } catch (_) {
          // Fallback if parsing fails
          totalWeeklyHours += 3.0;
        }
      }

      uniqueSubjects.add(s.subjectId);

      if (info.conflicts.isNotEmpty) {
        conflictCount++;
      }
    }

    return TimetableSummary(
      totalSubjects: uniqueSubjects.length,
      totalUnits: totalUnits,
      totalWeeklyHours: totalWeeklyHours,
      conflictCount: conflictCount,
    );
  }
}
