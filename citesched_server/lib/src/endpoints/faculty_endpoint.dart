import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../auth/scopes.dart';

class FacultyEndpoint extends Endpoint {
  Future<Faculty?> _findCurrentFaculty(Session session, dynamic authInfo) async {
    final userIdentifier = authInfo.userIdentifier.toString();
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Faculty.db.findFirstRow(
        session,
        where: (f) => f.userInfoId.equals(userInfoId),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    return await Faculty.db.findFirstRow(
      session,
      where: (f) => f.email.equals(userIdentifier),
    );
  }

  @override
  Set<Scope> get requiredScopes => {AppScopes.faculty};

  /// Fetches the schedule for the logged-in faculty.
  Future<List<Schedule>> getMySchedule(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('Unauthorized: You must be logged in.');
    }

    final faculty = await _findCurrentFaculty(session, authInfo);

    if (faculty == null) {
      throw Exception('Faculty profile not found.');
    }

    return await Schedule.db.find(
      session,
      where: (s) => s.facultyId.equals(faculty.id),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Get personal profile
  Future<Faculty?> getMyProfile(Session session) async {
    final authInfo = session.authenticated;
    if (authInfo == null) return null;
    return await _findCurrentFaculty(session, authInfo);
  }
}
