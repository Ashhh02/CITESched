import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class StudentScheduleEndpoint extends Endpoint {
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

  /// Fetches the schedule for the logged-in student based on their section.
  Future<List<Schedule>> fetchMySchedule(Session session) async {
    // 1. Authentication Check
    final user = session.authenticated;
    if (user == null) {
      throw Exception('Unauthorized: You must be logged in.');
    }

    // 2. Fetch Student Profile
    final student = await _findCurrentStudent(session, user);

    if (student == null) {
      throw Exception('Student profile not found.');
    }

    // 3. Fetch Schedules for the Student's Section
    if (student.sectionId != null) {
      final bySectionId = await Schedule.db.find(
        session,
        where: (s) =>
            s.sectionId.equals(student.sectionId) & s.isActive.equals(true),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
        orderBy: (s) => s.timeslotId,
      );

      if (bySectionId.isNotEmpty) {
        return bySectionId;
      }
    }

    if (student.section == null || student.section!.isEmpty) {
      return [];
    }

    return await Schedule.db.find(
      session,
      where: (s) =>
          s.section.equals(student.section) & s.isActive.equals(true),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }
}
