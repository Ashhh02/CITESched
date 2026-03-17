import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/screens/admin_dashboard_screen.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  UserInfo? build() => null;
}

DashboardStats _buildFakeStats() {
  return DashboardStats(
    totalSchedules: 12,
    totalFaculty: 5,
    totalStudents: 120,
    totalSubjects: 18,
    totalRooms: 9,
    totalConflicts: 0,
    facultyLoad: [
      FacultyLoadData(
        facultyName: 'Test Faculty',
        currentLoad: 9,
        maxLoad: 15,
      ),
    ],
    recentConflicts: [],
    sectionDistribution: [
      DistributionData(label: 'A', count: 10),
    ],
    yearLevelDistribution: [
      DistributionData(label: '1st', count: 10),
    ],
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Admin dashboard renders stats cards', (tester) async {
    final stats = _buildFakeStats();
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuthNotifier.new),
          dashboardStatsProvider.overrideWith((ref) async => stats),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('SCHEDULED CLASSES'), findsOneWidget);
    expect(find.text('ACTIVE USERS'), findsOneWidget);
    expect(find.text('TOTAL SUBJECTS'), findsOneWidget);
    expect(find.text('TOTAL ROOMS'), findsOneWidget);
  });
}
