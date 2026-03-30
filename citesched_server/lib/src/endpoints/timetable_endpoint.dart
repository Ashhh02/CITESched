import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';
import '../services/timetable_service.dart';
import '../auth/scopes.dart';

class TimetableEndpoint extends Endpoint {
  final TimetableService _timetableService = TimetableService();

  Future<Student?> _findCurrentStudent(
    Session session,
    dynamic authInfo,
  ) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Student.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final resolvedLinkedUserInfo = linkedUserInfo!;
      final byLinkedUserInfo = await Student.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(resolvedLinkedUserInfo.id!),
      );
      if (byLinkedUserInfo != null) return byLinkedUserInfo;

      final linkedEmail =
          (resolvedLinkedUserInfo.email ?? '').trim().toLowerCase();
      if (linkedEmail.isNotEmpty) {
        final byLinkedEmail = await Student.db.findFirstRow(
          session,
          where: (t) => t.email.equals(linkedEmail),
        );
        if (byLinkedEmail != null) return byLinkedEmail;
      }
    }

    return await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier),
    );
  }

  Future<Faculty?> _findCurrentFaculty(
    Session session,
    dynamic authInfo,
  ) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final resolvedLinkedUserInfo = linkedUserInfo!;
      final byLinkedUserInfo = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(resolvedLinkedUserInfo.id!),
      );
      if (byLinkedUserInfo != null) return byLinkedUserInfo;

      final linkedEmail =
          (resolvedLinkedUserInfo.email ?? '').trim().toLowerCase();
      if (linkedEmail.isNotEmpty) {
        final byLinkedEmail = await Faculty.db.findFirstRow(
          session,
          where: (t) => t.email.equals(linkedEmail),
        );
        if (byLinkedEmail != null) return byLinkedEmail;
      }
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

  Future<List<ScheduleInfo>> _getStudentPersonalSchedule(
    Session session,
    dynamic authInfo,
  ) async {
    final student = await _findCurrentStudent(session, authInfo);
    if (student == null) return [];

    if (student.sectionId != null) {
      return await _timetableService.fetchSchedulesBySectionId(
        session,
        student.sectionId!,
        fallbackSectionCode: student.section,
      );
    }

    if (student.section != null && student.section!.isNotEmpty) {
      final resolvedSectionId = await _timetableService.resolveSectionIdByCode(
        session,
        student.section!,
      );
      if (resolvedSectionId != null) {
        student.sectionId = resolvedSectionId;
        try {
          await Student.db.updateRow(session, student);
        } catch (_) {}
        return await _timetableService.fetchSchedulesBySectionId(
          session,
          resolvedSectionId,
          fallbackSectionCode: student.section,
        );
      }
    }

    if (student.section == null || student.section!.isEmpty) {
      return [];
    }

    return await _timetableService.fetchSchedulesWithFilters(
      session,
      TimetableFilterRequest(section: student.section),
    );
  }

  Future<List<ScheduleInfo>> _getFacultyPersonalSchedule(
    Session session,
    dynamic authInfo,
  ) async {
    final faculty = await _findCurrentFaculty(session, authInfo);
    if (faculty == null) return [];

    return await _timetableService.fetchSchedulesWithFilters(
      session,
      TimetableFilterRequest(facultyId: faculty.id!),
    );
  }

  Future<List<ScheduleInfo>> getPersonalSchedule(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('Authentication required');
    }

    final scopes = authInfo.scopes;
    if (scopes.contains(AppScopes.student)) {
      return await _getStudentPersonalSchedule(session, authInfo);
    }
    if (scopes.contains(AppScopes.faculty)) {
      return await _getFacultyPersonalSchedule(session, authInfo);
    }

    final student = await _findCurrentStudent(session, authInfo);
    if (student != null) {
      return await _getStudentPersonalSchedule(session, authInfo);
    }

    final faculty = await _findCurrentFaculty(session, authInfo);
    if (faculty != null) {
      return await _getFacultyPersonalSchedule(session, authInfo);
    }

    return [];
  }
}
