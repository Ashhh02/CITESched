import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/utils/session_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

final authProvider = NotifierProvider<AuthNotifier, UserInfo?>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<UserInfo?> {
  String? _selectedRole;
  bool _needsRoleOnboarding = false;

  bool _isLegacySession(AuthSuccess? authInfo) {
    final token = authInfo?.token.trim();
    if (token == null || token.isEmpty) return false;
    return RegExp(r'^\d+:').hasMatch(token);
  }

  bool _isGoogleSession(AuthSuccess? authInfo) {
    final strategy = authInfo?.authStrategy.trim().toLowerCase();
    return strategy == 'google';
  }

  @override
  UserInfo? build() {
    // Initialize auth listener
    _init();
    return null; // Initial state
  }

  Future<void> _init() async {
    // Add listener to auth state changes
    client.auth.authInfoListenable.addListener(_onAuthStateChanged);

    // Check initial state
    if (client.auth.isAuthenticated) {
      await _refreshCurrentUser();
    }
  }

  Future<void> _refreshCurrentUser() async {
    try {
      final sessionContext = await fetchSessionContext();
      final email = sessionContext.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        // Keep existing signed-in state if backend debug lookup is temporarily
        // unavailable (prevents unexpected auto-logout loops).
        if (state != null) return;
        _needsRoleOnboarding = true;
        state = null;
        return;
      }

      final userInfo = await client.setup.getUserInfoByEmail(email: email);
      if (userInfo == null) {
        if (state != null) return;
        _needsRoleOnboarding = true;
        state = null;
        return;
      }

      final existingRole = await client.setup.getExistingAccountRoleByEmail(
        email: email,
      );
      final normalizedRole = existingRole?.trim().toLowerCase();
      final isAdminAccount =
          userInfo.scopeNames.contains('admin') || normalizedRole == 'admin';

      // Keep Google-authenticated users in onboarding if their email no
      // longer maps to an active student / faculty profile.
      if (!isAdminAccount &&
          (normalizedRole != 'student' && normalizedRole != 'faculty')) {
        _needsRoleOnboarding = true;
        state = null;
        return;
      }

      _needsRoleOnboarding = false;
      state = userInfo;
    } catch (e) {
      debugPrint('Failed to fetch user info: $e');
      // Fail-safe: don't destroy existing auth state on transient backend
      // errors (for example /debug temporary 500).
      if (state != null) return;
      _needsRoleOnboarding = true;
      state = null;
    }
  }

  void _onAuthStateChanged() {
    if (!client.auth.isAuthenticated) {
      _selectedRole = null;
      _needsRoleOnboarding = false;
      state = null;
      return;
    }

    _refreshCurrentUser();
  }

  Future<void> refreshCurrentUser() async {
    await _refreshCurrentUser();
  }

  // Method to manually update user info (e.g., after custom login)
  void updateUserInfo(UserInfo? userInfo) {
    _needsRoleOnboarding = false;
    state = userInfo;
  }

  void setSelectedRole(String? role) {
    _selectedRole = role;
  }

  String? get selectedRole => _selectedRole;

  Future<void> signOut() async {
    final authInfo = client.auth.authInfo;
    try {
      if (_isGoogleSession(authInfo)) {
        await client.auth.disconnectGoogleAccount();
      } else if (_isLegacySession(authInfo)) {
        await client.auth.updateSignedInUser(null);
      } else {
        await client.auth.signOutDevice();
      }
    } catch (_) {
      await client.auth.updateSignedInUser(null);
    }
    _selectedRole = null;
    _needsRoleOnboarding = false;
    state = null;
  }

  bool get isSignedIn => state != null;
  bool get hasActiveSession => client.auth.isAuthenticated;
  bool get needsRoleOnboarding => _needsRoleOnboarding;

  // Helper to check roles (can be expanded later)
  bool get isAdmin => state?.scopeNames.contains('admin') ?? false;
  bool get isFaculty => state?.scopeNames.contains('faculty') ?? false;
  bool get isStudent => state?.scopeNames.contains('student') ?? false;

  // We don't need override dispose in Notifier,
  // currently we can't easily remove listener on dispose in Notifier
  // without using ref.onDispose, but referencing methods is tricky.
  // For a singleton auth provider, it effectively lives as long as the app.
}
