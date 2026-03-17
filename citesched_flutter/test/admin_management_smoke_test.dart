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

Widget _wrapWithOverrides({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

List<Override> _baseOverrides() {
  return [
    allConflictsProvider.overrideWith((ref) async => <ScheduleConflict>[]),
  ];
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Subject management screen renders header', (tester) async {
    await tester.pumpWidget(
      _wrapWithOverrides(
        child: const SubjectManagementScreen(),
        overrides: [
          ..._baseOverrides(),
          subjectsProvider.overrideWith((ref) async => <Subject>[]),
          archivedSubjectsProvider.overrideWith((ref) async => <Subject>[]),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Subject Management'), findsWidgets);
  });

  testWidgets('Room management screen renders header', (tester) async {
    await tester.pumpWidget(
      _wrapWithOverrides(
        child: const RoomManagementScreen(),
        overrides: [
          ..._baseOverrides(),
          roomListProvider.overrideWith((ref) async => <Room>[]),
          archivedRoomListProvider.overrideWith((ref) async => <Room>[]),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Room Management'), findsWidgets);
  });

  testWidgets('Faculty management screen renders header', (tester) async {
    await tester.pumpWidget(
      _wrapWithOverrides(
        child: const FacultyManagementScreen(),
        overrides: [
          ..._baseOverrides(),
          facultyListProvider.overrideWith((ref) async => <Faculty>[]),
          archivedFacultyListProvider.overrideWith((ref) async => <Faculty>[]),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Faculty Management'), findsWidgets);
  });

  testWidgets('User management screen renders header', (tester) async {
    await tester.pumpWidget(
      _wrapWithOverrides(
        child: const UserManagementScreen(),
        overrides: [
          ..._baseOverrides(),
          studentsProvider.overrideWith((ref) async => <Student>[]),
          archivedStudentsProvider.overrideWith((ref) async => <Student>[]),
          sectionListProvider.overrideWith((ref) async => <Section>[]),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('User Management'), findsWidgets);
  });
}
