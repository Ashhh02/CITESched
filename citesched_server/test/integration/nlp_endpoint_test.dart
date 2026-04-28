import 'package:citesched_server/src/generated/protocol.dart';
import 'package:citesched_server/src/auth/scopes.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given NLP Endpoint', (sessionBuilder, endpoints) {
    Future<void> seedScheduleData() async {
      final faculty = await endpoints.admin.createFaculty(
        sessionBuilder,
        Faculty(
          facultyId: 'F900',
          userInfoId: 900,
          name: 'Dr. NLP Test',
          email: 'nlp@test.com',
          program: Program.it,
          maxLoad: 5,
          employmentStatus: EmploymentStatus.fullTime,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await endpoints.admin.createStudent(
        sessionBuilder,
        Student(
          name: 'NLP Student',
          email: 'student@test.com',
          studentNumber: '2024-0001',
          course: 'BSIT',
          yearLevel: 2,
          section: 'A',
          userInfoId: 901,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final room = await endpoints.admin.createRoom(
        sessionBuilder,
        Room(
          name: 'ROOM 1',
          capacity: 30,
          type: RoomType.lecture,
          program: Program.it,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final subject = await endpoints.admin.createSubject(
        sessionBuilder,
        Subject(
          code: 'NLP101',
          name: 'Natural Language Processing',
          hours: 1,
          units: 3,
          types: [SubjectType.lecture],
          program: Program.it,
          studentsCount: 30,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final timeslot = await endpoints.admin.createTimeslot(
        sessionBuilder,
        Timeslot(
          day: DayOfWeek.mon,
          startTime: '08:00',
          endTime: '09:00',
          label: 'Morning Slot',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await endpoints.admin.createSchedule(
        sessionBuilder,
        Schedule(
          subjectId: subject.id!,
          facultyId: faculty.id!,
          roomId: room.id!,
          timeslotId: timeslot.id!,
          section: 'A',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    test('rejects unauthenticated query', () async {
      final response = await endpoints.nLP.query(
        sessionBuilder,
        'schedule monday',
      );

      expect(response.intent, NLPIntent.unknown);
      expect(response.text, contains('Authentication required'));
    });

    test(
      'returns schedule matches for authenticated student queries',
      () async {
        await seedScheduleData();

        final studentSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'student@test.com',
            {AppScopes.student},
          ),
        );

        final startResponse = await endpoints.nLP.query(
          studentSession,
          'my schedule on monday start at 8:00',
        );
        expect(startResponse.intent, NLPIntent.schedule);
        expect(startResponse.text, contains('1 class'));
        expect(startResponse.schedules, isNotNull);
        expect(startResponse.schedules!, isNotEmpty);

        final endResponse = await endpoints.nLP.query(
          studentSession,
          'my schedule on monday end at 9:00',
        );
        expect(endResponse.intent, NLPIntent.schedule);
        expect(endResponse.text, contains('1 class'));
        expect(endResponse.schedules, isNotNull);
        expect(endResponse.schedules!, isNotEmpty);
      },
    );
  });
}
