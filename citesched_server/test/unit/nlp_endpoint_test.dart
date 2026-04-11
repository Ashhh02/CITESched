import 'package:citesched_server/src/generated/protocol.dart';
import 'package:citesched_server/src/auth/scopes.dart';
import 'package:citesched_server/src/services/nlp_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given NLP Endpoint', (sessionBuilder, endpoints) {
    DayOfWeek _todayDay() {
      const days = <DayOfWeek>[
        DayOfWeek.mon,
        DayOfWeek.tue,
        DayOfWeek.wed,
        DayOfWeek.thu,
        DayOfWeek.fri,
        DayOfWeek.sat,
        DayOfWeek.sun,
      ];
      return days[DateTime.now().weekday - 1];
    }

    Future<Student> seedScheduleData() async {
      final today = _todayDay();
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

      final student = await endpoints.admin.createStudent(
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
          units: 2,
          types: [SubjectType.lecture],
          program: Program.it,
          studentsCount: 30,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final morningTimeslot = await endpoints.admin.createTimeslot(
        sessionBuilder,
        Timeslot(
          day: today,
          startTime: '08:00',
          endTime: '11:00',
          label: 'Morning Slot',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final lateTimeslot = await endpoints.admin.createTimeslot(
        sessionBuilder,
        Timeslot(
          day: today,
          startTime: '12:00',
          endTime: '15:00',
          label: 'Late Slot',
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
          timeslotId: morningTimeslot.id!,
          section: 'A',
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
          timeslotId: lateTimeslot.id!,
          section: 'B',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      return student;
    }

    test(
      'returns schedule matches for authenticated student queries',
      () async {
        final student = await seedScheduleData();

        final studentSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            student.userInfoId.toString(),
            {AppScopes.student},
          ),
        );

        final response = await endpoints.nLP.query(
          studentSession,
          'my schedule today',
        );
        expect(response.intent, NLPIntent.schedule);
        expect(response.text, contains('You have'));
        expect(response.schedules, isNotNull);
        expect(response.schedules!, isNotEmpty);
      },
    );

    test('returns next class using a fixed clock', () async {
      await seedScheduleData();

      final fixedNow = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        10,
      );
      final service = NLPService(nowProvider: () => fixedNow);

      final adminSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '1',
          {AppScopes.admin},
        ),
      );

      final response = await service.processQuery(
        adminSession.build(),
        'next class today',
        '1',
        ['admin'],
      );

      expect(response.intent, NLPIntent.schedule);
      expect(response.text, contains('next class'));
      expect(response.schedules, isNotNull);
      expect(response.schedules!, isNotEmpty);
    });
  });
}
//testing 