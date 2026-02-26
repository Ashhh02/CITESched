import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class StudentScheduleEndpoint extends Endpoint {
  /// Fetches the schedule for the logged-in student based on their section.
  Future<List<Schedule>> fetchMySchedule(Session session) async {
    // 1. Authentication Check
    final user = await session.authenticated;
    if (user == null) {
      throw Exception('Unauthorized: You must be logged in.');
    }

    // 2. Fetch Student Profile
    final student = await Student.db.findFirstRow(
      session,
      where: (s) => s.email.equals(user.userIdentifier),
    );

    if (student == null) {
      throw Exception('Student profile not found.');
    }

    if (student.section == null || student.section!.isEmpty) {
      return [];
    }

    // 3. Fetch Schedules for the Student's Section
    final schedules = await Schedule.db.find(
      session,
      where: (s) => s.section.equals(student.section) & s.isActive.equals(true),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );

    return schedules;
  }
}
