import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

class TimetableService {
  final ConflictService _conflictService = ConflictService();

  String _normalizeSectionCode(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<int?> resolveSectionIdByCode(
    Session session,
    String sectionCode,
  ) async {
    final code = sectionCode.trim();
    if (code.isEmpty) return null;

    final normalized = _normalizeSectionCode(code);
    final sections = await Section.db.find(session);
    for (final section in sections) {
      if (_normalizeSectionCode(section.sectionCode) == normalized) {
        return section.id;
      }
    }
    return null;
  }

  Future<List<Schedule>> _fetchScheduleRowsByNormalizedSection(
    Session session,
    String sectionCode,
  ) async {
    final normalized = _normalizeSectionCode(sectionCode);
    if (normalized.isEmpty) return [];

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.section.notEquals(null) & t.isActive.equals(true),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );

    final matched = schedules
        .where(
          (s) => _normalizeSectionCode(s.section) == normalized,
        )
        .toList();

    return matched;
  }

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
    return _toScheduleInfo(
      session,
      schedules,
      hasConflictsFilter: filter.hasConflicts,
      loadTypeFilter: filter.loadType,
    );
  }

  Future<List<ScheduleInfo>> fetchSchedulesBySectionId(
    Session session,
    int sectionId, {
    String? fallbackSectionCode,
  }) async {
    final collected = <Schedule>[];

    void mergeSchedules(List<Schedule> incoming) {
      for (final schedule in incoming) {
        final id = schedule.id;
        final exists = id != null
            ? collected.any((s) => s.id == id)
            : collected.contains(schedule);
        if (!exists) {
          collected.add(schedule);
        }
      }
    }

    final bySectionId = await Schedule.db.find(
      session,
      where: (t) => t.sectionId.equals(sectionId) & t.isActive.equals(true),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );
    mergeSchedules(bySectionId);

    if (fallbackSectionCode != null &&
        fallbackSectionCode.isNotEmpty) {
      final resolvedSectionId =
          await resolveSectionIdByCode(session, fallbackSectionCode);
      if (resolvedSectionId != null && resolvedSectionId != sectionId) {
        final resolvedSectionRows = await Schedule.db.find(
          session,
          where: (t) =>
              t.sectionId.equals(resolvedSectionId) & t.isActive.equals(true),
          include: Schedule.include(
            subject: Subject.include(),
            faculty: Faculty.include(),
            room: Room.include(),
            timeslot: Timeslot.include(),
          ),
        );
        mergeSchedules(resolvedSectionRows);
      }
    }

    if (fallbackSectionCode != null &&
        fallbackSectionCode.isNotEmpty) {
      final byExactSectionCode = await Schedule.db.find(
        session,
        where: (t) =>
            t.section.equals(fallbackSectionCode) & t.isActive.equals(true),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
      mergeSchedules(byExactSectionCode);
    }

    if (fallbackSectionCode != null &&
        fallbackSectionCode.isNotEmpty) {
      final byNormalizedSectionCode = await _fetchScheduleRowsByNormalizedSection(
        session,
        fallbackSectionCode,
      );
      mergeSchedules(byNormalizedSectionCode);
    }

    return _toScheduleInfo(session, collected);
  }

  Future<List<ScheduleInfo>> _toScheduleInfo(
    Session session,
    List<Schedule> schedules, {
    bool? hasConflictsFilter,
    SubjectType? loadTypeFilter,
  }) async {
    var result = <ScheduleInfo>[];
    for (var s in schedules) {
      // Defensive hydration for legacy rows / partial relation payloads.
      if (s.timeslot == null && s.timeslotId != null) {
        s.timeslot = await Timeslot.db.findById(session, s.timeslotId!);
      }
      if (s.subject == null) {
        s.subject = await Subject.db.findById(session, s.subjectId);
      }
      if (s.faculty == null) {
        s.faculty = await Faculty.db.findById(session, s.facultyId);
      }
      if (s.room == null && s.roomId != null) {
        s.room = await Room.db.findById(session, s.roomId!);
      }

      var conflicts = await _conflictService.validateSchedule(
        session,
        s,
        excludeScheduleId: s.id,
      );

      if (hasConflictsFilter != null) {
        if (hasConflictsFilter && conflicts.isEmpty) continue;
        if (!hasConflictsFilter && conflicts.isNotEmpty) continue;
      }

      if (loadTypeFilter != null) {
        if (!(s.loadTypes?.contains(loadTypeFilter) ?? false)) continue;
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
