import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';

class SetupEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<UserInfo?> _ensureUserInfo(
    Session session, {
    required String userName,
    required String email,
    required String password,
  }) async {
    var userInfo = await Emails.createUser(
      session,
      userName,
      email,
      password,
    );
    if (userInfo != null) return userInfo;

    session.log('User $email might already exist. Trying to update scopes...');
    userInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (userInfo == null) {
      session.log(
        'Failed to find user $email even though createUser returned null.',
      );
    }
    return userInfo;
  }

  Future<void> _ensureEmailAuth(
    Session session,
    UserInfo userInfo, {
    required String email,
    required String password,
  }) async {
    final emailLower = email.toLowerCase();
    final newHash = await defaultGeneratePasswordHash(password);
    EmailAuth? existingAuth = await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userInfo.id!),
    );
    existingAuth ??= await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.email.equals(emailLower),
    );
    if (existingAuth == null) {
      await EmailAuth.db.insertRow(
        session,
        EmailAuth(
          userId: userInfo.id!,
          email: emailLower,
          hash: newHash,
        ),
      );
    } else {
      existingAuth.email = emailLower;
      existingAuth.hash = newHash;
      await EmailAuth.db.updateRow(session, existingAuth);
    }
  }

  Future<void> _syncRoleScope(
    Session session,
    UserInfo userInfo, {
    required String role,
  }) async {
    final currentScopes = userInfo.scopeNames.toSet();
    if (currentScopes.contains(role)) return;
    currentScopes.add(role);
    userInfo.scopeNames = currentScopes.toList();
    await UserInfo.db.updateRow(session, userInfo);
  }

  Future<int?> _resolveSectionId(
    Session session, {
    required String section,
  }) async {
    try {
      final existingSection = await Section.db.findFirstRow(
        session,
        where: (t) => t.sectionCode.equals(section),
      );
      if (existingSection != null) return existingSection.id;

      var prog = Program.it;
      var year = 1;
      if (section.toUpperCase().contains('EMC')) {
        prog = Program.emc;
      }
      final yearMatch = RegExp(r'\d').firstMatch(section);
      if (yearMatch != null) {
        year = int.parse(yearMatch.group(0)!);
      }

      final newSection = await Section.db.insertRow(
        session,
        Section(
          sectionCode: section,
          program: prog,
          yearLevel: year,
          semester: 1,
          academicYear: '${DateTime.now().year}-${DateTime.now().year + 1}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return newSection.id;
    } catch (e) {
      session.log('Error syncing section: $e');
      return null;
    }
  }

  Future<void> _ensureStudentProfile(
    Session session,
    UserInfo userInfo, {
    required String userName,
    required String email,
    required String studentId,
    required String? section,
  }) async {
    final existingStudent = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (existingStudent != null) return;

    int? sectionId;
    if (section != null && section.isNotEmpty) {
      sectionId = await _resolveSectionId(session, section: section);
    }

    await Student.db.insertRow(
      session,
      Student(
        name: userName,
        email: email,
        studentNumber: studentId,
        course: 'BSIT',
        yearLevel: 1,
        section: section,
        sectionId: sectionId,
        userInfoId: userInfo.id!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _ensureFacultyProfile(
    Session session,
    UserInfo userInfo, {
    required String userName,
    required String email,
    required String facultyId,
  }) async {
    final existingFaculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (existingFaculty != null) return;

    await Faculty.db.insertRow(
      session,
      Faculty(
        name: userName,
        email: email,
        maxLoad: 18,
        employmentStatus: EmploymentStatus.fullTime,
        shiftPreference: FacultyShiftPreference.any,
        facultyId: facultyId,
        userInfoId: userInfo.id!,
        program: Program.it, // Default
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _ensureUserRole(
    Session session,
    UserInfo userInfo, {
    required String role,
  }) async {
    final userIdStr = userInfo.id!.toString();
    final existingRole = await UserRole.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userIdStr),
    );

    if (existingRole == null) {
      await UserRole.db.insertRow(
        session,
        UserRole(
          userId: userIdStr,
          role: role,
        ),
      );
    } else if (existingRole.role != role) {
      existingRole.role = role;
      await UserRole.db.updateRow(session, existingRole);
    }
  }

  Future<bool> createAccount(
    Session session, {
    required String userName,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? facultyId,
    String? section,
  }) async {
    try {
      final userInfo = await _ensureUserInfo(
        session,
        userName: userName,
        email: email,
        password: password,
      );
      if (userInfo == null) return false;

      await _ensureEmailAuth(
        session,
        userInfo,
        email: email,
        password: password,
      );
      await _syncRoleScope(session, userInfo, role: role);

      // Create linked profile based on role
      if (role == 'student' && studentId != null) {
        await _ensureStudentProfile(
          session,
          userInfo,
          userName: userName,
          email: email,
          studentId: studentId,
          section: section,
        );
      } else if ((role == 'faculty' || role == 'admin') && facultyId != null) {
        await _ensureFacultyProfile(
          session,
          userInfo,
          userName: userName,
          email: email,
          facultyId: facultyId,
        );
      }

      // Add UserRole entry to ensure authenticationHandler picks it up
      await _ensureUserRole(session, userInfo, role: role);

      session.log(
        'Created user $email with role $role and ID ${studentId ?? facultyId}',
      );
      return true;
    } catch (e) {
      session.log('Error creating user: $e');
      return false;
    }
  }

  /// Fetches a UserInfo by email (case-insensitive).
  Future<UserInfo?> getUserInfoByEmail(
    Session session, {
    required String email,
  }) async {
    final emailLower = email.toLowerCase();
    return await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(emailLower),
    );
  }
}
