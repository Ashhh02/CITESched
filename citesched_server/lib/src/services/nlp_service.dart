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

    // Check for forbidden keywords - NEVER execute
    if (_containsForbiddenKeywords(lowerQuery)) {
      return _unsupportedResponse();
    }

    // 1. My Schedule Queries (All authenticated users)
    if (lowerQuery.contains('my schedule') ||
        lowerQuery.contains('my timetable') ||
        lowerQuery.contains('my classes')) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to view your schedule.",
          intent: NLPIntent.unknown,
        );
      }
      return await _handleMyScheduleQuery(session, userId, scopes);
    }

    // 2. Conflict Queries (All authenticated users)
    if (lowerQuery.contains('conflict') || lowerQuery.contains('issue')) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to check for conflicts.",
          intent: NLPIntent.unknown,
        );
      }
      return await _handleConflictQuery(session, userId, scopes);
    }

    // 3. Faculty Overload Queries (All authenticated users)
    if (lowerQuery.contains('overload') ||
        (lowerQuery.contains('load') &&
            (lowerQuery.contains('faculty') || lowerQuery.contains('units')))) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to check faculty load information.",
          intent: NLPIntent.unknown,
        );
      }
      return await _handleOverloadQuery(session, userId, scopes, lowerQuery);
    }

    // 4. Room Availability Queries
    if (lowerQuery.contains('room') ||
        lowerQuery.contains('lab') ||
        lowerQuery.contains('lecture hall') ||
        lowerQuery.contains('available') ||
        lowerQuery.contains('free')) {
      return await _handleRoomQuery(session, lowerQuery);
    }

    // 5. Section/Schedule Queries
    if (lowerQuery.contains('schedule') ||
        lowerQuery.contains('timetable') ||
        lowerQuery.contains('class') ||
        _containsSectionPattern(lowerQuery)) {
      return await _handleScheduleQuery(session, lowerQuery);
    }

    return _unsupportedResponse();
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

  /// Handles "My Schedule" query for current authenticated user
  Future<NLPResponse> _handleMyScheduleQuery(
    Session session,
    String userId,
    List<String> scopes,
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

        return NLPResponse(
          text:
              "You have ${schedules.length} classes scheduled. View details below.",
          intent: NLPIntent.schedule,
          schedules: schedules,
        );
      } else if (isStudent) {
        // Get student section schedules
        // Note: Implement based on your student section mapping

        return NLPResponse(
          text: "Retrieving your class schedule...",
          intent: NLPIntent.schedule,
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
      final isAdmin = scopes.contains('admin');
      final isFaculty = scopes.contains('faculty');
      final isStudent = scopes.contains('student');

      // Admin sees all conflicts
      if (isAdmin) {
        final conflicts = await _conflictService.getAllConflicts(session);
        if (conflicts.isEmpty) {
          return NLPResponse(
            text:
                "Great news! There are currently no conflicts detected in the system.",
            intent: NLPIntent.conflict,
          );
        }

        final roomConflicts = conflicts
            .where((c) => c.type.toLowerCase().contains('room'))
            .length;
        final facultyConflicts = conflicts
            .where((c) => c.type.toLowerCase().contains('faculty'))
            .length;

        var summary = "I found ${conflicts.length} conflict(s): ";
        if (roomConflicts > 0) summary += "$roomConflicts room conflict(s). ";
        if (facultyConflicts > 0)
          summary += "$facultyConflicts faculty conflict(s). ";

        return NLPResponse(
          text:
              "$summary You can view details in the Conflict Module or use Timetable to resolve.",
          intent: NLPIntent.conflict,
          dataJson:
              '{"count": ${conflicts.length}, "room": $roomConflicts, "faculty": $facultyConflicts}',
        );
      }

      // Faculty sees conflicts related to their schedules
      if (isFaculty) {
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

        // Check for conflicts in this faculty's schedules
        int conflictCount = 0;
        for (var schedule in schedules) {
          final timeslotConflict = await _conflictService
              .checkFacultyAvailability(
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

      // Students see conflicts related to their section
      if (isStudent) {
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

        // Check for section conflicts
        int conflictCount = 0;
        for (var schedule in schedules) {
          final sectionConflict = await _conflictService
              .checkSectionAvailability(
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
        if (facultyId != null) {
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
          dataJson:
              '{"id": ${foundRoom.id}, "capacity": ${foundRoom.capacity}}',
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
  ) async {
    try {
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

        if (schedules.isEmpty) {
          return NLPResponse(
            text: "I couldn't find any classes scheduled for section $section.",
            intent: NLPIntent.schedule,
          );
        }

        return NLPResponse(
          text: "Found ${schedules.length} classes for section $section.",
          intent: NLPIntent.schedule,
          schedules: schedules,
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
}
