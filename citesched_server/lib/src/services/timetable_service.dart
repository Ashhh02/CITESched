import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

class TimetableService {
  final ConflictService _conflictService = ConflictService();

  String _normalizeSectionCode(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
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
    final schedules = await Schedule.db.find(
      session,
      where: (t) => _buildScheduleFilter(t, filter),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );
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
    void mergeSchedules(List<Schedule> incoming) =>
        _mergeSchedules(collected, incoming);

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

    if (fallbackSectionCode != null && fallbackSectionCode.isNotEmpty) {
      final resolvedSectionId = await resolveSectionIdByCode(
        session,
        fallbackSectionCode,
      );
      if (resolvedSectionId != null && resolvedSectionId != sectionId) {
        mergeSchedules(
          await _fetchSchedulesBySectionId(session, resolvedSectionId),
        );
      }
    }

    if (fallbackSectionCode != null && fallbackSectionCode.isNotEmpty) {
      mergeSchedules(
        await _fetchSchedulesBySectionCode(session, fallbackSectionCode),
      );
    }

    if (fallbackSectionCode != null && fallbackSectionCode.isNotEmpty) {
      final byNormalizedSectionCode =
          await _fetchScheduleRowsByNormalizedSection(
            session,
            fallbackSectionCode,
          );
      mergeSchedules(byNormalizedSectionCode);
    }

    return _toScheduleInfo(session, collected);
  }

  Expression _buildScheduleFilter(
    ScheduleTable t,
    TimetableFilterRequest filter,
  ) {
    Expression where = t.isActive.equals(true);

    if (filter.program != null) {
      where &= t.subject.program.equals(filter.program);
    }
    if (filter.section != null && filter.section!.isNotEmpty) {
      where &= t.section.equals(filter.section);
    }
    if (filter.yearLevel != null) {
      where &= t.subject.yearLevel.equals(filter.yearLevel);
    }
    if (filter.facultyId != null) {
      where &= t.facultyId.equals(filter.facultyId);
    }
    if (filter.roomId != null) {
      where &= t.roomId.equals(filter.roomId);
    }
    return where;
  }

  void _mergeSchedules(List<Schedule> target, List<Schedule> incoming) {
    for (final schedule in incoming) {
      final id = schedule.id;
      final exists = id != null
          ? target.any((s) => s.id == id)
          : target.contains(schedule);
      if (!exists) {
        target.add(schedule);
      }
    }
  }

  Future<List<Schedule>> _fetchSchedulesBySectionId(
    Session session,
    int sectionId,
  ) {
    return Schedule.db.find(
      session,
      where: (t) => t.sectionId.equals(sectionId) & t.isActive.equals(true),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );
  }

  Future<List<Schedule>> _fetchSchedulesBySectionCode(
    Session session,
    String sectionCode,
  ) {
    return Schedule.db.find(
      session,
      where: (t) => t.section.equals(sectionCode) & t.isActive.equals(true),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );
  }

  Future<List<ScheduleInfo>> _toScheduleInfo(
    Session session,
    List<Schedule> schedules, {
    bool? hasConflictsFilter,
    SubjectType? loadTypeFilter,
  }) async {
    final result = <ScheduleInfo>[];
    for (var s in schedules) {
      await _hydrateSchedule(session, s);
      final conflicts = await _conflictService.validateSchedule(
        session,
        s,
        excludeScheduleId: s.id,
      );

      if (!_passesConflictFilter(conflicts, hasConflictsFilter)) continue;
      if (!_passesLoadTypeFilter(s, loadTypeFilter)) continue;

      result.add(ScheduleInfo(schedule: s, conflicts: conflicts));
    }

    return result;
  }

  Future<void> _hydrateSchedule(Session session, Schedule schedule) async {
    if (schedule.timeslot == null && schedule.timeslotId != null) {
      schedule.timeslot =
          await Timeslot.db.findById(session, schedule.timeslotId!);
    }
    schedule.subject ??= await Subject.db.findById(
      session,
      schedule.subjectId,
    );
    schedule.faculty ??= await Faculty.db.findById(
      session,
      schedule.facultyId,
    );
    if (schedule.room == null && schedule.roomId != null) {
      schedule.room = await Room.db.findById(session, schedule.roomId!);
    }
  }

  bool _passesConflictFilter(
    List<ScheduleConflict> conflicts,
    bool? hasConflictsFilter,
  ) {
    if (hasConflictsFilter == null) return true;
    if (hasConflictsFilter && conflicts.isEmpty) return false;
    if (!hasConflictsFilter && conflicts.isNotEmpty) return false;
    return true;
  }

  bool _passesLoadTypeFilter(Schedule schedule, SubjectType? loadTypeFilter) {
    if (loadTypeFilter == null) return true;
    return schedule.loadTypes?.contains(loadTypeFilter) ?? false;
  }

  Future<TimetableSummary> fetchSectionSummary(
    Session session,
    TimetableFilterRequest filter,
  ) async {
    // Similar query but specifically for summary
    var schedulesInfo = await fetchSchedulesWithFilters(session, filter);

    double totalUnits = 0;
    double totalWeeklyHours = 0;
    final uniqueSubjects = <int>{};
    int conflictCount = 0;

    for (var info in schedulesInfo) {
      final s = info.schedule;
      totalUnits += s.units ?? 0;
      totalWeeklyHours += _hoursFromTimeslot(s.timeslot);
      uniqueSubjects.add(s.subjectId);
      if (info.conflicts.isNotEmpty) conflictCount++;
    }

    return TimetableSummary(
      totalSubjects: uniqueSubjects.length,
      totalUnits: totalUnits,
      totalWeeklyHours: totalWeeklyHours,
      conflictCount: conflictCount,
    );
  }

  double _hoursFromTimeslot(Timeslot? timeslot) {
    if (timeslot == null) return 0;
    try {
      final start = DateTime.parse('2000-01-01 ${timeslot.startTime}');
      final end = DateTime.parse('2000-01-01 ${timeslot.endTime}');
      return end.difference(start).inMinutes / 60.0;
    } catch (_) {
      return 3.0;
    }
  }
}
