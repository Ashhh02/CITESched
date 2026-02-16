import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class CustomAuthEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// Logs in a user using their ID (Student ID or Faculty ID) and password.
  Future<AuthenticationResponse> loginWithId(
    Session session, {
    required String id,
    required String password,
    required String role, // 'student' or 'faculty'
  }) async {
    String? email;

    if (role == 'student') {
      var student = await Student.db.findFirstRow(
        session,
        where: (t) => t.studentNumber.equals(id),
      );
      if (student == null) {
        return AuthenticationResponse(
          success: false,
          failReason: AuthenticationFailReason.invalidCredentials,
        );
      }
      email = student.email;
    } else {
      // Faculty or Admin login
      // Search in Faculty table first
      var faculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(id),
      );

      if (faculty != null) {
        email = faculty.email;
      } else {
        // If not found in Faculty table, check if it's an admin trying to login with ID?
        // But if admin doesn't have a linked faculty profile, they can't login via ID.
        // They should use email login. But the UI asks for ID.
        // So we assume all ID-based logins MUST have a linked profile.
        return AuthenticationResponse(
          success: false,
          failReason: AuthenticationFailReason.invalidCredentials,
        );
      }
    }

    if (email == null) {
      session.log('LoginWithId Failed: ID $id not found for role $role');
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }

    // Now authenticate using the resolved email
    var response = await Emails.authenticate(session, email, password);
    if (!response.success) {
      session.log('LoginWithId Failed: Authentication failed for email $email');
    } else {
      session.log('LoginWithId Success: Authenticated $email');
    }
    return response;
  }
}
