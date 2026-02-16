import 'package:serverpod/serverpod.dart';

import '../auth/scopes.dart';
import '../generated/protocol.dart';

/// Student-only endpoint for viewing schedules and managing own profile.
/// Only users with the 'student' scope can access these methods.
class StudentEndpoint extends Endpoint {
  @override
  Set<Scope> get requiredScopes => {AppScopes.student};

  // ─── Schedule Viewing ────────────────────────────────────────────────

  /// Get all available schedules (read-only for students).
  Future<List<Schedule>> getSchedules(Session session) async {
    return await Schedule.db.find(session);
  }

  /// Get a specific schedule by ID.
  Future<Schedule?> getScheduleById(Session session, int id) async {
    return await Schedule.db.findById(session, id);
  }

  // ─── Student Profile ─────────────────────────────────────────────────

  /// Get the current student's profile by their auth user ID.
  Future<Student?> getMyProfile(Session session) async {
    var authInfo = session.authenticated;
    if (authInfo == null) return null;

    return await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(authInfo.userIdentifier),
    );
  }

  /// Update the current student's profile.
  Future<Student?> updateMyProfile(
    Session session,
    Student updatedProfile,
  ) async {
    var authInfo = session.authenticated;
    if (authInfo == null) return null;

    // Only allow updating own profile
    var existing = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(authInfo.userIdentifier),
    );

    if (existing == null) return null;

    // Preserve the ID and email; only update editable fields.
    existing.name = updatedProfile.name;
    existing.course = updatedProfile.course;
    existing.yearLevel = updatedProfile.yearLevel;
    existing.updatedAt = DateTime.now();

    return await Student.db.updateRow(session, existing);
  }

  // ─── Read-Only Data ──────────────────────────────────────────────────

  /// Get all faculty members (read-only).
  Future<List<Faculty>> getFaculty(Session session) async {
    return await Faculty.db.find(session);
  }

  /// Get all rooms (read-only).
  Future<List<Room>> getRooms(Session session) async {
    return await Room.db.find(session);
  }

  /// Get all subjects (read-only).
  Future<List<Subject>> getSubjects(Session session) async {
    return await Subject.db.find(session);
  }

  /// Get all timeslots (read-only).
  Future<List<Timeslot>> getTimeslots(Session session) async {
    return await Timeslot.db.find(session);
  }
}
