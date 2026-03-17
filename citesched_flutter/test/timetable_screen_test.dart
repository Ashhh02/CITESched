import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/screens/timetable_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Timetable screen renders header and summary', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    final summary = TimetableSummary(
      totalSubjects: 0,
      totalUnits: 0,
      totalWeeklyHours: 0,
      conflictCount: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredSchedulesProvider.overrideWith((ref) async => <ScheduleInfo>[]),
          timetableSummaryProvider.overrideWith((ref) async => summary),
        ],
        child: MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: const TextScaler.linear(0.85),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const TimetableScreen(
            initialMetadata: TimetableMetadata(
              facultyList: [],
              roomList: [],
            ),
            skipMetadataLoad: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Weekly Timetable'), findsWidgets);
    expect(find.text('GENERATE AI SCHEDULE'), findsOneWidget);
  });
}
