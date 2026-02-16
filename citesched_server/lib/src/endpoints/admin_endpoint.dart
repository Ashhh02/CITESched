import 'package:serverpod/serverpod.dart';

import '../auth/scopes.dart';
import '../generated/protocol.dart';
import '../services/scheduling_service.dart';

/// Admin-only endpoint for managing scheduling data and user roles.
/// Only users with the 'admin' scope can access these methods.
class AdminEndpoint extends Endpoint {
  @override
  Set<Scope> get requiredScopes => {AppScopes.admin};

  // ─── Role Management ─────────────────────────────────────────────────

  /// Assign or change a user's role (admin, faculty, student).
  Future<UserRole> assignRole(
    Session session, {
    required String userId,
    required String role,
  }) async {
    // Validate the role
    if (!['admin', 'faculty', 'student'].contains(role)) {
      throw Exception(
        'Invalid role: $role. Must be admin, faculty, or student.',
      );
    }

    // Check if a role already exists for this user
    var existing = await UserRole.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing != null) {
      // Update the existing role
      existing.role = role;
      return await UserRole.db.updateRow(session, existing);
    } else {
      // Create a new role entry
      return await UserRole.db.insertRow(
        session,
        UserRole(userId: userId, role: role),
      );
    }
  }

  /// Get all user roles.
  Future<List<UserRole>> getAllUserRoles(Session session) async {
    return await UserRole.db.find(session);
  }

  // ─── Faculty CRUD ────────────────────────────────────────────────────

  /// Create a new faculty member with validation.
  Future<Faculty> createFaculty(Session session, Faculty faculty) async {
    // Validate email format
    if (!_isValidEmail(faculty.email)) {
      throw Exception('Invalid email format: ${faculty.email}');
    }

    // Check email uniqueness
    var existing = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(faculty.email),
    );
    if (existing != null) {
      throw Exception('Faculty with email ${faculty.email} already exists');
    }

    // Validate maxLoad
    if (faculty.maxLoad <= 0) {
      throw Exception('Max load must be greater than 0');
    }

    // Set timestamps
    faculty.createdAt = DateTime.now();
    faculty.updatedAt = DateTime.now();

    return await Faculty.db.insertRow(session, faculty);
  }

  /// Get all faculty members.
  Future<List<Faculty>> getAllFaculty(Session session) async {
    return await Faculty.db.find(session);
  }

  /// Update a faculty member with validation.
  Future<Faculty> updateFaculty(Session session, Faculty faculty) async {
    // Ensure faculty exists
    var existing = await Faculty.db.findById(session, faculty.id!);
    if (existing == null) {
      throw Exception('Faculty not found with ID: ${faculty.id}');
    }

    // Validate email format
    if (!_isValidEmail(faculty.email)) {
      throw Exception('Invalid email format: ${faculty.email}');
    }

    // Check email uniqueness (excluding current faculty)
    var emailConflict = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(faculty.email),
    );
    if (emailConflict != null && emailConflict.id != faculty.id) {
      throw Exception('Faculty with email ${faculty.email} already exists');
    }

    // Validate maxLoad
    if (faculty.maxLoad <= 0) {
      throw Exception('Max load must be greater than 0');
    }

    // Update timestamp
    faculty.updatedAt = DateTime.now();

    return await Faculty.db.updateRow(session, faculty);
  }

  /// Delete a faculty member by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteFaculty(Session session, int id) async {
    var faculty = await Faculty.db.findById(session, id);
    if (faculty == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete faculty: ${schedules.length} active schedule(s) exist. '
        'Please remove or reassign schedules first.',
      );
    }

    await Faculty.db.deleteRow(session, faculty);
    return true;
  }

  // ─── Student CRUD ────────────────────────────────────────────────────

  /// Create a new student with validation.
  Future<Student> createStudent(Session session, Student student) async {
    // Validate email format
    if (!_isValidEmail(student.email)) {
      throw Exception('Invalid email format: ${student.email}');
    }

    // Check email uniqueness
    var existing = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(student.email),
    );
    if (existing != null) {
      throw Exception('Student with email ${student.email} already exists');
    }

    // Check student number uniqueness
    var existingNumber = await Student.db.findFirstRow(
      session,
      where: (t) => t.studentNumber.equals(student.studentNumber),
    );
    if (existingNumber != null) {
      throw Exception(
        'Student with number ${student.studentNumber} already exists',
      );
    }

    // Set timestamps
    student.createdAt = DateTime.now();
    student.updatedAt = DateTime.now();

    return await Student.db.insertRow(session, student);
  }

  /// Get all students.
  Future<List<Student>> getAllStudents(Session session) async {
    return await Student.db.find(session);
  }

  /// Update a student with validation.
  Future<Student> updateStudent(Session session, Student student) async {
    // Ensure student exists
    var existing = await Student.db.findById(session, student.id!);
    if (existing == null) {
      throw Exception('Student not found with ID: ${student.id}');
    }

    // Validate email format
    if (!_isValidEmail(student.email)) {
      throw Exception('Invalid email format: ${student.email}');
    }

    // Check email uniqueness (excluding current student)
    var emailConflict = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(student.email),
    );
    if (emailConflict != null && emailConflict.id != student.id) {
      throw Exception('Student with email ${student.email} already exists');
    }

    // Check student number uniqueness (excluding current student)
    var numberConflict = await Student.db.findFirstRow(
      session,
      where: (t) => t.studentNumber.equals(student.studentNumber),
    );
    if (numberConflict != null && numberConflict.id != student.id) {
      throw Exception(
        'Student with number ${student.studentNumber} already exists',
      );
    }

    // Update timestamp
    student.updatedAt = DateTime.now();

    return await Student.db.updateRow(session, student);
  }

  /// Delete a student by ID.
  Future<bool> deleteStudent(Session session, int id) async {
    var student = await Student.db.findById(session, id);
    if (student == null) return false;

    // Optional: Check for related data like grades/enrollments if they existed
    // For now, just delete

    await Student.db.deleteRow(session, student);
    return true;
  }

  // ─── Room CRUD ───────────────────────────────────────────────────────

  /// Create a new room with validation.
  Future<Room> createRoom(Session session, Room room) async {
    // Validate capacity
    if (room.capacity <= 0) {
      throw Exception('Room capacity must be greater than 0');
    }

    // Check room name uniqueness per building
    var existing = await Room.db.findFirstRow(
      session,
      where: (t) => t.name.equals(room.name) & t.building.equals(room.building),
    );
    if (existing != null) {
      throw Exception(
        'Room ${room.name} already exists in building ${room.building}',
      );
    }

    // Set timestamps
    room.createdAt = DateTime.now();
    room.updatedAt = DateTime.now();

    return await Room.db.insertRow(session, room);
  }

  /// Get all rooms.
  Future<List<Room>> getAllRooms(Session session) async {
    return await Room.db.find(session);
  }

  /// Update a room with validation.
  Future<Room> updateRoom(Session session, Room room) async {
    // Ensure room exists
    var existing = await Room.db.findById(session, room.id!);
    if (existing == null) {
      throw Exception('Room not found with ID: ${room.id}');
    }

    // Validate capacity
    if (room.capacity <= 0) {
      throw Exception('Room capacity must be greater than 0');
    }

    // Check room name uniqueness per building (excluding current room)
    var nameConflict = await Room.db.findFirstRow(
      session,
      where: (t) => t.name.equals(room.name) & t.building.equals(room.building),
    );
    if (nameConflict != null && nameConflict.id != room.id) {
      throw Exception(
        'Room ${room.name} already exists in building ${room.building}',
      );
    }

    // Update timestamp
    room.updatedAt = DateTime.now();

    return await Room.db.updateRow(session, room);
  }

  /// Delete a room by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteRoom(Session session, int id) async {
    var room = await Room.db.findById(session, id);
    if (room == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.roomId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete room: ${schedules.length} active schedule(s) exist. '
        'Please remove or reassign schedules first.',
      );
    }

    await Room.db.deleteRow(session, room);
    return true;
  }

  // ─── Subject CRUD ────────────────────────────────────────────────────

  /// Create a new subject with validation.
  Future<Subject> createSubject(Session session, Subject subject) async {
    // Validate subject code format (basic check)
    if (subject.code.trim().isEmpty) {
      throw Exception('Subject code cannot be empty');
    }

    // Validate units
    if (subject.units <= 0) {
      throw Exception('Subject units must be greater than 0');
    }

    // Set timestamps
    subject.createdAt = DateTime.now();
    subject.updatedAt = DateTime.now();

    return await Subject.db.insertRow(session, subject);
  }

  /// Get all subjects.
  Future<List<Subject>> getAllSubjects(Session session) async {
    return await Subject.db.find(session);
  }

  /// Update a subject with validation.
  Future<Subject> updateSubject(Session session, Subject subject) async {
    // Ensure subject exists
    var existing = await Subject.db.findById(session, subject.id!);
    if (existing == null) {
      throw Exception('Subject not found with ID: ${subject.id}');
    }

    // Validate subject code
    if (subject.code.trim().isEmpty) {
      throw Exception('Subject code cannot be empty');
    }

    // Validate units
    if (subject.units <= 0) {
      throw Exception('Subject units must be greater than 0');
    }

    // Update timestamp
    subject.updatedAt = DateTime.now();

    return await Subject.db.updateRow(session, subject);
  }

  /// Delete a subject by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteSubject(Session session, int id) async {
    var subject = await Subject.db.findById(session, id);
    if (subject == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.subjectId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete subject: ${schedules.length} active schedule(s) exist. '
        'Please remove schedules first.',
      );
    }

    await Subject.db.deleteRow(session, subject);
    return true;
  }

  // ─── Timeslot CRUD ───────────────────────────────────────────────────

  /// Create a new timeslot with validation.
  Future<Timeslot> createTimeslot(Session session, Timeslot timeslot) async {
    // Validate time format and logic
    if (!_isValidTimeFormat(timeslot.startTime)) {
      throw Exception(
        'Invalid start time format: ${timeslot.startTime}. Use HH:mm format.',
      );
    }
    if (!_isValidTimeFormat(timeslot.endTime)) {
      throw Exception(
        'Invalid end time format: ${timeslot.endTime}. Use HH:mm format.',
      );
    }

    // Ensure start time is before end time
    if (!_isStartBeforeEnd(timeslot.startTime, timeslot.endTime)) {
      throw Exception('Start time must be before end time');
    }

    // Set timestamps
    timeslot.createdAt = DateTime.now();
    timeslot.updatedAt = DateTime.now();

    return await Timeslot.db.insertRow(session, timeslot);
  }

  /// Get all timeslots.
  Future<List<Timeslot>> getAllTimeslots(Session session) async {
    return await Timeslot.db.find(session);
  }

  /// Update a timeslot with validation.
  Future<Timeslot> updateTimeslot(Session session, Timeslot timeslot) async {
    // Ensure timeslot exists
    var existing = await Timeslot.db.findById(session, timeslot.id!);
    if (existing == null) {
      throw Exception('Timeslot not found with ID: ${timeslot.id}');
    }

    // Validate time format and logic
    if (!_isValidTimeFormat(timeslot.startTime)) {
      throw Exception(
        'Invalid start time format: ${timeslot.startTime}. Use HH:mm format.',
      );
    }
    if (!_isValidTimeFormat(timeslot.endTime)) {
      throw Exception(
        'Invalid end time format: ${timeslot.endTime}. Use HH:mm format.',
      );
    }

    // Ensure start time is before end time
    if (!_isStartBeforeEnd(timeslot.startTime, timeslot.endTime)) {
      throw Exception('Start time must be before end time');
    }

    // Update timestamp
    timeslot.updatedAt = DateTime.now();

    return await Timeslot.db.updateRow(session, timeslot);
  }

  /// Delete a timeslot by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteTimeslot(Session session, int id) async {
    var timeslot = await Timeslot.db.findById(session, id);
    if (timeslot == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.timeslotId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete timeslot: ${schedules.length} active schedule(s) exist. '
        'Please remove schedules first.',
      );
    }

    await Timeslot.db.deleteRow(session, timeslot);
    return true;
  }

  // ─── Schedule CRUD ───────────────────────────────────────────────────

  /// Create a new schedule entry with conflict detection.
  Future<Schedule> createSchedule(Session session, Schedule schedule) async {
    var schedulingService = SchedulingService();

    // Validate schedule entry against all conflicts
    await schedulingService.validateScheduleEntry(session, schedule);

    // Set timestamps
    schedule.createdAt = DateTime.now();
    schedule.updatedAt = DateTime.now();

    return await Schedule.db.insertRow(session, schedule);
  }

  /// Get all schedule entries.
  Future<List<Schedule>> getAllSchedules(Session session) async {
    return await Schedule.db.find(session);
  }

  /// Update a schedule entry with conflict detection.
  Future<Schedule> updateSchedule(Session session, Schedule schedule) async {
    // Ensure schedule exists
    var existing = await Schedule.db.findById(session, schedule.id!);
    if (existing == null) {
      throw Exception('Schedule not found with ID: ${schedule.id}');
    }

    var schedulingService = SchedulingService();

    // Validate schedule entry (excluding current schedule from conflict checks)
    await schedulingService.validateScheduleEntry(
      session,
      schedule,
      excludeScheduleId: schedule.id,
    );

    // Update timestamp
    schedule.updatedAt = DateTime.now();

    return await Schedule.db.updateRow(session, schedule);
  }

  /// Delete a schedule entry by ID.
  Future<bool> deleteSchedule(Session session, int id) async {
    var schedule = await Schedule.db.findById(session, id);
    if (schedule == null) return false;
    await Schedule.db.deleteRow(session, schedule);
    return true;
  }

  // ─── Schedule Generation ─────────────────────────────────────────────

  /// Generate schedules using the scheduling service.
  Future<GenerateScheduleResponse> generateSchedule(
    Session session,
    GenerateScheduleRequest request,
  ) async {
    var schedulingService = SchedulingService();
    return await schedulingService.generateSchedule(session, request);
  }

  // ─── Helper Methods ──────────────────────────────────────────────────

  /// Validate email format using a simple regex.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate time format (HH:mm).
  bool _isValidTimeFormat(String time) {
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  /// Check if start time is before end time.
  bool _isStartBeforeEnd(String startTime, String endTime) {
    try {
      var startParts = startTime.split(':');
      var endParts = endTime.split(':');

      var startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      var endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      return startMinutes < endMinutes;
    } catch (e) {
      return false;
    }
  }
  // ─── Dashboard Stats ─────────────────────────────────────────────────

  /// Get aggregated dashboard statistics.
  Future<DashboardStats> getDashboardStats(Session session) async {
    // 1. Get Counts
    var totalSchedules = await Schedule.db.count(session);
    var totalFaculty = await Faculty.db.count(session);
    var totalStudents = await Student.db.count(session);

    // 2. Calculate Faculty Load
    // Fetch all schedules and faculty to calculate load in memory
    // (Optimization: In a real large-scale app, this should be a custom SQL query)
    var allSchedules = await Schedule.db.find(session);
    var allFaculty = await Faculty.db.find(session);
    var allSubjects = await Subject.db.find(session);

    // Map subject ID to units for quick lookup
    var subjectUnits = {for (var s in allSubjects) s.id!: s.units};

    List<FacultyLoadData> facultyLoad = [];
    for (var faculty in allFaculty) {
      double currentLoad = 0;
      var facultySchedules = allSchedules.where(
        (s) => s.facultyId == faculty.id,
      );

      for (var schedule in facultySchedules) {
        // Assume 1 unit = 1 hour for now, or use subject units if available
        // You might want to adjust this logic based on how 'units' map to 'hours'
        currentLoad += (subjectUnits[schedule.subjectId] ?? 3).toDouble();
      }

      facultyLoad.add(
        FacultyLoadData(
          facultyName: faculty.name,
          currentLoad: currentLoad,
          maxLoad: faculty.maxLoad.toDouble(),
        ),
      );
    }

    // 3. Integrity Check (Conflicts)
    // Re-run validation on all schedules to find current conflicts
    // This is an expensive operation, so use with caution on large datasets
    List<ScheduleConflict> conflicts = [];

    // We can't easily "find all conflicts" without checking each schedule against others.
    // A simpler approach for the dashboard might be to just return a count if we had a
    // persistent 'Conflict' table. Since we don't, we'll do a quick scan or just return 0
    // if we trust the 'createSchedule' validation.

    // However, to satisfy the requirement of "Unresolved Conflicts" which implies
    // some might exist, let's scan.
    // Optimization: Only scan if requested or cache this.
    // For now, let's just return an empty list or a placeholder if we want to be fast,
    // OR implementation the scan.

    // Let's implement a "soft" scan: Check if any room is double booked or faculty double booked.
    // This is O(N^2) naive, but O(N) if we sort/group.

    // We will Group by Room+Time and Faculty+Time
    // ... (logic for conflict detection) ...

    // For this implementation, we will trust the `createSchedule` validation and return 0
    // unless we specifically add a mechanism to flag "force-added" schedules.
    // But since the user asked for "unresolved conflicts", let's simulate a check
    // by looking for overlaps.

    // Group schedules by Timeslot
    var schedulesByTime = <int, List<Schedule>>{};
    for (var s in allSchedules) {
      schedulesByTime.putIfAbsent(s.timeslotId, () => []).add(s);
    }

    // Check constraints within each timeslot
    for (var timeslotId in schedulesByTime.keys) {
      var concurrent = schedulesByTime[timeslotId]!;

      // Check Room Conflicts
      var schedulesByRoom = <int, List<Schedule>>{};
      for (var s in concurrent) {
        schedulesByRoom.putIfAbsent(s.roomId, () => []).add(s);
      }

      schedulesByRoom.forEach((roomId, roomSchedules) {
        if (roomSchedules.length > 1) {
          conflicts.add(
            ScheduleConflict(
              type: 'Room Conflict',
              message:
                  'Multiple classes in Room $roomId at Timeslot $timeslotId',
              details:
                  'Schedules: ${roomSchedules.map((s) => s.id).join(', ')}',
            ),
          );
        }
      });

      // Check Faculty Conflicts
      var schedulesByFaculty = <int, List<Schedule>>{};
      for (var s in concurrent) {
        schedulesByFaculty.putIfAbsent(s.facultyId, () => []).add(s);
      }
      schedulesByFaculty.forEach((facultyId, facSchedules) {
        if (facSchedules.length > 1) {
          conflicts.add(
            ScheduleConflict(
              type: 'Faculty Conflict',
              message:
                  'Faculty $facultyId has multiple classes at Timeslot $timeslotId',
              details: 'Schedules: ${facSchedules.map((s) => s.id).join(', ')}',
            ),
          );
        }
      });
    }

    return DashboardStats(
      totalSchedules: totalSchedules,
      totalFaculty: totalFaculty,
      totalStudents: totalStudents,
      totalConflicts: conflicts.length,
      facultyLoad: facultyLoad,
      recentConflicts: conflicts,
    );
  }
}
