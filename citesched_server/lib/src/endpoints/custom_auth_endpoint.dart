import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:serverpod_auth_server/src/business/email_auth.dart'
    as email_auth;
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
    String? displayName;
    print('--- LOGIN WITH ID DEBUG ---');
    print('ID: $id, Role: $role');

    if (role == 'student') {
      var student = await Student.db.findFirstRow(
        session,
        where: (t) => t.studentNumber.equals(id),
      );
      if (student == null) {
        print('FAIL: Student with ID $id not found');
        return AuthenticationResponse(
          success: false,
          failReason: AuthenticationFailReason.invalidCredentials,
        );
      }
      email = student.email;
      displayName = student.name;
      print('FOUND Student email: $email');
    } else {
      // Faculty or Admin login
      // Search in Faculty table first
      var faculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(id),
      );

      if (faculty != null) {
        email = faculty.email;
        displayName = faculty.name;
        print('FOUND Faculty email: $email');
      } else {
        print('FAIL: Faculty/Admin with ID $id not found');
        return AuthenticationResponse(
          success: false,
          failReason: AuthenticationFailReason.invalidCredentials,
        );
      }
    }

    // Ensure we have a usable email
    if (email == null || email.isEmpty) {
      print('FAIL: Resolved email is null/empty for ID $id');
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }
    final emailLower = email.toLowerCase();

    // Now authenticate using the resolved email
    var response = await Emails.authenticate(session, emailLower, password);

    if (!response.success) {
      // If auth fails, ensure an auth user exists and reset password to provided one (or ID).
      final createPassword = password.isNotEmpty ? password : id;

      // Create user if missing
      final user = await Emails.createUser(
        session,
        (displayName != null && displayName.isNotEmpty)
            ? displayName
            : email,
        email,
        createPassword,
      );

      if (user != null && user.id != null) {
        // Upsert auth hash (reset password)
        final newHash =
            await email_auth.defaultGeneratePasswordHash(createPassword);
        // Try locate by userId first (safer than email casing), then by email.
        EmailAuth? existingAuth = await EmailAuth.db.findFirstRow(
          session,
          where: (t) => t.userId.equals(user.id!),
        );
        existingAuth ??= await EmailAuth.db.findFirstRow(
          session,
          where: (t) => t.email.equals(emailLower),
        );
        if (existingAuth == null) {
          await EmailAuth.db.insertRow(
            session,
            EmailAuth(
              userId: user.id!,
              email: emailLower,
              hash: newHash,
            ),
          );
        } else {
          existingAuth.email = emailLower;
          existingAuth.hash = newHash;
          await EmailAuth.db.updateRow(session, existingAuth);
        }

        // Attach scope for role
        final currentScopes = user.scopeNames.map((s) => Scope(s)).toSet();
        currentScopes.add(Scope(role));
        await Users.updateUserScopes(session, user.id!, currentScopes);

        // Ensure UserRole exists (custom login depends on it)
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

      // Retry authentication after ensuring user exists
      response = await Emails.authenticate(session, emailLower, createPassword);

      if (!response.success) {
        session.log(
          'LoginWithId Failed: Authentication failed for email $email. FailReason: ${response.failReason}',
        );
        print('FAIL: Password authentication failed for $email');
        return response;
      }
    }

    session.log('LoginWithId Success: Authenticated $email');
    print('SUCCESS: Authenticated $email');
    return response;
  }
}
