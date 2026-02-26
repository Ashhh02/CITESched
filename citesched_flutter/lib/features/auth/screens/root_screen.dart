import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/screens/login_screen.dart';
import 'package:citesched_flutter/features/student/screens/student_dashboard_screen.dart';
import 'package:citesched_flutter/features/faculty/screens/faculty_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // If not signed in, show login
    if (authState == null) {
      return const LoginScreen();
    }

    // Route to specific role dashboards
    if (authNotifier.isAdmin) {
      return const AdminLayout();
    }

    if (authNotifier.isStudent) {
      return const StudentDashboardScreen();
    }

    if (authNotifier.isFaculty) {
      return const FacultyDashboardScreen();
    }

    // Unknown role — sign out and return to login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authNotifier.signOut();
    });
    return const LoginScreen();
  }
}
