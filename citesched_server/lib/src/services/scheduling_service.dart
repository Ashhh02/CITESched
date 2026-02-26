import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

/// Service class for handling scheduling logic.
/// Uses [ConflictService] to validate schedule entries and generates schedules.
/// Respects faculty availability preferences from the FacultyAvailability table.
class SchedulingService {
  final ConflictService _conflictService = ConflictService();

  // ─── Schedule Generation ────────────────────────────────────────────

  /// Generate schedules using a greedy algorithm.
  /// Attempts to assign each subject to available timeslots while respecting
  /// all constraints including faculty day/time availability.
  Future<GenerateScheduleResponse> generateSchedule(
    Session session,
    GenerateScheduleRequest request,
  ) async {
    var generatedSchedules = <Schedule>[];
    var conflicts = <ScheduleConflict>[];

    // Validate input
    if (request.subjectIds.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No subjects provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }

    if (request.sections.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No sections provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }

    // Fetch all entities
    var subjects = await Future.wait(
      request.subjectIds.map((id) => Subject.db.findById(session, id)),
    );
    var faculties = await Future.wait(
      request.facultyIds.map((id) => Faculty.db.findById(session, id)),
    );
    var rooms = await Future.wait(
      request.roomIds.map((id) => Room.db.findById(session, id)),
    );
    var timeslots = await Future.wait(
      request.timeslotIds.map((id) => Timeslot.db.findById(session, id)),
    );

    // Filter out nulls
    var validSubjects = subjects.whereType<Subject>().toList();
    var validFaculties = faculties.whereType<Faculty>().toList();
    var validRooms = rooms.whereType<Room>().toList();
    var validTimeslots = timeslots.whereType<Timeslot>().toList();

    // Pre-load faculty availability preferences for fast lookup
    var facultyAvailMap = <int, List<FacultyAvailability>>{};
    for (var faculty in validFaculties) {
      var avails = await FacultyAvailability.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
      );
      facultyAvailMap[faculty.id!] = avails;
    }

    // Track faculty assignments for load balancing
    var facultyAssignments = <int, int>{};
    for (var faculty in validFaculties) {
      facultyAssignments[faculty.id!] = 0;
    }

    // Greedy algorithm: For each subject and section, try to assign to available slot
    for (var subject in validSubjects) {
      for (var section in request.sections) {
        var assigned = false;

        // Try each faculty
        for (var faculty in validFaculties) {
          if (assigned) break;

          // Quick maxLoad pre-check
          var currentLoad = facultyAssignments[faculty.id!] ?? 0;
          if (currentLoad >= (faculty.maxLoad ?? 0)) continue;

          // Try each timeslot
          for (var timeslot in validTimeslots) {
            if (assigned) break;

            // ── Faculty availability preference check ──
            // If faculty has availability preferences, check if this timeslot fits
            var avails = facultyAvailMap[faculty.id!] ?? [];
            if (avails.isNotEmpty) {
              var fitsAvailability = false;
              for (var avail in avails) {
                if (avail.dayOfWeek == timeslot.day) {
                  final tsStart = _parseTimeToMinutes(timeslot.startTime);
                  final tsEnd = _parseTimeToMinutes(timeslot.endTime);
                  final avStart = _parseTimeToMinutes(avail.startTime);
                  final avEnd = _parseTimeToMinutes(avail.endTime);
                  if (tsStart >= avStart && tsEnd <= avEnd) {
                    fitsAvailability = true;
                    break;
                  }
                }
              }
              if (!fitsAvailability)
                continue; // Skip this timeslot for this faculty
            }

            // Try each room
            for (var room in validRooms) {
              if (assigned) break;

              // Create candidate schedule
              var candidate = Schedule(
                subjectId: subject.id!,
                facultyId: faculty.id!,
                roomId: room.id!,
                timeslotId: timeslot.id!,
                section: section,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // Validate using ConflictService
              var validationConflicts = await _conflictService.validateSchedule(
                session,
                candidate,
              );

              if (validationConflicts.isEmpty) {
                // Valid assignment
                generatedSchedules.add(candidate);
                facultyAssignments[faculty.id!] =
                    (facultyAssignments[faculty.id!] ?? 0) + 1;
                assigned = true;
              }
            }
          }
        }

        // If we couldn't assign this subject-section combination
        if (!assigned) {
          conflicts.add(
            ScheduleConflict(
              type: 'generation_failed',
              message:
                  'Could not assign ${subject.name} (${subject.code}) - Section $section',
              details:
                  'No valid faculty/room/timeslot combination satisfies all constraints (including faculty availability)',
            ),
          );
        }
      }
    }

    // Save successfully generated schedules
    if (generatedSchedules.isNotEmpty) {
      for (var s in generatedSchedules) {
        await Schedule.db.insertRow(session, s);
      }
    }

    // Return results with summary counts
    return GenerateScheduleResponse(
      success: conflicts.isEmpty,
      schedules: generatedSchedules,
      conflicts: conflicts.isEmpty ? null : conflicts,
      totalAssigned: generatedSchedules.length,
      conflictsDetected: conflicts.length,
      unassignedSubjects: conflicts.length,
      message: conflicts.isEmpty
          ? 'Successfully generated ${generatedSchedules.length} schedule entries'
          : '${generatedSchedules.length} assigned, ${conflicts.length} unassigned',
    );
  }

  /// Helper: parse "HH:MM" to minutes since midnight.
  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }
}
