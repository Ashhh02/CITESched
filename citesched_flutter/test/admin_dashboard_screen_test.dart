import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/screens/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardStatsProvider.overrideWith((ref) async => stats),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Scheduled Classes'), findsOneWidget);
    expect(find.text('Active Users'), findsOneWidget);
    expect(find.text('Total Subjects'), findsOneWidget);
    expect(find.text('Total Rooms'), findsOneWidget);
  });
}
