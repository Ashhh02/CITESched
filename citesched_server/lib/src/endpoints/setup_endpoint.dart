import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class SetupEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<bool> createAccount(
    Session session, {
    required String userName,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? facultyId,
  }) async {
    try {
      var userInfo = await Emails.createUser(
        session,
        userName,
        email,
        password,
      );
      if (userInfo == null) {
        session.log(
          'User $email might already exist. Trying to update scopes...',
        );
        userInfo = await UserInfo.db.findFirstRow(
          session,
          where: (t) => t.email.equals(email),
        );

        if (userInfo == null) {
          session.log(
            'Failed to find user $email even though createUser returned null.',
          );
          return false;
        }
      }

      if (userInfo.scopeNames == null) {
        userInfo.scopeNames = [];
      }
      userInfo.scopeNames!.add(role);
      await UserInfo.db.updateRow(session, userInfo);

      // Create linked profile based on role
      if (role == 'student' && studentId != null) {
        var existingStudent = await Student.db.findFirstRow(
          session,
          where: (t) => t.email.equals(email),
        );
        if (existingStudent == null) {
          await Student.db.insertRow(
            session,
            Student(
              name: userName,
              email: email,
              studentNumber: studentId,
              course: 'BSIT', // Default
              yearLevel: 1, // Default
              userInfoId: userInfo!.id!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      } else if ((role == 'faculty' || role == 'admin') && facultyId != null) {
        var existingFaculty = await Faculty.db.findFirstRow(
          session,
          where: (t) => t.email.equals(email),
        );
        if (existingFaculty == null) {
          await Faculty.db.insertRow(
            session,
            Faculty(
              name: userName,
              email: email,
              department: 'CITE', // Default
              maxLoad: 18,
              employmentStatus: EmploymentStatus.fullTime,
              shiftPreference: FacultyShiftPreference.any,
              facultyId: facultyId,
              userInfoId: userInfo!.id!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      // Add UserRole entry to ensure authenticationHandler picks it up
      var existingRole = await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userInfo!.id.toString()),
      );

      if (existingRole == null) {
        await UserRole.db.insertRow(
          session,
          UserRole(
            userId: userInfo!.id.toString(),
            role: role,
          ),
        );
      }

      session.log(
        'Created user $email with role $role and ID ${studentId ?? facultyId}',
      );
      return true;
    } catch (e) {
      session.log('Error creating user: $e');
      return false;
    }
  }
}
