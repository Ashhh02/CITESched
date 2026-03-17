import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

class NLPService {
  final ConflictService _conflictService = ConflictService();

  // Restricted keywords that should always be rejected
  static const List<String> forbiddenKeywords = [
    'drop',
    'delete',
    'password',
    'sql',
    'schema',
    'database',
    'truncate',
    'alter',
  ];

  Future<NLPResponse> processQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
  ) async {
    // Sanitize and validate input
    if (query.isEmpty || query.length > 500) {
      return _unsupportedResponse();
    }

    final lowerQuery = query.toLowerCase();
    final normalizedQuery = _normalizeQuery(lowerQuery);
    final requestedDays = _extractDaysOfWeek(normalizedQuery);
    final requestedDay = requestedDays.length == 1 ? requestedDays.first : null;
    final relativeDays = _extractRelativeDays(normalizedQuery);

    // Check for forbidden keywords - NEVER execute
    if (_containsForbiddenKeywords(lowerQuery)) {
      return _unsupportedResponse();
    }

    // 1. My Schedule Queries (All authenticated users)
    if (_hasMyScheduleIntent(normalizedQuery)) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to view your schedule.",
          intent: NLPIntent.unknown,
        );
      }
      return await _handleMyScheduleQuery(
        session,
        userId,
        scopes,
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null),
      );
    }

    // 2. Conflict Queries (All authenticated users)
    if (_hasConflictIntent(normalizedQuery)) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to check for conflicts.",
          intent: NLPIntent.unknown,
        );
      }
      return await _handleConflictQuery(session, userId, scopes);
    }

    // 3. Faculty Overload Queries (All authenticated users)
    if (_hasOverloadIntent(normalizedQuery)) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to check faculty load information.",
          intent: NLPIntent.unknown,
        );
      }
      return await _handleOverloadQuery(session, userId, scopes, lowerQuery);
    }

    // 3.5 Room type questions (lab vs lecture)
    final roomTypeResponse = await _tryRoomTypeQuestion(session, normalizedQuery);
    if (roomTypeResponse != null) {
      return roomTypeResponse;
    }

    // 3.6 Room type schedule queries (lecture/lab on a day)
    final roomTypeScheduleResponse = await _tryRoomTypeScheduleQuery(
      session,
      normalizedQuery,
      requestedDay,
      scopes,
    );
    if (roomTypeScheduleResponse != null) {
      return roomTypeScheduleResponse;
    }

    // 4. Room Availability Queries
    if (_hasRoomIntent(normalizedQuery)) {
      final timeQueryResponse = await _tryRoomTimeQuery(
        session,
        normalizedQuery,
        relativeDays,
        scopes,
      );
      if (timeQueryResponse != null) return timeQueryResponse;

      return await _handleRoomQuery(session, normalizedQuery);
    }

    // 5. Section/Schedule Queries
    final timeRange = _extractTimeRange(normalizedQuery);
    if (_hasScheduleIntent(normalizedQuery) ||
        _containsSectionPattern(normalizedQuery) ||
        _hasScheduleQuestion(normalizedQuery, requestedDay, relativeDays, timeRange)) {
      final timeQueryResponse = await _tryTimeBasedScheduleQuery(
        session,
        normalizedQuery,
        userId,
        scopes,
        requestedDay,
        relativeDays,
      );
      if (timeQueryResponse != null) return timeQueryResponse;

      final filteredResponse = await _tryFilteredScheduleQuery(
        session,
        normalizedQuery,
        userId,
        scopes,
        requestedDay,
        relativeDays,
        timeRange,
      );
      if (filteredResponse != null) return filteredResponse;

      return await _handleScheduleQuery(
        session,
        normalizedQuery,
        userId,
        scopes,
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null),
        requestedDays.isNotEmpty ? requestedDays : relativeDays,
      );
    }

    if (_hasSystemIntent(normalizedQuery)) {
      return NLPResponse(
        text:
            "That action needs the admin scheduling tools. Use the Timetable or Conflict modules to generate, optimize, or resolve schedules.",
        intent: NLPIntent.unknown,
      );
    }

    if (_containsKeywordFuzzy(normalizedQuery, ['free', 'available']) &&
        _containsKeywordFuzzy(normalizedQuery, ['slot', 'slots', 'time'])) {
      return NLPResponse(
        text:
            "Please specify whose availability to check (e.g., 'Show free time slots for Prof Ryan') or include a day/time.",
        intent: NLPIntent.schedule,
      );
    }

    if (_containsKeywordFuzzy(normalizedQuery, ['free']) &&
        _containsKeywordFuzzy(normalizedQuery, ['room'])) {
      return NLPResponse(
        text:
            "Please specify a day and time range to find a free room (e.g., 'Find free room on Monday between 1 PM and 3 PM').",
        intent: NLPIntent.roomStatus,
      );
    }

    return NLPResponse(
      text:
          "I couldn't match that request. Try asking about schedules, rooms, conflicts, or faculty load. Example: 'My schedule on Monday' or 'Is IT LAB available at 2 PM?'",
      intent: NLPIntent.unknown,
    );
  }

  Future<NLPResponse?> _tryRoomTypeQuestion(
    Session session,
    String query,
  ) async {
    if (!_isRoomTypeQuestion(query)) return null;

    final rooms = await Room.db.find(session);
    final matchedRoom = _matchRoomByName(query, rooms);
    if (matchedRoom == null) {
      return NLPResponse(
        text:
            "Which room are you asking about? Try: 'Is IT Lab a laboratory or lecture room?'",
        intent: NLPIntent.roomStatus,
      );
    }

    final typeLabel =
        matchedRoom.type == RoomType.laboratory ? 'laboratory' : 'lecture';
    return NLPResponse(
      text: "Room ${matchedRoom.name} is a $typeLabel room.",
      intent: NLPIntent.roomStatus,
      dataJson: jsonEncode({
        'roomId': matchedRoom.id,
        'roomName': matchedRoom.name,
        'type': typeLabel,
      }),
    );
  }

  bool _isRoomTypeQuestion(String query) {
    final hasLab = _containsKeyword(query, ['lab', 'laboratory']);
    final hasLecture = _containsKeyword(query, ['lecture']);
    return hasLab && hasLecture;
  }

  Room? _matchRoomByName(String query, List<Room> rooms) {
    final cleanedQuery = _normalizeQuery(query.toLowerCase());
    for (var r in rooms) {
      final name = _normalizeQuery(r.name.toLowerCase());
      if (cleanedQuery.contains(name)) return r;

      final tokens = name.split(RegExp(r'\s+')).where((t) => t.length >= 2);
      for (var token in tokens) {
        final tokenRegex = RegExp(r'\b' + RegExp.escape(token) + r'\b');
        if (tokenRegex.hasMatch(cleanedQuery)) {
          return r;
        }
      }
    }
    return null;
  }

  Future<NLPResponse?> _tryRoomTypeScheduleQuery(
    Session session,
    String query,
    DayOfWeek? requestedDay,
    List<String> scopes,
  ) async {
    final roomType = _extractRoomType(query);
    if (roomType == null) return null;

    final hasScheduleIntent = _hasScheduleIntent(query);

    if (!hasScheduleIntent && requestedDay == null) {
      return null;
    }

    if (requestedDay == null) {
      return NLPResponse(
        text:
            "Which day should I check for ${roomType == RoomType.laboratory ? 'laboratory' : 'lecture'} rooms?",
        intent: NLPIntent.schedule,
      );
    }

    final isAdmin = scopes.contains('admin');
    if (!isAdmin) {
      return NLPResponse(
        text:
            "Please specify whose schedule to check (e.g., 'my schedule on ${_dayLabel(requestedDay)}' or 'schedule for IT 3A on ${_dayLabel(requestedDay)}').",
        intent: NLPIntent.schedule,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );

    final filtered = schedules.where((s) {
      final ts = s.timeslot;
      final room = s.room;
      if (ts == null || room == null) return false;
      if (ts.day != requestedDay) return false;
      return room.type == roomType;
    }).toList();

    if (filtered.isEmpty) {
      return NLPResponse(
        text:
            "I couldn't find any ${roomType == RoomType.laboratory ? 'laboratory' : 'lecture'} classes on ${_dayLabel(requestedDay)}.",
        intent: NLPIntent.schedule,
      );
    }

    return NLPResponse(
      text:
          "Found ${filtered.length} ${roomType == RoomType.laboratory ? 'laboratory' : 'lecture'} class(es) on ${_dayLabel(requestedDay)}.",
      intent: NLPIntent.schedule,
      schedules: filtered,
    );
  }

  RoomType? _extractRoomType(String query) {
    final hasLecture = _containsKeyword(query, ['lecture']);
    final hasLab = _containsKeyword(query, ['lab', 'laboratory']);

    if (hasLecture && hasLab) return null;
    if (hasLecture) return RoomType.lecture;
    if (hasLab) return RoomType.laboratory;
    return null;
  }

  /// Checks if query contains forbidden keywords
  bool _containsForbiddenKeywords(String query) {
    return forbiddenKeywords.any((keyword) => query.contains(keyword));
  }

  /// Returns standard unsupported response
  NLPResponse _unsupportedResponse() {
    return NLPResponse(
      text: "This query is not supported by the system.",
      intent: NLPIntent.unknown,
    );
  }

  bool _containsSectionPattern(String query) {
    // Regex for common section patterns (e.g., IT 1A, IT-2B, 3-C, etc.)
    final sectionRegex = RegExp(r'\b([a-zA-Z]{1,4})?\s?\d[a-zA-Z]\b');
    return sectionRegex.hasMatch(query);
  }

  bool _hasScheduleIntent(String query) {
    return _containsKeywordFuzzy(
      query,
      [
        'schedule',
        'scheduled',
        'sched',
        'timetable',
        'class',
        'classes',
        'subject',
        'subjects',
      ],
    );
  }

  bool _hasMyScheduleIntent(String query) {
    return _containsKeywordFuzzy(query, ['my', 'mine']) &&
        _hasScheduleIntent(query);
  }

  bool _hasRoomIntent(String query) {
    return _containsKeywordFuzzy(
      query,
      ['room', 'rooms', 'lab', 'laboratory', 'lecture', 'available', 'free'],
    );
  }

  bool _hasConflictIntent(String query) {
    return _containsKeywordFuzzy(query, ['conflict', 'issue', 'overlap']);
  }

  bool _hasOverloadIntent(String query) {
    return _containsKeywordFuzzy(query, ['overload', 'load', 'units']) &&
        _containsKeywordFuzzy(query, ['faculty', 'teacher', 'instructor']);
  }

  bool _hasSystemIntent(String query) {
    return _containsKeywordFuzzy(
      query,
      [
        'generate',
        'regenerate',
        'optimize',
        'timetable',
        'schedule',
        'conflict',
        'resolve',
        'suggest',
      ],
    );
  }

  bool _hasScheduleQuestion(
    String query,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
    _TimeRange? timeRange,
  ) {
    final hasDay = requestedDay != null || relativeDays.isNotEmpty;
    final hasTime = timeRange != null || _containsKeywordFuzzy(query, ['now']);
    if (!hasDay && !hasTime) return false;
    return _containsKeywordFuzzy(query, ['who', 'what', 'which']);
  }

  /// Handles "My Schedule" query for current authenticated user
  Future<NLPResponse> _handleMyScheduleQuery(
    Session session,
    String userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
  ) async {
    try {
      final isFaculty = scopes.contains('faculty');
      final isStudent = scopes.contains('student');

      if (isFaculty) {
        // Get faculty schedules
        final faculty = await Faculty.db.findFirstRow(
          session,
          where: (t) => t.facultyId.equals(userId),
        );

        if (faculty == null) {
          return NLPResponse(
            text: "Could not find your faculty profile.",
            intent: NLPIntent.schedule,
          );
        }

        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(faculty.id!),
          include: Schedule.include(
            subject: Subject.include(),
            room: Room.include(),
            timeslot: Timeslot.include(),
          ),
        );

        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "You have",
            requestedDay,
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'my',
            'contextValue': 'faculty',
          }),
        );
      } else if (isStudent) {
        // Get student section schedules
        // Note: Implement based on your student section mapping

        return NLPResponse(
          text: "Retrieving your class schedule...",
          intent: NLPIntent.schedule,
          dataJson: jsonEncode({
            'contextType': 'my',
            'contextValue': 'student',
          }),
        );
      }

      return NLPResponse(
        text: "Could not determine your user role.",
        intent: NLPIntent.unknown,
      );
    } catch (e) {
      print('Error in _handleMyScheduleQuery: $e');
      return NLPResponse(
        text: "An error occurred while retrieving your schedule.",
        intent: NLPIntent.unknown,
      );
    }
  }

  Future<NLPResponse> _handleConflictQuery(
    Session session,
    String userId,
    List<String> scopes,
  ) async {
    try {
      if (scopes.contains('admin')) {
        return await _handleAdminConflicts(session);
      }
      if (scopes.contains('faculty')) {
        return await _handleFacultyConflicts(session, userId);
      }
      if (scopes.contains('student')) {
        return await _handleStudentConflicts(session, userId);
      }

      return NLPResponse(
        text: "Could not determine your role to check conflicts.",
        intent: NLPIntent.unknown,
      );
    } catch (e) {
      print('Error in _handleConflictQuery: $e');
      return NLPResponse(
        text: "An error occurred while checking conflicts.",
        intent: NLPIntent.conflict,
      );
    }
  }

  Future<NLPResponse> _handleAdminConflicts(Session session) async {
    final conflicts = await _conflictService.getAllConflicts(session);
    if (conflicts.isEmpty) {
      return NLPResponse(
        text:
            "Great news! There are currently no conflicts detected in the system.",
        intent: NLPIntent.conflict,
      );
    }
    final roomConflicts =
        conflicts.where((c) => c.type.toLowerCase().contains('room')).length;
    final facultyConflicts =
        conflicts.where((c) => c.type.toLowerCase().contains('faculty')).length;

    var summary = "I found ${conflicts.length} conflict(s): ";
    if (roomConflicts > 0) summary += "$roomConflicts room conflict(s). ";
    if (facultyConflicts > 0) {
      summary += "$facultyConflicts faculty conflict(s). ";
    }

    return NLPResponse(
      text:
          "$summary You can view details in the Conflict Module or use Timetable to resolve.",
      intent: NLPIntent.conflict,
      dataJson:
          '{"count": ${conflicts.length}, "room": $roomConflicts, "faculty": $facultyConflicts}',
    );
  }

  Future<NLPResponse> _handleFacultyConflicts(
    Session session,
    String userId,
  ) async {
    final faculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.facultyId.equals(userId),
    );

    if (faculty == null) {
      return NLPResponse(
        text: "Could not find your faculty profile.",
        intent: NLPIntent.conflict,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(faculty.id!),
    );

    int conflictCount = 0;
    for (var schedule in schedules) {
      final timeslotConflict = await _conflictService.checkFacultyAvailability(
        session,
        facultyId: faculty.id!,
        timeslotId: schedule.timeslotId,
        excludeScheduleId: schedule.id,
      );
      if (timeslotConflict != null) conflictCount++;
    }

    if (conflictCount == 0) {
      return NLPResponse(
        text:
            "Good news! You have no conflicts in your schedule. All your classes are scheduled properly.",
        intent: NLPIntent.conflict,
      );
    }

    return NLPResponse(
      text:
          "⚠️ You have $conflictCount conflict(s) in your schedule. Please check the Timetable to resolve them.",
      intent: NLPIntent.conflict,
      dataJson: '{"count": $conflictCount}',
    );
  }

  Future<NLPResponse> _handleStudentConflicts(
    Session session,
    String userId,
  ) async {
    final student = await Student.db.findFirstRow(
      session,
      where: (t) => t.studentNumber.equals(userId),
    );

    if (student == null || student.section == null) {
      return NLPResponse(
        text: "Could not find your section information.",
        intent: NLPIntent.conflict,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.section.equals(student.section!),
    );

    int conflictCount = 0;
    for (var schedule in schedules) {
      final sectionConflict = await _conflictService.checkSectionAvailability(
        session,
        section: student.section!,
        timeslotId: schedule.timeslotId,
        excludeScheduleId: schedule.id,
      );
      if (sectionConflict != null) conflictCount++;
    }

    if (conflictCount == 0) {
      return NLPResponse(
        text:
            "Good news! Your section has no conflicts. All classes are properly scheduled.",
        intent: NLPIntent.conflict,
      );
    }

    return NLPResponse(
      text:
          "⚠️ Your section has $conflictCount conflict(s). Please contact your administrator.",
      intent: NLPIntent.conflict,
      dataJson: '{"count": $conflictCount}',
    );
  }

  /// Handles faculty overload detection
  Future<NLPResponse> _handleOverloadQuery(
    Session session,
    String userId,
    List<String> scopes,
    String query,
  ) async {
    try {
      final isAdmin = scopes.contains('admin');
      final isFaculty = scopes.contains('faculty');
      final facultyList = await Faculty.db.find(session);
      Faculty? foundFaculty;

      // Entity extraction: find faculty by name
      for (var f in facultyList) {
        if (query.contains(f.name.toLowerCase())) {
          foundFaculty = f;
          break;
        }
      }

      if (foundFaculty != null) {
        // If a specific faculty is mentioned and user is not admin, check if it's themselves
        if (!isAdmin && isFaculty) {
          final currentFaculty = await Faculty.db.findFirstRow(
            session,
            where: (t) => t.facultyId.equals(userId),
          );
          if (currentFaculty == null || currentFaculty.id != foundFaculty.id) {
            return NLPResponse(
              text:
                  "You can only view your own load information. Contact administrators to see other faculty loads.",
              intent: NLPIntent.facultyLoad,
            );
          }
        }

        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(foundFaculty!.id!),
          include: Schedule.include(
            subject: Subject.include(),
            timeslot: Timeslot.include(),
          ),
        );

        double totalUnits = 0;
        double totalHours = 0;

        for (var s in schedules) {
          totalUnits += s.units ?? 0;
          if (s.timeslot != null) {
            try {
              var start = DateTime.parse('2000-01-01 ${s.timeslot!.startTime}');
              var end = DateTime.parse('2000-01-01 ${s.timeslot!.endTime}');
              totalHours += end.difference(start).inMinutes / 60.0;
            } catch (_) {
              totalHours += 3.0;
            }
          }
        }

        // Check if overloaded
        final isOverloaded = totalUnits > (foundFaculty.maxLoad ?? 0);
        final intent = isOverloaded
            ? NLPIntent.facultyLoad
            : NLPIntent.schedule;

        return NLPResponse(
          text: isOverloaded
              ? "⚠️ ${foundFaculty.name} is OVERLOADED! Teaching ${schedules.length} classes with ${totalUnits.toStringAsFixed(1)} units (Limit: ${foundFaculty.maxLoad}). Total hours: ${totalHours.toStringAsFixed(1)}/week."
              : "${foundFaculty.name} is teaching ${schedules.length} classes with ${totalUnits.toStringAsFixed(1)} units (Limit: ${foundFaculty.maxLoad}). Total hours: ${totalHours.toStringAsFixed(1)}/week. Load is acceptable.",
          intent: intent,
          schedules: schedules,
          dataJson:
              '{"facultyId": ${foundFaculty.id}, "totalUnits": $totalUnits, "maxLoad": ${foundFaculty.maxLoad}, "isOverloaded": $isOverloaded}',
        );
      }

      // Non-admin users can only see their own load info
      if (!isAdmin && isFaculty) {
        final faculty = await Faculty.db.findFirstRow(
          session,
          where: (t) => t.facultyId.equals(userId),
        );

        if (faculty == null) {
          return NLPResponse(
            text:
                "General load information is only available to administrators.",
            intent: NLPIntent.facultyLoad,
          );
        }

        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(faculty.id!),
          include: Schedule.include(
            subject: Subject.include(),
            timeslot: Timeslot.include(),
          ),
        );

        double totalUnits = 0;
        for (var s in schedules) {
          totalUnits += s.units ?? 0;
        }

        final isOverloaded = totalUnits > (faculty.maxLoad ?? 0);
        return NLPResponse(
          text: isOverloaded
              ? "⚠️ You are currently overloaded with ${totalUnits.toStringAsFixed(1)} units (Limit: ${faculty.maxLoad} units). Consider discussing with administration."
              : "Your current load is ${totalUnits.toStringAsFixed(1)} units (Limit: ${faculty.maxLoad}). Load is within acceptable range.",
          intent: isOverloaded ? NLPIntent.facultyLoad : NLPIntent.schedule,
          dataJson:
              '{"totalUnits": $totalUnits, "maxLoad": ${faculty.maxLoad}, "isOverloaded": $isOverloaded}',
        );
      }

      // If no specific faculty mentioned and user is admin, show all overloaded faculty
      if (!isAdmin) {
        return NLPResponse(
          text:
              "General faculty load information is only available to administrators.",
          intent: NLPIntent.facultyLoad,
        );
      }

      final allSchedules = await Schedule.db.find(
        session,
        include: Schedule.include(
          faculty: Faculty.include(),
          subject: Subject.include(),
          timeslot: Timeslot.include(),
        ),
      );

      final facultyLoad = <int, Map<String, dynamic>>{};
      for (var s in allSchedules) {
        final facultyId = s.facultyId;
        if (!facultyLoad.containsKey(facultyId)) {
          facultyLoad[facultyId] = {
            'units': 0.0,
            'hours': 0.0,
            'faculty': s.faculty,
            'count': 0,
          };
        }
        facultyLoad[facultyId]!['units'] += s.units ?? 0;
        facultyLoad[facultyId]!['count']++;

        if (s.timeslot != null) {
          try {
            var start = DateTime.parse('2000-01-01 ${s.timeslot!.startTime}');
            var end = DateTime.parse('2000-01-01 ${s.timeslot!.endTime}');
            facultyLoad[facultyId]!['hours'] +=
                end.difference(start).inMinutes / 60.0;
          } catch (_) {
            facultyLoad[facultyId]!['hours'] += 3.0;
          }
        }
      }

      final overloadedFaculty = facultyLoad.entries
          .where(
            (e) =>
                ((e.value['units'] as double?) ?? 0) >
                (e.value['faculty'].maxLoad ?? 0),
          )
          .toList();

      if (overloadedFaculty.isEmpty) {
        return NLPResponse(
          text: "Good news! No faculty members are currently overloaded.",
          intent: NLPIntent.schedule,
        );
      }

      var summary =
          "I found ${overloadedFaculty.length} overloaded faculty member(s):\n";
      for (var entry in overloadedFaculty) {
        final faculty = entry.value['faculty'] as Faculty;
        final units = entry.value['units'] as double;
        summary +=
            "\n• ${faculty.name}: ${units.toStringAsFixed(1)} units (Limit: ${faculty.maxLoad})";
      }

      return NLPResponse(
        text: summary,
        intent: NLPIntent.facultyLoad,
        dataJson: '{"overloadedCount": ${overloadedFaculty.length}}',
      );
    } catch (e) {
      print('Error in _handleOverloadQuery: $e');
      return NLPResponse(
        text: "An error occurred while checking faculty load.",
        intent: NLPIntent.facultyLoad,
      );
    }
  }

  Future<NLPResponse> _handleRoomQuery(Session session, String query) async {
    try {
      final rooms = await Room.db.find(session);
      Room? foundRoom;

      for (var r in rooms) {
        if (query.contains(r.name.toLowerCase())) {
          foundRoom = r;
          break;
        }
      }

      if (foundRoom != null) {
        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.roomId.equals(foundRoom!.id!),
          include: Schedule.include(
            subject: Subject.include(),
            timeslot: Timeslot.include(),
          ),
        );

        return NLPResponse(
          text:
              "Room ${foundRoom.name} (${foundRoom.type.name}) currently has ${schedules.length} assigned sessions. Capacity: ${foundRoom.capacity} students.",
          intent: NLPIntent.roomStatus,
          schedules: schedules,
          dataJson: jsonEncode({
            'id': foundRoom.id,
            'capacity': foundRoom.capacity,
            'roomName': foundRoom.name,
            'type': foundRoom.type.name,
          }),
        );
      }

      return NLPResponse(
        text:
            "I can check room status. Try asking 'Is [Room Name] available?' or 'How busy is [Room Name]?'",
        intent: NLPIntent.roomStatus,
      );
    } catch (e) {
      print('Error in _handleRoomQuery: $e');
      return NLPResponse(
        text: "An error occurred while checking room status.",
        intent: NLPIntent.roomStatus,
      );
    }
  }

  Future<NLPResponse> _handleScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> requestedDays,
  ) async {
    try {
      final isAdmin = scopes.contains('admin');

      // Multi-day schedule queries (e.g., "schedule on Monday, Tuesday")
      final multiDayResponse = await _tryMultiDayScheduleQuery(
        session,
        query,
        userId,
        scopes,
        requestedDays,
      );
      if (multiDayResponse != null) return multiDayResponse;

      // First: check if the query references a faculty name
      final facultySchedules =
          await _tryFacultyScheduleQuery(
            session,
            query,
            userId,
            scopes,
            requestedDay,
          );
      if (facultySchedules != null) return facultySchedules;

      // Extract section (e.g., IT 3A)
      final sectionMatch = RegExp(
        r'\b([a-zA-Z]{1,4})?\s?(\d[a-zA-Z])\b',
      ).firstMatch(query.toUpperCase());

      if (sectionMatch != null) {
        final section = sectionMatch.group(0)!;
        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.section.equals(section),
          include: Schedule.include(
            subject: Subject.include(),
            faculty: Faculty.include(),
            room: Room.include(),
            timeslot: Timeslot.include(),
          ),
        );

        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        if (filtered.isEmpty) {
          return NLPResponse(
            text: _buildScheduleCountMessage(
              0,
              "I couldn't find any classes scheduled for section $section",
              requestedDay,
            ),
            intent: NLPIntent.schedule,
          );
        }

        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "Found",
            requestedDay,
            suffix: "for section $section",
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'section',
            'contextValue': section,
          }),
        );
      }

      if (isAdmin && query.contains('timetable')) {
        final schedules = await Schedule.db.find(
          session,
          include: Schedule.include(
            subject: Subject.include(),
            faculty: Faculty.include(),
            room: Room.include(),
            timeslot: Timeslot.include(),
          ),
        );
        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        if (filtered.isEmpty) {
          return NLPResponse(
            text: _buildScheduleCountMessage(
              0,
              "I couldn't find any classes scheduled",
              requestedDay,
              suffix: 'in the timetable',
            ),
            intent: NLPIntent.schedule,
          );
        }

        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "Found",
            requestedDay,
            suffix: 'in the timetable',
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'timetable',
            'contextValue': 'all',
          }),
        );
      }

      if (requestedDay != null) {
        return NLPResponse(
          text:
              "Which schedule on ${_dayLabel(requestedDay)}? Try 'my schedule on ${_dayLabel(requestedDay)}', 'Show schedule for IT 3A on ${_dayLabel(requestedDay)}', or 'Schedule of Prof Juan on ${_dayLabel(requestedDay)}'.",
          intent: NLPIntent.schedule,
        );
      }

      return NLPResponse(
        text:
            "I can find schedules for specific sections. Try asking 'Show schedule for IT 3A'.",
        intent: NLPIntent.schedule,
      );
    } catch (e) {
      print('Error in _handleScheduleQuery: $e');
      return NLPResponse(
        text: "An error occurred while retrieving the schedule.",
        intent: NLPIntent.schedule,
      );
    }
  }

  Future<NLPResponse?> _tryMultiDayScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    List<DayOfWeek> requestedDays,
  ) async {
    if (requestedDays.length < 2) return null;

    // Require schedule intent words to avoid false positives.
    if (!query.contains('schedule') &&
        !query.contains('timetable') &&
        !query.contains('class') &&
        !query.contains('classes')) {
      return null;
    }

    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');
    final isStudent = scopes.contains('student');

    if (!isAdmin) {
      final dayList = requestedDays.map(_dayLabel).join(', ');
      final roleHint = isFaculty || isStudent
          ? 'Try "my schedule on $dayList" or specify a section or faculty.'
          : 'Please log in and specify whose schedule you want.';
      return NLPResponse(
        text: "Which schedule on $dayList? $roleHint",
        intent: NLPIntent.schedule,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      include: Schedule.include(
        timeslot: Timeslot.include(),
      ),
    );

    final counts = <DayOfWeek, int>{};
    for (var day in requestedDays) {
      counts[day] = 0;
    }

    for (var s in schedules) {
      final day = s.timeslot?.day;
      if (day != null && counts.containsKey(day)) {
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }

    final summaryParts = requestedDays
        .map((d) => "${_dayLabel(d)}: ${counts[d] ?? 0}")
        .toList();

    return NLPResponse(
      text: "Schedules by day: ${summaryParts.join(', ')}.",
      intent: NLPIntent.schedule,
      dataJson: _buildDayCountJson(counts),
    );
  }

  Future<NLPResponse?> _tryFacultyScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
  ) async {
    if (!query.contains('schedule') &&
        !query.contains('timetable') &&
        !query.contains('class') &&
        !query.contains('classes')) {
      return null;
    }

    final facultyList = await Faculty.db.find(session);
    final matchedFaculty = _matchFacultyByName(query, facultyList);
    if (matchedFaculty == null) return null;

    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');

    if (!isAdmin && isFaculty) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to view faculty schedules.",
          intent: NLPIntent.unknown,
        );
      }

      final currentFaculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(userId),
      );
      if (currentFaculty == null || currentFaculty.id != matchedFaculty.id) {
        return NLPResponse(
          text:
              "You can only view your own schedule. Contact administrators to see other faculty schedules.",
          intent: NLPIntent.schedule,
        );
      }
    } else if (!isAdmin && !isFaculty) {
      return NLPResponse(
        text:
            "Faculty schedules are only available to faculty members and administrators.",
        intent: NLPIntent.schedule,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(matchedFaculty.id!),
      include: Schedule.include(
        subject: Subject.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );

    final filtered = _filterSchedulesByDay(schedules, requestedDay);
    if (filtered.isEmpty) {
      return NLPResponse(
        text: _buildScheduleCountMessage(
          0,
          "I couldn't find any classes for ${matchedFaculty.name}",
          requestedDay,
        ),
        intent: NLPIntent.schedule,
      );
    }

    return NLPResponse(
      text: _buildScheduleCountMessage(
        filtered.length,
        "Found",
        requestedDay,
        suffix: "for ${matchedFaculty.name}",
      ),
      intent: NLPIntent.schedule,
      schedules: filtered,
      dataJson: jsonEncode({
        'contextType': 'faculty',
        'contextValue': matchedFaculty.name,
        'facultyId': matchedFaculty.id,
      }),
    );
  }

  Faculty? _matchFacultyByName(String query, List<Faculty> facultyList) {
    var cleanedQuery = query.toLowerCase();
    cleanedQuery = cleanedQuery.replaceAll(
      RegExp(r'\b(sir|maam|mr|ms|mrs|prof|professor|dr)\b'),
      '',
    );

    for (var f in facultyList) {
      final name = f.name.toLowerCase();
      if (cleanedQuery.contains(name)) return f;

      final tokens = name.split(RegExp(r'\s+')).where((t) => t.length >= 3);
      for (var token in tokens) {
        final tokenRegex = RegExp(r'\b' + RegExp.escape(token) + r'\b');
        if (tokenRegex.hasMatch(cleanedQuery)) {
          return f;
        }
      }
    }

    return null;
  }

  List<DayOfWeek> _extractDaysOfWeek(String query) {
    final matches = <DayOfWeek>{};
    final tokens = [
      const {'mon', 'monday'},
      const {'tue', 'tues', 'tuesday'},
      const {'wed', 'wednesday'},
      const {'thu', 'thur', 'thurs', 'thursday'},
      const {'fri', 'friday'},
      const {'sat', 'saturday'},
      const {'sun', 'sunday'},
    ];

    for (var i = 0; i < tokens.length; i++) {
      for (var token in tokens[i]) {
        if (_containsKeywordFuzzy(query, [token])) {
          matches.add(DayOfWeek.values[i]);
        }
      }
    }

    return matches.toList()..sort((a, b) => a.index.compareTo(b.index));
  }

  String? _extractSectionFromQuery(String query) {
    final match = RegExp(r'\b([a-zA-Z]{1,4})?\s?\d[a-zA-Z]\b')
        .firstMatch(query.toUpperCase());
    return match?.group(0);
  }

  List<DayOfWeek> _extractRelativeDays(String query) {
    final days = <DayOfWeek>[];
    final now = DateTime.now();
    if (_containsKeywordFuzzy(query, ['today', 'tonight', 'now'])) {
      days.add(_dayFromDate(now));
    }
    if (_containsKeywordFuzzy(query, ['tomorrow'])) {
      days.add(_dayFromDate(now.add(const Duration(days: 1))));
    }
    if (_containsKeywordFuzzy(query, ['weekend'])) {
      days.add(DayOfWeek.sat);
      days.add(DayOfWeek.sun);
    }
    if (_containsKeywordFuzzy(query, ['week'])) {
      days.addAll([
        DayOfWeek.mon,
        DayOfWeek.tue,
        DayOfWeek.wed,
        DayOfWeek.thu,
        DayOfWeek.fri,
      ]);
    }
    return days;
  }

  DayOfWeek _dayFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return DayOfWeek.mon;
      case DateTime.tuesday:
        return DayOfWeek.tue;
      case DateTime.wednesday:
        return DayOfWeek.wed;
      case DateTime.thursday:
        return DayOfWeek.thu;
      case DateTime.friday:
        return DayOfWeek.fri;
      case DateTime.saturday:
        return DayOfWeek.sat;
      case DateTime.sunday:
        return DayOfWeek.sun;
    }
    return DayOfWeek.mon;
  }

  String _dayLabel(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Monday';
      case DayOfWeek.tue:
        return 'Tuesday';
      case DayOfWeek.wed:
        return 'Wednesday';
      case DayOfWeek.thu:
        return 'Thursday';
      case DayOfWeek.fri:
        return 'Friday';
      case DayOfWeek.sat:
        return 'Saturday';
      case DayOfWeek.sun:
        return 'Sunday';
    }
  }

  List<Schedule> _filterSchedulesByDay(
    List<Schedule> schedules,
    DayOfWeek? day,
  ) {
    if (day == null) return schedules;
    return schedules.where((s) => s.timeslot?.day == day).toList();
  }

  String _buildScheduleCountMessage(
    int count,
    String prefix,
    DayOfWeek? day, {
    String? suffix,
  }) {
    final dayPart = day != null ? ' on ${_dayLabel(day)}' : '';
    final suffixPart = suffix != null ? ' $suffix' : '';
    if (prefix.startsWith("I couldn't find")) {
      return '$prefix$dayPart$suffixPart.';
    }
    return '$prefix $count classes$dayPart$suffixPart.';
  }

  String _buildDayCountJson(Map<DayOfWeek, int> counts) {
    final entries = counts.entries
        .map((e) => '"${e.key.name}": ${e.value}')
        .join(', ');
    return '{${entries}}';
  }

  String _normalizeQuery(String query) {
    final cleaned = query.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _containsKeyword(String query, List<String> keywords) {
    for (final keyword in keywords) {
      final re = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
      if (re.hasMatch(query)) return true;
    }
    return false;
  }

  bool _containsKeywordFuzzy(String query, List<String> keywords) {
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    for (final token in tokens) {
      for (final keyword in keywords) {
        if (_levenshtein(token, keyword) <= 1) return true;
      }
    }
    return false;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) dp[i][0] = i;
    for (var j = 0; j <= b.length; j++) dp[0][j] = j;

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[a.length][b.length];
  }

  Future<NLPResponse?> _tryTimeBasedScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
  ) async {
    var timeRange = _extractTimeRange(query);
    final hasNow = _containsKeywordFuzzy(query, ['now', 'ongoing', 'happening']);
    final hasTime = timeRange != null || hasNow;
    var day =
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null);

    if (!hasTime && day == null) return null;

    // Determine schedule scope (admin: all, faculty/student: own)
    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');
    final isStudent = scopes.contains('student');

    List<Schedule> schedules;
    if (isAdmin) {
      schedules = await Schedule.db.find(
        session,
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else if (isFaculty) {
      if (userId == null) return null;
      final faculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(userId),
      );
      if (faculty == null) return null;
      schedules = await Schedule.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else if (isStudent) {
      if (userId == null) return null;
      final student = await Student.db.findFirstRow(
        session,
        where: (t) => t.studentNumber.equals(userId),
      );
      if (student?.section == null) return null;
      schedules = await Schedule.db.find(
        session,
        where: (t) => t.section.equals(student!.section!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else {
      return null;
    }

    final now = DateTime.now();
    final nowDay = _dayFromDate(now);
    final nowMinutes = now.hour * 60 + now.minute;

    if (hasNow) {
      day ??= nowDay;
      timeRange = _TimeRange(nowMinutes, nowMinutes + 1);
    }

    schedules = _filterSchedulesByDay(schedules, day);

    // Next class
    if (_containsKeywordFuzzy(query, ['next']) &&
        _containsKeywordFuzzy(query, ['class'])) {
      if (day == null) day = nowDay;
      final upcoming = schedules
          .where((s) {
            final ts = s.timeslot;
            if (ts == null) return false;
            final start = _parseTimeToMinutes(ts.startTime);
            return start > nowMinutes;
          })
          .toList()
        ..sort((a, b) {
          final sa = _parseTimeToMinutes(a.timeslot?.startTime ?? '00:00');
          final sb = _parseTimeToMinutes(b.timeslot?.startTime ?? '00:00');
          return sa.compareTo(sb);
        });

      if (upcoming.isEmpty) {
        return NLPResponse(
          text: "No upcoming classes found.",
          intent: NLPIntent.schedule,
        );
      }
      final next = upcoming.first;
      return NLPResponse(
        text: "Your next class is ${next.subject?.name ?? 'a class'}.",
        intent: NLPIntent.schedule,
        schedules: [next],
      );
    }

    // First/last class (for day)
    if (_containsKeywordFuzzy(query, ['first', 'last']) &&
        _containsKeywordFuzzy(query, ['class'])) {
      final sorted = List<Schedule>.from(schedules)
        ..sort((a, b) {
          final sa = _parseTimeToMinutes(a.timeslot?.startTime ?? '00:00');
          final sb = _parseTimeToMinutes(b.timeslot?.startTime ?? '00:00');
          return sa.compareTo(sb);
        });
      if (sorted.isEmpty) {
        return NLPResponse(
          text: "No classes found for that day.",
          intent: NLPIntent.schedule,
        );
      }
      final picked = _containsKeywordFuzzy(query, ['last'])
          ? sorted.last
          : sorted.first;
      return NLPResponse(
        text:
            "Your ${_containsKeywordFuzzy(query, ['last']) ? 'last' : 'first'} class is ${picked.subject?.name ?? 'a class'}.",
        intent: NLPIntent.schedule,
        schedules: [picked],
      );
    }

    // Start at / End at exact time
    if (_containsKeywordFuzzy(query, ['start', 'starts']) &&
        _containsKeywordFuzzy(query, ['at'])) {
      final startAt = _parseTimeToken(query);
      if (startAt != null) {
        schedules = schedules.where((s) {
          final ts = s.timeslot;
          if (ts == null) return false;
          return _parseTimeToMinutes(ts.startTime) == startAt;
        }).toList();
      }
    } else if (_containsKeywordFuzzy(query, ['end', 'ends']) &&
        _containsKeywordFuzzy(query, ['at'])) {
      final endAt = _parseTimeToken(query);
      if (endAt != null) {
        schedules = schedules.where((s) {
          final ts = s.timeslot;
          if (ts == null) return false;
          return _parseTimeToMinutes(ts.endTime) == endAt;
        }).toList();
      }
    }

    final filtered = _filterSchedulesByTimeRange(schedules, timeRange);

    if (filtered.isEmpty) {
      return NLPResponse(
        text: day != null
            ? "I couldn't find any classes${timeRange != null ? ' at that time' : ''} on ${_dayLabel(day)}."
            : "I couldn't find any classes for that time range.",
        intent: NLPIntent.schedule,
      );
    }

    return NLPResponse(
      text: "Found ${filtered.length} class(es)${day != null ? ' on ${_dayLabel(day)}' : ''}.",
      intent: NLPIntent.schedule,
      schedules: filtered,
    );
  }

  Future<NLPResponse?> _tryFilteredScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
    _TimeRange? timeRange,
  ) async {
    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');
    final isStudent = scopes.contains('student');

    final day =
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null);
    final roomType = _extractRoomType(query);
    final rooms = await Room.db.find(session);
    final room = _matchRoomByName(query, rooms);

    final facultyList = await Faculty.db.find(session);
    final matchedFaculty = _matchFacultyByName(query, facultyList);

    final section = _extractSectionFromQuery(query);

    final hasAnyFilter = day != null ||
        timeRange != null ||
        roomType != null ||
        room != null ||
        matchedFaculty != null ||
        section != null;
    if (!hasAnyFilter) return null;

    List<Schedule> schedules;
    if (isAdmin) {
      schedules = await Schedule.db.find(
        session,
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else if (isFaculty) {
      if (userId == null) return null;
      final faculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(userId),
      );
      if (faculty == null) return null;
      if (matchedFaculty != null && matchedFaculty.id != faculty.id) {
        return NLPResponse(
          text:
              "You can only view your own schedule. Contact administrators to see other faculty schedules.",
          intent: NLPIntent.schedule,
        );
      }
      schedules = await Schedule.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else if (isStudent) {
      if (userId == null) return null;
      final student = await Student.db.findFirstRow(
        session,
        where: (t) => t.studentNumber.equals(userId),
      );
      if (student?.section == null) return null;
      if (section != null && section != student!.section) {
        return NLPResponse(
          text: "You can only view your own section schedule.",
          intent: NLPIntent.schedule,
        );
      }
      schedules = await Schedule.db.find(
        session,
        where: (t) => t.section.equals(student!.section!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else {
      return null;
    }

    if (matchedFaculty != null) {
      schedules =
          schedules.where((s) => s.facultyId == matchedFaculty.id).toList();
    }
    if (section != null) {
      schedules = schedules.where((s) => s.section == section).toList();
    }
    if (room != null) {
      schedules = schedules.where((s) => s.roomId == room.id).toList();
    }
    if (roomType != null) {
      schedules = schedules.where((s) => s.room?.type == roomType).toList();
    }
    schedules = _filterSchedulesByDay(schedules, day);
    schedules = _filterSchedulesByTimeRange(schedules, timeRange);

    if (schedules.isEmpty) {
      return NLPResponse(
        text: "I couldn't find any matching classes.",
        intent: NLPIntent.schedule,
      );
    }

    if (_containsKeywordFuzzy(query, ['which', 'room']) &&
        section != null &&
        day != null) {
      final roomNames = schedules
          .map((s) => s.room?.name)
          .whereType<String>()
          .toSet()
          .toList();
      return NLPResponse(
        text: "Rooms used: ${roomNames.join(', ')}.",
        intent: NLPIntent.schedule,
        schedules: schedules,
      );
    }

    if (_containsKeywordFuzzy(query, ['who']) &&
        _containsKeywordFuzzy(query, ['teach', 'teaching', 'instructor'])) {
      final names = schedules
          .map((s) => s.faculty?.name)
          .whereType<String>()
          .toSet()
          .toList();
      return NLPResponse(
        text: "Teaching: ${names.join(', ')}.",
        intent: NLPIntent.schedule,
        schedules: schedules,
      );
    }

    return NLPResponse(
      text: "Found ${schedules.length} class(es).",
      intent: NLPIntent.schedule,
      schedules: schedules,
    );
  }

  Future<NLPResponse?> _tryRoomTimeQuery(
    Session session,
    String query,
    List<DayOfWeek> relativeDays,
    List<String> scopes,
  ) async {
    var timeRange = _extractTimeRange(query);
    final hasNow = _containsKeywordFuzzy(query, ['now']);
    if (timeRange == null && !hasNow) return null;

    if (!scopes.contains('admin')) {
      return NLPResponse(
        text:
            "Please specify a room name to check availability.",
        intent: NLPIntent.roomStatus,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      include: Schedule.include(
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );
    var day = relativeDays.length == 1 ? relativeDays.first : null;
    if (hasNow) {
      final now = DateTime.now();
      day ??= _dayFromDate(now);
      final nowMinutes = now.hour * 60 + now.minute;
      timeRange ??= _TimeRange(nowMinutes, nowMinutes + 1);
    }
    final filtered = schedules.where((s) {
      final ts = s.timeslot;
      if (ts == null || s.room == null) return false;
      if (day != null && ts.day != day) return false;
      return _timeRangeOverlaps(
        _parseTimeToMinutes(ts.startTime),
        _parseTimeToMinutes(ts.endTime),
        timeRange,
      );
    }).toList();

    final rooms = await Room.db.find(session);
    final occupiedRoomIds = filtered.map((s) => s.roomId).toSet();
    final availableRooms =
        rooms.where((r) => !occupiedRoomIds.contains(r.id)).toList();

    return NLPResponse(
      text:
          "Available rooms: ${availableRooms.take(8).map((r) => r.name).join(', ')}${availableRooms.length > 8 ? '...' : ''}",
      intent: NLPIntent.roomStatus,
      dataJson: jsonEncode({
        'availableCount': availableRooms.length,
      }),
    );
  }

  List<Schedule> _filterSchedulesByTimeRange(
    List<Schedule> schedules,
    _TimeRange? range,
  ) {
    if (range == null) return schedules;
    return schedules.where((s) {
      final ts = s.timeslot;
      if (ts == null) return false;
      final start = _parseTimeToMinutes(ts.startTime);
      final end = _parseTimeToMinutes(ts.endTime);
      return _timeRangeOverlaps(start, end, range);
    }).toList();
  }

  bool _timeRangeOverlaps(int start, int end, _TimeRange? range) {
    if (range == null) return true;
    return !(end <= range.start || start >= range.end);
  }

  _TimeRange? _extractTimeRange(String query) {
    // Between/From X to Y
    final between = RegExp(
      r'(between|from)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)\s+(and|to)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)',
    ).firstMatch(query);
    if (between != null) {
      final start = _parseTimeToken(between.group(2));
      final end = _parseTimeToken(between.group(5));
      if (start != null && end != null) return _TimeRange(start, end);
    }

    // After X
    final after = RegExp(
      r'(after)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)',
    ).firstMatch(query);
    if (after != null) {
      final start = _parseTimeToken(after.group(2));
      if (start != null) return _TimeRange(start, 24 * 60);
    }

    // Before X
    final before = RegExp(
      r'(before)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)',
    ).firstMatch(query);
    if (before != null) {
      final end = _parseTimeToken(before.group(2));
      if (end != null) return _TimeRange(0, end);
    }

    if (_containsKeywordFuzzy(query, ['morning'])) {
      return _TimeRange(7 * 60, 12 * 60);
    }
    if (_containsKeywordFuzzy(query, ['afternoon'])) {
      return _TimeRange(12 * 60, 17 * 60);
    }
    if (_containsKeywordFuzzy(query, ['evening'])) {
      return _TimeRange(17 * 60, 21 * 60);
    }

    final match = RegExp(r'(\d{1,2})(?::(\d{2}))?\s?(am|pm)?')
        .allMatches(query)
        .toList();
    if (match.isEmpty) return null;
    final first = match.first;
    final token = first.group(0);
    final start = _parseTimeToken(token);
    if (start == null) return null;
    return _TimeRange(start, start + 60);
  }

  int? _parseTimeToken(String? token) {
    if (token == null) return null;
    final match = RegExp(r'(\d{1,2})(?::(\d{2}))?\s?(am|pm)?')
        .firstMatch(token.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    var h = hour;
    final ampm = match.group(3);
    if (ampm != null) {
      if (ampm.toLowerCase() == 'pm' && h < 12) h += 12;
      if (ampm.toLowerCase() == 'am' && h == 12) h = 0;
    }
    return h * 60 + minute;
  }

  int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
}

class _TimeRange {
  final int start;
  final int end;
  const _TimeRange(this.start, this.end);
}
