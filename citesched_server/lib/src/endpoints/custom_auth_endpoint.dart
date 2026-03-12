import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:serverpod_auth_server/src/business/email_auth.dart'
    as email_auth;
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
      return _LoginTarget(email: student.email, displayName: student.name);
    }

    // Faculty or Admin login
    final faculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.facultyId.equals(id),
    );
    if (faculty == null) return null;
    return _LoginTarget(email: faculty.email, displayName: faculty.name);
  }

  Future<void> _ensureUserAndAuth(
    Session session, {
    required String email,
    required String displayName,
    required String password,
    required String fallbackPassword,
    required String role,
  }) async {
    final createPassword = password.isNotEmpty ? password : fallbackPassword;
    final user = await Emails.createUser(
      session,
      displayName.isNotEmpty ? displayName : email,
      email,
      createPassword,
    );

    if (user == null || user.id == null) return;

    final newHash = await email_auth.defaultGeneratePasswordHash(
      createPassword,
    );

    EmailAuth? existingAuth = await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(user.id!),
    );
    existingAuth ??= await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );

    if (existingAuth == null) {
      await EmailAuth.db.insertRow(
        session,
        EmailAuth(
          userId: user.id!,
          email: email,
          hash: newHash,
        ),
      );
    } else {
      existingAuth.email = email;
      existingAuth.hash = newHash;
      await EmailAuth.db.updateRow(session, existingAuth);
    }

    final currentScopes = user.scopeNames.map((s) => Scope(s)).toSet();
    currentScopes.add(Scope(role));
    await Users.updateUserScopes(session, user.id!, currentScopes);

    final userIdStr = user.id.toString();
    if (userIdStr.isNotEmpty) {
      final existingRole = await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userIdStr),
      );
      if (existingRole == null) {
        await UserRole.db.insertRow(
          session,
          UserRole(userId: userIdStr, role: role),
        );
      }
    }
  }

  /// Logs in a user using their ID (Student ID or Faculty ID) and password.
  Future<AuthenticationResponse> loginWithId(
    Session session, {
    required String id,
    required String password,
    required String role, // 'student' or 'faculty'
  }) async {
    print('--- LOGIN WITH ID DEBUG ---');
    print('ID: $id, Role: $role');

    final target = await _resolveLoginTarget(
      session,
      id: id,
      role: role,
    );
    if (target == null) {
      print('FAIL: User with ID $id not found');
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }

    if (target.email.isEmpty) {
      print('FAIL: Resolved email is null/empty for ID $id');
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }
    final emailLower = target.email.toLowerCase();

    // Now authenticate using the resolved email
    var response = await Emails.authenticate(session, emailLower, password);

    if (!response.success) {
      // If auth fails, ensure an auth user exists and reset password to provided one (or ID).
      await _ensureUserAndAuth(
        session,
        email: emailLower,
        displayName: target.displayName,
        password: password,
        fallbackPassword: id,
        role: role,
      );

      // Retry authentication after ensuring user exists
      final retryPassword = password.isNotEmpty ? password : id;
      response = await Emails.authenticate(session, emailLower, retryPassword);

      if (!response.success) {
        session.log(
          'LoginWithId Failed: Authentication failed for email ${target.email}. FailReason: ${response.failReason}',
        );
        print('FAIL: Password authentication failed for ${target.email}');
        return response;
      }
    }

    session.log('LoginWithId Success: Authenticated ${target.email}');
    print('SUCCESS: Authenticated ${target.email}');
    return response;
  }
}

class _LoginTarget {
  final String email;
  final String displayName;

  const _LoginTarget({
    required this.email,
    required this.displayName,
  });
}
