import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class CustomAuthEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<_LoginTarget?> _resolveLoginTarget(
    Session session, {
    required String id,
    required String role,
  }) async {
    if (role == 'student') {
      final student = await Student.db.findFirstRow(
        session,
        where: (t) => t.studentNumber.equals(id),
      );
      if (student == null) return null;
      return _LoginTarget(email: student.email);
    }

    // Faculty or Admin login
    final faculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.facultyId.equals(id),
    );
    if (faculty == null) return null;
    return _LoginTarget(email: faculty.email);
  }

  /// Logs in a user using their ID (Student ID or Faculty ID) and password.
  Future<AuthenticationResponse> loginWithId(
    Session session, {
    required String id,
    required String password,
    required String role, // 'student' or 'faculty'
  }) async {
    final normalizedId = id.trim();
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedId.isEmpty || password.isEmpty) {
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }

    if (normalizedRole != 'student' &&
        normalizedRole != 'faculty' &&
        normalizedRole != 'admin') {
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }

    final target = await _resolveLoginTarget(
      session,
      id: normalizedId,
      role: normalizedRole,
    );
    if (target == null) {
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }

    if (target.email.isEmpty) {
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }
    final emailLower = target.email.toLowerCase();

    // Strict authentication: no automatic account creation or password reset.
    return Emails.authenticate(session, emailLower, password);
  }
}

class _LoginTarget {
  final String email;

  const _LoginTarget({
    required this.email,
  });
}
