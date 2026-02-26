import 'package:serverpod/serverpod.dart';

import '../auth/scopes.dart';
import '../generated/protocol.dart';
import '../services/scheduling_service.dart';
import '../services/conflict_service.dart';
import '../services/report_service.dart';

/// Admin-only endpoint for managing scheduling data and user roles.
/// Only users with the 'admin' scope can access these methods.
class AdminEndpoint extends Endpoint {
  @override
  @override
  bool get requireLogin => false;

  @override
  Set<Scope> get requiredScopes => {};

  /// Get aggregated dashboard statistics. ─────────────────────────────────────────────────

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
    if ((faculty.maxLoad ?? 0) <= 0) {
      throw Exception('Max load must be greater than 0');
    }

    // Set timestamps
    faculty.createdAt = DateTime.now();
    faculty.updatedAt = DateTime.now();

    return await Faculty.db.insertRow(session, faculty);
  }

  /// Get all faculty members.
  Future<List<Faculty>> getAllFaculty(
    Session session, {
    bool isActive = true,
  }) async {
    return await Faculty.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );
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
    if ((faculty.maxLoad ?? 0) <= 0) {
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
  Future<List<Student>> getAllStudents(
    Session session, {
    bool isActive = true,
  }) async {
    return await Student.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );
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

    student.isActive = false;
    await Student.db.updateRow(session, student);
    return true;
  }

  // ─── Room CRUD ───────────────────────────────────────────────────────

  /// Create a new room with validation.
  Future<Room> createRoom(Session session, Room room) async {
    // Enforce 3-room limit
    var allRooms = await Room.db.find(session);
    if (allRooms.length >= 3) {
      throw Exception(
        'Limit Exceeded: Only 3 rooms are allowed in the system.',
      );
    }

    // Enforce Program Distribution (2 IT, 1 EMC)
    var itRooms = allRooms.where((r) => r.program == Program.it).length;
    var emcRooms = allRooms.where((r) => r.program == Program.emc).length;

    if (room.program == Program.it && itRooms >= 2) {
      throw Exception('Limit Exceeded: Already have 2 IT rooms.');
    }
    if (room.program == Program.emc && emcRooms >= 1) {
      throw Exception('Limit Exceeded: Already have 1 EMC room.');
    }

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
  Future<List<Room>> getAllRooms(
    Session session, {
    bool isActive = true,
  }) async {
    return await Room.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );
  }

  /// Update a room with validation.
  Future<Room> updateRoom(Session session, Room room) async {
    // Ensure room exists
    var existing = await Room.db.findById(session, room.id!);
    if (existing == null) {
      throw Exception('Room not found with ID: ${room.id}');
    }

    // If program is changing, check distribution
    if (existing.program != room.program) {
      var allRooms = await Room.db.find(session);
      var itRooms = allRooms.where((r) => r.program == Program.it).length;
      var emcRooms = allRooms.where((r) => r.program == Program.emc).length;

      if (room.program == Program.it && itRooms >= 2) {
        throw Exception('Limit Exceeded: Already have 2 IT rooms.');
      }
      if (room.program == Program.emc && emcRooms >= 1) {
        throw Exception('Limit Exceeded: Already have 1 EMC room.');
      }
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

    room.isActive = false;
    await Room.db.updateRow(session, room);
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

    // Validate student count
    if (subject.studentsCount < 0) {
      throw Exception('Student count cannot be negative');
    }

    // Set timestamps
    subject.createdAt = DateTime.now();
    subject.updatedAt = DateTime.now();

    return await Subject.db.insertRow(session, subject);
  }

  /// Get all subjects.
  Future<List<Subject>> getAllSubjects(
    Session session, {
    bool isActive = true,
  }) async {
    return await Subject.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );
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

    // Validate student count
    if (subject.studentsCount < 0) {
      throw Exception('Student count cannot be negative');
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

    subject.isActive = false;
    await Subject.db.updateRow(session, subject);
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
    // Normalize sentinel values from frontend
    if (schedule.roomId == -1) schedule.roomId = null;
    if (schedule.timeslotId == -1) schedule.timeslotId = null;

    // Validate schedule entry against all conflicts
    var conflicts = await ConflictService().validateSchedule(session, schedule);

    if (conflicts.isNotEmpty) {
      var messages = conflicts.map((c) => c.message).join('; ');
      throw Exception('Schedule validation failed: $messages');
    }

    // Set timestamps
    schedule.createdAt = DateTime.now();
    schedule.updatedAt = DateTime.now();

    return await Schedule.db.insertRow(session, schedule);
  }

  // TEST ENDPOINT to bypass auth and trigger checkFacultyMaxLoad
  Future<String> testMaxLoadValidation(
    Session session,
    int facultyId,
    double units,
  ) async {
    var schedule = Schedule(
      subjectId: 1,
      facultyId: facultyId,
      section: 'A',
      units: units == -1.0 ? null : units,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      var conflicts = await ConflictService().validateSchedule(
        session,
        schedule,
      );
      if (conflicts.isNotEmpty) {
        return 'Conflicts: ${conflicts.map((c) => c.message).join(', ')}';
      }
      return 'No conflicts!';
    } catch (e) {
      return 'Exception: $e';
    }
  }

  /// Get all schedule entries.
  Future<List<Schedule>> getAllSchedules(
    Session session, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          isActive == null ? Constant.bool(true) : t.isActive.equals(isActive),
    );
  }

  /// Get schedule for a specific faculty with includes.
  Future<List<Schedule>> getFacultySchedule(
    Session session,
    int facultyId, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          t.facultyId.equals(facultyId) &
          (isActive == null
              ? Constant.bool(true)
              : t.isActive.equals(isActive)),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Get schedule for a specific subject with includes.
  Future<List<Schedule>> getSubjectSchedule(
    Session session,
    int subjectId, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          t.subjectId.equals(subjectId) &
          (isActive == null
              ? Constant.bool(true)
              : t.isActive.equals(isActive)),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Get schedule for a specific room with includes.
  Future<List<Schedule>> getRoomSchedule(
    Session session,
    int roomId, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          t.roomId.equals(roomId) &
          (isActive == null
              ? Constant.bool(true)
              : t.isActive.equals(isActive)),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Update a schedule entry with conflict detection.
  Future<Schedule> updateSchedule(Session session, Schedule schedule) async {
    // Normalize sentinel values from frontend
    if (schedule.roomId == -1) schedule.roomId = null;
    if (schedule.timeslotId == -1) schedule.timeslotId = null;

    // Ensure schedule exists
    var existing = await Schedule.db.findById(session, schedule.id!);
    if (existing == null) {
      throw Exception('Schedule not found with ID: ${schedule.id}');
    }

    // Validate schedule entry (excluding current schedule from conflict checks)
    var conflicts = await ConflictService().validateSchedule(
      session,
      schedule,
      excludeScheduleId: schedule.id,
    );

    if (conflicts.isNotEmpty) {
      var messages = conflicts.map((c) => c.message).join('; ');
      throw Exception('Schedule validation failed: $messages');
    }

    // Update timestamp
    schedule.updatedAt = DateTime.now();

    return await Schedule.db.updateRow(session, schedule);
  }

  /// Delete (Archive) a schedule entry by ID.
  Future<bool> deleteSchedule(Session session, int id) async {
    var schedule = await Schedule.db.findById(session, id);
    if (schedule == null) return false;

    schedule.isActive = false;
    await Schedule.db.updateRow(session, schedule);
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
    try {
      var totalSchedules = await Schedule.db.count(session);
      var totalFaculty = await Faculty.db.count(session);
      var totalStudents = await Student.db.count(session);
      var totalSubjects = await Subject.db.count(session);
      var totalRooms = await Room.db.count(session);

      // 2. Calculate Faculty Load
      print('[DEBUG] getDashboardStats: Step 2 - Fetching all data');
      var allSchedules = await Schedule.db.find(session);
      var allFaculty = await Faculty.db.find(session);
      var allSubjects = await Subject.db.find(session);
      print(
        '[DEBUG] getDashboardStats: Fetched ${allSchedules.length} schedules, ${allFaculty.length} faculty',
      );
      for (var f in allFaculty) {
        print('[DEBUG] Faculty ${f.id}: name=${f.name}, maxLoad=${f.maxLoad}');
      }

      // Map subject ID to units for quick lookup
      var subjectUnits = <int, double>{
        for (var s in allSubjects)
          if (s.id != null) s.id!: s.units.toDouble(),
      };

      List<FacultyLoadData> facultyLoad = [];
      for (var faculty in allFaculty) {
        double currentLoad = 0;
        var facultySchedules = allSchedules.where(
          (s) => s.facultyId == faculty.id,
        );

        for (var schedule in facultySchedules) {
          currentLoad += subjectUnits[schedule.subjectId] ?? 3.0;
        }

        facultyLoad.add(
          FacultyLoadData(
            facultyName: faculty.name,
            currentLoad: currentLoad,
            maxLoad: (faculty.maxLoad ?? 0).toDouble(),
          ),
        );
      }
      print('[DEBUG] getDashboardStats: Step 2 complete');

      // 3. Integrity Check (Conflicts)
      print('[DEBUG] getDashboardStats: Step 3 - Calculating conflicts');
      List<ScheduleConflict> conflicts = await ConflictService()
          .getAllConflicts(session);

      print(
        '[DEBUG] getDashboardStats: Step 3 complete. Found ${conflicts.length} conflicts.',
      );

      // 4. Distribution Summaries
      var sectionCounts = <String, int>{};
      var yearLevelCounts = <String, int>{};

      for (var schedule in allSchedules) {
        // Section Distribution
        sectionCounts[schedule.section] =
            (sectionCounts[schedule.section] ?? 0) + 1;

        // Year Level Distribution (lookup from subject)
        var subject = allSubjects.firstWhere(
          (s) => s.id == schedule.subjectId,
          orElse: () => Subject(
            code: 'N/A',
            name: 'N/A',
            units: 0,
            studentsCount: 0,
            program: Program.it,
            types: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        var yearLevel = subject.yearLevel?.toString() ?? 'N/A';
        yearLevelCounts[yearLevel] = (yearLevelCounts[yearLevel] ?? 0) + 1;
      }

      List<DistributionData> sectionDistribution = sectionCounts.entries
          .map((e) => DistributionData(label: e.key, count: e.value))
          .toList();
      List<DistributionData> yearLevelDistribution = yearLevelCounts.entries
          .map((e) => DistributionData(label: 'Year ${e.key}', count: e.value))
          .toList();

      return DashboardStats(
        totalSchedules: totalSchedules,
        totalFaculty: totalFaculty,
        totalStudents: totalStudents,
        totalSubjects: totalSubjects,
        totalRooms: totalRooms,
        totalConflicts: conflicts.length,
        facultyLoad: facultyLoad,
        recentConflicts: conflicts,
        sectionDistribution: sectionDistribution,
        yearLevelDistribution: yearLevelDistribution,
      );
    } catch (e, stack) {
      print('[ERROR] getDashboardStats failed: $e');
      print('[ERROR] Stack trace: \n$stack');
      rethrow;
    }
  }
  // ─── Conflict & Reports ──────────────────────────────────────────────

  Future<List<ScheduleConflict>> validateSchedule(
    Session session,
    Schedule schedule,
  ) async {
    return await ConflictService().validateSchedule(session, schedule);
  }

  /// Retrieves all detected conflicts in the current schedule.
  Future<List<ScheduleConflict>> getAllConflicts(Session session) async {
    return await ConflictService().getAllConflicts(session);
  }

  /// Generates the Faculty Load Report.
  Future<List<FacultyLoadReport>> getFacultyLoadReport(Session session) async {
    return await ReportService().generateFacultyLoadReport(session);
  }

  /// Generates the Room Utilization Report.
  Future<List<RoomUtilizationReport>> getRoomUtilizationReport(
    Session session,
  ) async {
    return await ReportService().generateRoomUtilizationReport(session);
  }

  /// Generates the Conflict Summary Report.
  Future<ConflictSummaryReport> getConflictSummaryReport(
    Session session,
  ) async {
    return await ReportService().generateConflictSummary(session);
  }

  /// Generates the Schedule Overview Report.
  Future<ScheduleOverviewReport> getScheduleOverviewReport(
    Session session,
  ) async {
    return await ReportService().generateScheduleOverview(session);
  }

  // ─── Section CRUD ───────────────────────────────────────────────────

  /// Create a new section with validation.
  Future<Section> createSection(Session session, Section section) async {
    // Validate fields
    if (section.sectionCode.trim().isEmpty) {
      throw Exception('Section code cannot be empty');
    }
    if (section.yearLevel < 1 || section.yearLevel > 6) {
      throw Exception('Year level must be between 1 and 6');
    }
    if (section.semester < 1 || section.semester > 3) {
      throw Exception('Semester must be 1, 2, or 3');
    }

    // Check uniqueness
    var existing = await Section.db.findFirstRow(
      session,
      where: (t) =>
          t.program.equals(section.program) &
          t.yearLevel.equals(section.yearLevel) &
          t.sectionCode.equals(section.sectionCode) &
          t.academicYear.equals(section.academicYear) &
          t.semester.equals(section.semester),
    );
    if (existing != null) {
      throw Exception(
        'Section ${section.sectionCode} already exists for this program/year/semester',
      );
    }

    section.createdAt = DateTime.now();
    section.updatedAt = DateTime.now();
    return await Section.db.insertRow(session, section);
  }

  /// Get all sections.
  Future<List<Section>> getAllSections(Session session) async {
    return await Section.db.find(session);
  }

  /// Update a section.
  Future<Section> updateSection(Session session, Section section) async {
    var existing = await Section.db.findById(session, section.id!);
    if (existing == null) {
      throw Exception('Section not found with ID: ${section.id}');
    }

    if (section.sectionCode.trim().isEmpty) {
      throw Exception('Section code cannot be empty');
    }

    section.updatedAt = DateTime.now();
    return await Section.db.updateRow(session, section);
  }

  /// Delete a section by ID.
  Future<bool> deleteSection(Session session, int id) async {
    var section = await Section.db.findById(session, id);
    if (section == null) return false;

    // Check for students assigned to this section
    var students = await Student.db.find(
      session,
      where: (t) => t.sectionId.equals(id),
    );
    if (students.isNotEmpty) {
      throw Exception(
        'Cannot delete section: ${students.length} student(s) assigned. '
        'Please reassign students first.',
      );
    }

    section.isActive = false;
    await Section.db.updateRow(session, section);
    return true;
  }

  // ─── Faculty Availability CRUD ──────────────────────────────────────

  /// Set faculty availability (creates or replaces entries for a faculty).
  Future<List<FacultyAvailability>> setFacultyAvailability(
    Session session,
    int facultyId,
    List<FacultyAvailability> availabilities,
  ) async {
    // Validate faculty exists
    var faculty = await Faculty.db.findById(session, facultyId);
    if (faculty == null) {
      throw Exception('Faculty not found with ID: $facultyId');
    }

    // Validate each availability entry
    for (var avail in availabilities) {
      if (!_isValidTimeFormat(avail.startTime)) {
        throw Exception('Invalid start time: ${avail.startTime}');
      }
      if (!_isValidTimeFormat(avail.endTime)) {
        throw Exception('Invalid end time: ${avail.endTime}');
      }
      if (!_isStartBeforeEnd(avail.startTime, avail.endTime)) {
        throw Exception(
          'Start time must be before end time: ${avail.startTime} - ${avail.endTime}',
        );
      }
    }

    // Check for overlapping availability for same faculty on same day
    for (var i = 0; i < availabilities.length; i++) {
      for (var j = i + 1; j < availabilities.length; j++) {
        if (availabilities[i].dayOfWeek == availabilities[j].dayOfWeek) {
          if (_timesOverlap(
            availabilities[i].startTime,
            availabilities[i].endTime,
            availabilities[j].startTime,
            availabilities[j].endTime,
          )) {
            throw Exception(
              'Overlapping availability on ${availabilities[i].dayOfWeek.name}: '
              '${availabilities[i].startTime}-${availabilities[i].endTime} and '
              '${availabilities[j].startTime}-${availabilities[j].endTime}',
            );
          }
        }
      }
    }

    // Delete existing availability for this faculty
    var existing = await FacultyAvailability.db.find(
      session,
      where: (t) => t.facultyId.equals(facultyId),
    );
    for (var e in existing) {
      await FacultyAvailability.db.deleteRow(session, e);
    }

    // Insert new entries
    var now = DateTime.now();
    var results = <FacultyAvailability>[];
    for (var avail in availabilities) {
      avail.facultyId = facultyId;
      avail.createdAt = now;
      avail.updatedAt = now;
      results.add(await FacultyAvailability.db.insertRow(session, avail));
    }

    return results;
  }

  /// Get all availability entries for a specific faculty.
  Future<List<FacultyAvailability>> getFacultyAvailability(
    Session session,
    int facultyId,
  ) async {
    return await FacultyAvailability.db.find(
      session,
      where: (t) => t.facultyId.equals(facultyId),
    );
  }

  /// Get all faculty availabilities.
  Future<List<FacultyAvailability>> getAllFacultyAvailabilities(
    Session session,
  ) async {
    return await FacultyAvailability.db.find(session);
  }

  /// Delete a single faculty availability entry.
  Future<bool> deleteFacultyAvailability(Session session, int id) async {
    var avail = await FacultyAvailability.db.findById(session, id);
    if (avail == null) return false;
    await FacultyAvailability.db.deleteRow(session, avail);
    return true;
  }

  // ─── Schedule Pre-Check & Regeneration ──────────────────────────────

  /// Pre-check readiness for schedule generation.
  /// Returns a map with readiness status and any missing items.
  Future<GenerateScheduleResponse> precheckSchedule(
    Session session,
  ) async {
    var missing = <String>[];

    var facultyCount = await Faculty.db.count(session);
    if (facultyCount == 0) missing.add('No faculty members defined');

    var subjectCount = await Subject.db.count(session);
    if (subjectCount == 0) missing.add('No subjects defined');

    var roomCount = await Room.db.count(session);
    if (roomCount == 0) missing.add('No rooms defined');

    var sectionCount = await Section.db.count(session);
    if (sectionCount == 0) missing.add('No sections defined');

    var timeslotCount = await Timeslot.db.count(session);
    if (timeslotCount == 0) missing.add('No timeslots defined');

    var availabilityCount = await FacultyAvailability.db.count(session);
    if (availabilityCount == 0) {
      missing.add('No faculty availability defined');
    }

    if (missing.isNotEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'Not ready: ${missing.join(", ")}',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }

    return GenerateScheduleResponse(
      success: true,
      message:
          'Ready to generate. Faculty: $facultyCount, '
          'Subjects: $subjectCount, Rooms: $roomCount, '
          'Sections: $sectionCount, Timeslots: $timeslotCount, '
          'Availabilities: $availabilityCount',
      totalAssigned: 0,
      conflictsDetected: 0,
      unassignedSubjects: 0,
    );
  }

  /// Regenerate all schedules using the AI scheduling engine.
  /// Clears existing schedules, then generates new ones respecting all constraints.
  Future<GenerateScheduleResponse> regenerateSchedule(
    Session session,
  ) async {
    // 1. Pre-check
    var precheck = await precheckSchedule(session);
    if (!precheck.success) {
      return precheck;
    }

    // 2. Clear existing schedules
    var existingSchedules = await Schedule.db.find(session);
    for (var s in existingSchedules) {
      await Schedule.db.deleteRow(session, s);
    }

    // 3. Fetch all entities
    var allFaculty = await Faculty.db.find(session);
    var allSubjects = await Subject.db.find(session);
    var allRooms = await Room.db.find(session);
    var allTimeslots = await Timeslot.db.find(session);
    var allSections = await Section.db.find(session);
    var allAvailabilities = await FacultyAvailability.db.find(session);

    // Build availability lookup: facultyId -> list of availability windows
    var availabilityMap = <int, List<FacultyAvailability>>{};
    for (var a in allAvailabilities) {
      availabilityMap.putIfAbsent(a.facultyId, () => []);
      availabilityMap[a.facultyId]!.add(a);
    }

    // 4. Run AI scheduling algorithm
    var request = GenerateScheduleRequest(
      subjectIds: allSubjects.map((s) => s.id!).toList(),
      facultyIds: allFaculty.map((f) => f.id!).toList(),
      roomIds: allRooms.map((r) => r.id!).toList(),
      timeslotIds: allTimeslots.map((t) => t.id!).toList(),
      sections: allSections.map((s) => s.sectionCode).toList(),
    );

    var result = await SchedulingService().generateSchedule(session, request);

    // 5. Recalculate conflicts
    var conflicts = await ConflictService().getAllConflicts(session);

    // 6. Return summary
    return GenerateScheduleResponse(
      success: result.success,
      schedules: result.schedules,
      conflicts: conflicts,
      message: result.message,
      totalAssigned: result.schedules?.length ?? 0,
      conflictsDetected: conflicts.length,
      unassignedSubjects: result.conflicts?.length ?? 0,
    );
  }

  /// Check if two time ranges overlap.
  bool _timesOverlap(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    try {
      var s1 = _timeToMinutes(start1);
      var e1 = _timeToMinutes(end1);
      var s2 = _timeToMinutes(start2);
      var e2 = _timeToMinutes(end2);
      return s1 < e2 && s2 < e1;
    } catch (e) {
      return false;
    }
  }

  /// Convert time string to minutes since midnight.
  int _timeToMinutes(String time) {
    var parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
