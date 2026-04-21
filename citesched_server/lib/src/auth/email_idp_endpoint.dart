import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

import '../generated/protocol.dart';
import 'scopes.dart';

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
class EmailIdpEndpoint extends EmailIdpBaseEndpoint {
  @override
  Future<UuidValue> startPasswordReset(
    Session session, {
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final repaired = await _ensureIdpEmailAccount(session, normalizedEmail);
    if (repaired) {
      await emailIdp.admin.deletePasswordResetRequestsAttemptsForEmail(
        session,
        email: normalizedEmail,
      );
      session.log(
        '[EmailIdp] Cleared stale password reset attempts for $normalizedEmail',
      );
    }
    return super.startPasswordReset(session, email: normalizedEmail);
  }

  @override
  Future<void> finishPasswordReset(
    Session session, {
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    final resetRequestId = _extractResetRequestId(finishPasswordResetToken);
    String? emailToSync;

    if (resetRequestId != null) {
      final resetRequest = await EmailAccountPasswordResetRequest.db.findById(
        session,
        resetRequestId,
      );
      if (resetRequest != null) {
        final account = await EmailAccount.db.findById(
          session,
          resetRequest.emailAccountId,
        );
        emailToSync = account?.email;
      }
    }

    await super.finishPasswordReset(
      session,
      finishPasswordResetToken: finishPasswordResetToken,
      newPassword: newPassword,
    );

    if (emailToSync != null && emailToSync.isNotEmpty) {
      await _syncLegacyEmailPassword(session, emailToSync, newPassword);
    }
  }

  Future<bool> _ensureIdpEmailAccount(Session session, String email) async {
    final existingAccount = await emailIdp.admin.findAccount(
      session,
      email: email,
    );
    if (existingAccount != null) {
      return false;
    }

    final student = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (student != null) {
      await _createMissingIdpAccount(
        session,
        email: email,
        name: student.name,
        defaultPassword: 'JMC-${student.studentNumber}',
        scope: AppScopes.student,
      );
      session.log(
        '[EmailIdp] Repaired student email auth account for $email',
      );
      return true;
    }

    final faculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (faculty == null) {
      return false;
    }

    final existingRole = await UserRole.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(faculty.userInfoId.toString()),
    );
    final repairedRole = _facultyRoleForReset(existingRole?.role);
    await _createMissingIdpAccount(
      session,
      email: email,
      name: faculty.name,
      defaultPassword: 'JMC-${faculty.facultyId}',
      scope: _scopeForRole(repairedRole),
    );
    session.log(
      '[EmailIdp] Repaired $repairedRole email auth account for $email',
    );
    return true;
  }

  Future<void> _createMissingIdpAccount(
    Session session, {
    required String email,
    required String name,
    required String defaultPassword,
    required Scope scope,
  }) async {
    final profiles = await const auth_core.UserProfiles().admin.listUserProfiles(
      session,
      email: email,
      limit: 1,
    );

    late final UuidValue authUserId;

    if (profiles.isNotEmpty) {
      final existingProfile = profiles.first;
      authUserId = existingProfile.authUserId;

      final authUser = await const auth_core.AuthUsers().get(
        session,
        authUserId: authUserId,
      );
      final updatedScopes = {
        ...authUser.scopeNames.map(Scope.new),
        scope,
      };
      await const auth_core.AuthUsers().update(
        session,
        authUserId: authUserId,
        scopes: updatedScopes,
      );
    } else {
      final createdUser = await const auth_core.AuthUsers().create(
        session,
        scopes: {scope},
      );
      authUserId = createdUser.id;
      await const auth_core.UserProfiles().createUserProfile(
        session,
        authUserId,
        auth_core.UserProfileData(
          userName: _deriveUserName(name, email),
          fullName: name.trim(),
          email: email,
        ),
      );
    }

    await emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: authUserId,
      email: email,
      password: defaultPassword,
    );
  }

  Future<void> _syncLegacyEmailPassword(
    Session session,
    String email,
    String newPassword,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    final newHash = await defaultGeneratePasswordHash(newPassword);

    var existingAuth = await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );

    if (existingAuth != null) {
      existingAuth
        ..email = normalizedEmail
        ..hash = newHash;
      await EmailAuth.db.updateRow(session, existingAuth);
      session.log(
        '[EmailIdp] Synced legacy email auth password for $normalizedEmail',
      );
      return;
    }

    final userInfoId = await _findLegacyUserInfoId(session, normalizedEmail);
    if (userInfoId == null) {
      session.log(
        '[EmailIdp] Skipped legacy password sync for $normalizedEmail because no legacy user was found',
      );
      return;
    }

    await EmailAuth.db.insertRow(
      session,
      EmailAuth(
        userId: userInfoId,
        email: normalizedEmail,
        hash: newHash,
      ),
    );
    session.log(
      '[EmailIdp] Created legacy email auth password for $normalizedEmail',
    );
  }

  Future<int?> _findLegacyUserInfoId(Session session, String email) async {
    final directUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (directUserInfo?.id != null) {
      return directUserInfo!.id;
    }

    final student = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (student?.userInfoId != null) {
      return student!.userInfoId;
    }

    final faculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    return faculty?.userInfoId;
  }

  UuidValue? _extractResetRequestId(String finishPasswordResetToken) {
    try {
      final decoded = utf8.decode(base64Decode(finishPasswordResetToken));
      final parts = decoded.split(':');
      if (parts.length != 2) return null;
      return UuidValue.withValidation(parts.first);
    } catch (_) {
      return null;
    }
  }

  Scope _scopeForRole(String role) {
    switch (role) {
      case 'admin':
        return AppScopes.admin;
      case 'faculty_pending':
      case 'faculty_declined':
      case 'faculty':
        return Scope(role);
      default:
        return AppScopes.faculty;
    }
  }

  String _deriveUserName(String name, String email) {
    final normalizedName = name.trim();
    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? email : localPart;
  }

  String _facultyRoleForReset(String? currentRole) {
    final normalized = currentRole?.trim().toLowerCase();
    if (normalized == 'admin' ||
        normalized == 'faculty_pending' ||
        normalized == 'faculty_declined') {
      return normalized!;
    }
    return 'faculty';
  }
}
