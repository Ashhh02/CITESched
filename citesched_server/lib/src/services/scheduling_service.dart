import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service class for handling scheduling logic and conflict detection.
/// This service validates schedule entries and generates schedules while
/// respecting all constraints (room availability, faculty availability, max load).
class SchedulingService {
  // ─── Conflict Detection Methods ─────────────────────────────────────

  /// Check if a room is available at a given timeslot.
  /// Returns the conflicting schedule if room is already booked, null otherwise.
  /// If [roomId] or [timeslotId] is null, returns null (no conflict possible).
  Future<Schedule?> checkRoomAvailability(
    Session session, {
    required int? roomId,
    required int? timeslotId,
    int? excludeScheduleId, // For updates, exclude the current schedule
  }) async {
    if (roomId == null ||
        roomId == -1 ||
        timeslotId == null ||
        timeslotId == -1)
      return null;

    var query = Schedule.db.find(
      session,
      where: (t) => t.roomId.equals(roomId) & t.timeslotId.equals(timeslotId),
    );

    var conflicts = await query;

    // Filter out the schedule being updated
    if (excludeScheduleId != null) {
      conflicts = conflicts.where((s) => s.id != excludeScheduleId).toList();
    }

    return conflicts.isNotEmpty ? conflicts.first : null;
  }

  /// Check if a faculty member is available at a given timeslot.
  /// Returns the conflicting schedule if faculty is already assigned, null otherwise.
  /// If [timeslotId] is null, returns null.
  Future<Schedule?> checkFacultyAvailability(
    Session session, {
    required int facultyId,
    required int? timeslotId,
    int? excludeScheduleId,
  }) async {
    if (timeslotId == null || timeslotId == -1) return null;

    var query = Schedule.db.find(
      session,
      where: (t) =>
          t.facultyId.equals(facultyId) & t.timeslotId.equals(timeslotId),
    );

    var conflicts = await query;

    // Filter out the schedule being updated
    if (excludeScheduleId != null) {
      conflicts = conflicts.where((s) => s.id != excludeScheduleId).toList();
    }

    return conflicts.isNotEmpty ? conflicts.first : null;
  }

  /// Check if a faculty member has exceeded their maximum teaching load.
  /// Returns true if faculty can take more classes, false otherwise.
  Future<bool> checkFacultyMaxLoad(
    Session session, {
    required int facultyId,
    int? excludeScheduleId,
    double?
    additionalUnits, // Check if adding these units fits (optional logic)
  }) async {
    // Get faculty details
    var faculty = await Faculty.db.findById(session, facultyId);
    if (faculty == null) {
      throw Exception('Faculty not found with ID: $facultyId');
    }

    // Count current schedules for this faculty
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(facultyId),
    );

    // Filter out the schedule being updated
    if (excludeScheduleId != null) {
      schedules = schedules.where((s) => s.id != excludeScheduleId).toList();
    }

    // Determine current load
    // For now, assuming count is the load, or use units if available.
    // If we want to use units, we need to fetch subjects or use cached units.
    // Let's stick to simple count or simple unit sum if we can.
    // But `Schedule` doesn't always have `units` (it's in Subject).
    // For MVP, we'll just check if count < maxLoad (if maxLoad is count-based)
    // or we can implement unit-based load check later.
    // The current implementation is count based: `schedules.length < faculty.maxLoad`.

    return schedules.length < faculty.maxLoad;
  }

  /// Validate a schedule entry against all conflict rules.
  /// Throws an exception with details if any conflict is found.
  Future<void> validateScheduleEntry(
    Session session,
    Schedule schedule, {
    int? excludeScheduleId,
  }) async {
    var conflicts = <ScheduleConflict>[];

    // Check room availability (only if room and time are set)
    if (schedule.roomId != -1 && schedule.timeslotId != -1) {
      var roomConflict = await checkRoomAvailability(
        session,
        roomId: schedule.roomId,
        timeslotId: schedule.timeslotId,
        excludeScheduleId: excludeScheduleId,
      );

      if (roomConflict != null) {
        conflicts.add(
          ScheduleConflict(
            type: 'room_conflict',
            message: 'Room is already booked for this timeslot',
            conflictingScheduleId: roomConflict.id,
            details:
                'Room ID ${schedule.roomId} is already assigned to schedule ID ${roomConflict.id}',
          ),
        );
      }
    }

    // Check faculty availability (only if time is set)
    if (schedule.timeslotId != -1) {
      var facultyConflict = await checkFacultyAvailability(
        session,
        facultyId: schedule.facultyId,
        timeslotId: schedule.timeslotId,
        excludeScheduleId: excludeScheduleId,
      );

      if (facultyConflict != null) {
        conflicts.add(
          ScheduleConflict(
            type: 'faculty_conflict',
            message:
                'Faculty is already assigned to another class at this timeslot',
            conflictingScheduleId: facultyConflict.id,
            details:
                'Faculty ID ${schedule.facultyId} is already assigned to schedule ID ${facultyConflict.id}',
          ),
        );
      }
    }

    // Check faculty max load
    var canTakeMore = await checkFacultyMaxLoad(
      session,
      facultyId: schedule.facultyId,
      excludeScheduleId: excludeScheduleId,
    );

    if (!canTakeMore) {
      var faculty = await Faculty.db.findById(session, schedule.facultyId);
      conflicts.add(
        ScheduleConflict(
          type: 'max_load_exceeded',
          message: 'Faculty has reached maximum teaching load',
          details:
              'Faculty ID ${schedule.facultyId} has reached max load of ${faculty?.maxLoad ?? 0} classes',
        ),
      );
    }

    // If any conflicts found, throw exception
    if (conflicts.isNotEmpty) {
      var messages = conflicts.map((c) => c.message).join('; ');
      throw Exception('Schedule validation failed: $messages');
    }
  }

  // ─── Schedule Generation ────────────────────────────────────────────

  /// Generate schedules using a greedy algorithm.
  /// Attempts to assign each subject to available timeslots while respecting all constraints.
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
      );
    }

    if (request.sections.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No sections provided for schedule generation',
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

          // Check if faculty can take more classes
          var currentLoad = facultyAssignments[faculty.id!] ?? 0;
          if (currentLoad >= faculty.maxLoad) continue;

          // Try each timeslot
          for (var timeslot in validTimeslots) {
            if (assigned) break;

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

              // Check if this assignment is valid
              try {
                await validateScheduleEntry(session, candidate);

                // Valid assignment - add to generated schedules
                generatedSchedules.add(candidate);
                facultyAssignments[faculty.id!] =
                    (facultyAssignments[faculty.id!] ?? 0) + 1;
                assigned = true;
              } catch (e) {
                // Conflict found, try next combination
                continue;
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
                  'Could not find valid assignment for ${subject.name} (${subject.code}) - Section $section',
              details:
                  'No available faculty, room, or timeslot combination found that satisfies all constraints',
            ),
          );
        }
      }
    }

    // Return results
    if (conflicts.isEmpty) {
      return GenerateScheduleResponse(
        success: true,
        schedules: generatedSchedules,
        message:
            'Successfully generated ${generatedSchedules.length} schedule entries',
      );
    } else {
      return GenerateScheduleResponse(
        success: false,
        schedules: generatedSchedules,
        conflicts: conflicts,
        message:
            'Partial generation: ${generatedSchedules.length} schedules created, ${conflicts.length} failed',
      );
    }
  }
}
