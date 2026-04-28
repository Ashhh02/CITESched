import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class CustomAuthEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<UserInfo?> _loadUserInfoForEmail(Session session, String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    return await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
  }

  Future<UserRole?> _loadUserRoleForUserInfo(
    Session session,
    UserInfo? userInfo,
  ) async {
    final userInfoId = userInfo?.id;
    if (userInfoId == null) return null;

    return await UserRole.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userInfoId.toString()),
    );
  }

  Future<UserInfo?> _repairScopesForLogin(
    Session session, {
    required UserInfo? userInfo,
    required String normalizedRole,
    Faculty? faculty,
  }) async {
    if (userInfo == null) return null;

    final updatedScopes = userInfo.scopeNames.toSet();
    final userRole = await _loadUserRoleForUserInfo(session, userInfo);
    var storedRole = userRole?.role.trim().toLowerCase();

    if (storedRole == 'faculty_declined') {
      return null;
    }

    // Repair legacy admin-created faculty rows that were left in
    // faculty_pending even though the faculty profile is already active.
    if (storedRole == 'faculty_pending' &&
        normalizedRole == 'faculty' &&
        faculty?.isActive == true) {
      if (userRole != null) {
        userRole.role = 'faculty';
        await UserRole.db.updateRow(session, userRole);
      } else if (userInfo.id != null) {
        await UserRole.db.insertRow(
          session,
          UserRole(userId: userInfo.id!.toString(), role: 'faculty'),
        );
      }
      storedRole = 'faculty';
    } else if (storedRole == 'faculty_pending') {
      return null;
    }

    if (normalizedRole == 'faculty') {
      if (faculty == null || !faculty.isActive) {
        return null;
      }
      updatedScopes.add('faculty');
    } else if (normalizedRole == 'student') {
      updatedScopes.add('student');
    } else if (normalizedRole == 'admin') {
      updatedScopes.add('admin');
    }

    if (storedRole == 'admin') {
      updatedScopes.add('admin');
    } else if (storedRole == 'faculty') {
      updatedScopes.add('faculty');
    } else if (storedRole == 'student') {
      updatedScopes.add('student');
    }

    final repairedScopeNames = updatedScopes.toList();
    final didChange = repairedScopeNames.length != userInfo.scopeNames.length ||
        !repairedScopeNames.toSet().containsAll(userInfo.scopeNames);

    if (didChange) {
      userInfo.scopeNames = repairedScopeNames;
      await UserInfo.db.updateRow(session, userInfo);
    }

    return userInfo.copyWith(scopeNames: repairedScopeNames);
  }

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
    final authResponse = await Emails.authenticate(session, emailLower, password);
    if (!authResponse.success) {
      return authResponse;
    }

    final userInfo =
        authResponse.userInfo ?? await _loadUserInfoForEmail(session, emailLower);

    Faculty? faculty;
    if (normalizedRole == 'faculty' || normalizedRole == 'admin') {
      faculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(normalizedId),
      );
      if (normalizedRole == 'faculty' && (faculty == null || !faculty.isActive)) {
        return AuthenticationResponse(
          success: false,
          failReason: AuthenticationFailReason.invalidCredentials,
        );
      }
    }

    final repairedUserInfo = await _repairScopesForLogin(
      session,
      userInfo: userInfo,
      normalizedRole: normalizedRole,
      faculty: faculty,
    );

    if (repairedUserInfo == null) {
      return AuthenticationResponse(
        success: false,
        failReason: AuthenticationFailReason.invalidCredentials,
      );
    }

    authResponse.userInfo = repairedUserInfo;
    return authResponse;
  }
}

class _LoginTarget {
  final String email;

  const _LoginTarget({
    required this.email,
  });
}
