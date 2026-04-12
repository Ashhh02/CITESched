import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/room_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/subject_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/user_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> setDesktopSurface(WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  testWidgets('Subject management screen renders header', (tester) async {
    await setDesktopSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allConflictsProvider.overrideWith((ref) async => <ScheduleConflict>[]),
          subjectsProvider.overrideWith((ref) async => <Subject>[]),
          archivedSubjectsProvider.overrideWith((ref) async => <Subject>[]),
        ],
        child: const MaterialApp(home: SubjectManagementScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Subject Management'), findsWidgets);
  });

  testWidgets('Room management screen renders header', (tester) async {
    await setDesktopSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allConflictsProvider.overrideWith((ref) async => <ScheduleConflict>[]),
          roomListProvider.overrideWith((ref) async => <Room>[]),
          archivedRoomListProvider.overrideWith((ref) async => <Room>[]),
        ],
        child: const MaterialApp(home: RoomManagementScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Room Management'), findsWidgets);
  });

  testWidgets('Faculty management screen renders header', (tester) async {
    await setDesktopSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allConflictsProvider.overrideWith((ref) async => <ScheduleConflict>[]),
          facultyListProvider.overrideWith((ref) async => <Faculty>[]),
          archivedFacultyListProvider.overrideWith((ref) async => <Faculty>[]),
        ],
        child: const MaterialApp(home: FacultyManagementScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Faculty Management'), findsWidgets);
  });

  testWidgets('User management screen renders header', (tester) async {
    await setDesktopSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allConflictsProvider.overrideWith((ref) async => <ScheduleConflict>[]),
          studentsProvider.overrideWith((ref) async => <Student>[]),
          archivedStudentsProvider.overrideWith((ref) async => <Student>[]),
          sectionListProvider.overrideWith((ref) async => <Section>[]),
        ],
        child: const MaterialApp(home: UserManagementScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('User Management'), findsWidgets);
  });
}
