import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

/// Service class responsible for generating administrative reports.
class ReportService {
  // ─── Faculty Load Report ──────────────────────────────────────────────

  /// Generates a report on faculty teaching loads.
  Future<List<FacultyLoadReport>> generateFacultyLoadReport(
    Session session,
  ) async {
    var facultyList = await Faculty.db.find(session);
    var allSchedules = await Schedule.db.find(session);
    var allSubjects = await Subject.db.find(session);

    // Map subject ID to units
    var subjectMap = {for (var s in allSubjects) s.id!: s};

    var reports = <FacultyLoadReport>[];

    for (var faculty in facultyList) {
      var facultySchedules = allSchedules.where(
        (s) => s.facultyId == faculty.id,
      );

      double totalUnits = 0;
      double totalHours = 0;
      int totalSubjects = facultySchedules.length;

      for (var schedule in facultySchedules) {
        var subject = subjectMap[schedule.subjectId];
        if (schedule.units != null) {
          totalUnits += schedule.units!;
        } else if (subject != null) {
          totalUnits += subject.units;
        }

        if (schedule.hours != null) {
          totalHours += schedule.hours!;
        } else if (subject != null) {
          // Fallback if schedule doesn't have hours
          totalHours += subject.units;
        }
      }

      String status = 'Balanced';
      if (totalSubjects == 0) {
        status = 'No Load';
      } else if (totalUnits < ((faculty.maxLoad ?? 0) * 0.7)) {
        status = 'Underloaded';
      } else if (totalUnits > (faculty.maxLoad ?? 0)) {
        status = 'Overloaded';
      } else if (totalUnits == (faculty.maxLoad ?? 0)) {
        status = 'Max Load';
      }

      reports.add(
        FacultyLoadReport(
          facultyId: faculty.id!,
          facultyName: faculty.name,
          totalUnits: totalUnits,
          totalHours: totalHours,
          totalSubjects: totalSubjects,
          loadStatus: status,
          program: faculty.program?.name,
        ),
      );
    }
    return reports;
  }

  // ─── Room Utilization Report ──────────────────────────────────────────

  /// Generates a report on room usage.
  Future<List<RoomUtilizationReport>> generateRoomUtilizationReport(
    Session session,
  ) async {
    var rooms = await Room.db.find(session);
    var allSchedules = await Schedule.db.find(session);

    var totalTimeslotsCount = await Timeslot.db.count(session);
    if (totalTimeslotsCount == 0) totalTimeslotsCount = 1;

    var reports = <RoomUtilizationReport>[];

    for (var room in rooms) {
      var roomSchedules = allSchedules.where((s) => s.roomId == room.id);
      var totalBookings = roomSchedules.length;
      var utilization = (totalBookings / totalTimeslotsCount) * 100;

      reports.add(
        RoomUtilizationReport(
          roomId: room.id!,
          roomName: room.name,
          utilizationPercentage: utilization,
          totalBookings: totalBookings,
          isActive: room.isActive,
          program: room.program.name,
        ),
      );
    }
    return reports;
  }

  // ─── Conflict Summary Report ──────────────────────────────────────────

  /// Generates a summary of detected conflicts.
  Future<ConflictSummaryReport> generateConflictSummary(Session session) async {
    List<ScheduleConflict> conflicts = await ConflictService().getAllConflicts(
      session,
    );

    var counts = <String, int>{};
    for (var c in conflicts) {
      counts[c.type] = (counts[c.type] ?? 0) + 1;
    }

    String mostFrequent = 'None';
    int maxCount = 0;
    counts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = type;
      }
    });

    return ConflictSummaryReport(
      totalConflicts: conflicts.length,
      conflictsByType: counts,
      resolvedConflicts: 0,
      mostFrequentConflictType: mostFrequent,
    );
  }

  // ─── Schedule Overview Report ─────────────────────────────────────────

  /// Generates high-level schedule statistics.
  Future<ScheduleOverviewReport> generateScheduleOverview(
    Session session,
  ) async {
    var allSchedules = await Schedule.db.find(session);
    var allSubjects = await Subject.db.find(session);

    var subjectMap = {for (var s in allSubjects) s.id!: s};

    var itSchedules = 0;
    var emcSchedules = 0;
    var termCounts = <String, int>{};

    for (var s in allSchedules) {
      var subject = subjectMap[s.subjectId];
      if (subject != null) {
        if (subject.program == Program.it) {
          itSchedules++;
        } else if (subject.program == Program.emc) {
          emcSchedules++;
        }

        String termKey = subject.term.toString();
        termCounts[termKey] = (termCounts[termKey] ?? 0) + 1;
      }
    }

    return ScheduleOverviewReport(
      totalSchedules: allSchedules.length,
      schedulesByProgram: {
        'IT': itSchedules,
        'EMC': emcSchedules,
      },
      schedulesByTerm: termCounts,
      activeTerm: 1,
      academicYear: '2025-2026',
    );
  }
}
