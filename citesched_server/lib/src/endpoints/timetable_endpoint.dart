import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/timetable_service.dart';
import '../auth/scopes.dart';

class TimetableEndpoint extends Endpoint {
  final TimetableService _timetableService = TimetableService();

  Future<Student?> _findCurrentStudent(Session session, dynamic authInfo) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Student.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    return await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier),
    );
  }

  Future<Faculty?> _findCurrentFaculty(Session session, dynamic authInfo) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    return await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier),
    );
  }

  @override
  bool get requireLogin => true;

  Future<List<ScheduleInfo>> getSchedules(
    Session session,
    TimetableFilterRequest filter,
  ) async {
    return await _timetableService.fetchSchedulesWithFilters(session, filter);
  }

  Future<TimetableSummary> getSummary(
    Session session,
    TimetableFilterRequest filter,
  ) async {
    return await _timetableService.fetchSectionSummary(session, filter);
  }

  Future<List<ScheduleInfo>> getPersonalSchedule(Session session) async {
    var authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('Authentication required');
    }

    // Check scopes/roles to determine if Student or Faculty
    var scopes = authInfo.scopes;

    if (scopes.contains(AppScopes.student)) {
      var student = await _findCurrentStudent(session, authInfo);
      if (student == null) return [];

      if (student.sectionId != null) {
        return await _timetableService.fetchSchedulesBySectionId(
          session,
          student.sectionId!,
          fallbackSectionCode: student.section,
        );
      }

      if (student.section == null || student.section!.isEmpty) {
        return [];
      }

      return await _timetableService.fetchSchedulesWithFilters(
        session,
        TimetableFilterRequest(section: student.section),
      );
    } else if (scopes.contains(AppScopes.faculty)) {
      var faculty = await _findCurrentFaculty(session, authInfo);
      if (faculty == null) return [];

      return await _timetableService.fetchSchedulesWithFilters(
        session,
        TimetableFilterRequest(facultyId: faculty.id!),
      );
    }

    return [];
  }
}
