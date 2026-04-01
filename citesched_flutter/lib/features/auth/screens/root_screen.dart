import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/screens/login_screen.dart';
import 'package:citesched_flutter/features/faculty/screens/faculty_dashboard_screen.dart';
import 'package:citesched_flutter/features/student/screens/student_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final selectedRole = authNotifier.selectedRole;

    if (authState == null) {
      return const LoginScreen();
    }

    if (selectedRole != null) {
      if (selectedRole == 'admin' && authNotifier.isAdmin) {
        return const AdminLayout();
      }
      if (selectedRole == 'student' && authNotifier.isStudent) {
        return const StudentDashboardScreen();
      }
      if (selectedRole == 'faculty' && authNotifier.isFaculty) {
        return const FacultyDashboardScreen();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        authNotifier.setSelectedRole(null);
      });
    }

    if (authNotifier.isAdmin) {
      return const AdminLayout();
    }

    if (authNotifier.isStudent) {
      return const StudentDashboardScreen();
    }

    if (authNotifier.isFaculty) {
      return const FacultyDashboardScreen();
    }

    if (authNotifier.needsRoleOnboarding) {
      return const LoginScreen();
    }

    return const LoginScreen();
  }
}
