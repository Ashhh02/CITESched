import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Report screen renders header', (tester) async {
    final overview = ScheduleOverviewReport(
      totalSchedules: 0,
      schedulesByProgram: const {},
      schedulesByTerm: const {},
      activeTerm: null,
      academicYear: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          facultyLoadReportProvider
              .overrideWith((ref) async => <FacultyLoadReport>[]),
          roomUtilizationReportProvider
              .overrideWith((ref) async => <RoomUtilizationReport>[]),
          conflictSummaryReportProvider
              .overrideWith((ref) async => <ScheduleConflict>[]),
          scheduleOverviewReportProvider.overrideWith((ref) async => overview),
        ],
        child: const MaterialApp(
          home: ReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Analytical Reports'), findsWidgets);
  });
}
