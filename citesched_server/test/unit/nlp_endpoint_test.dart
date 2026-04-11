import 'package:citesched_server/src/generated/protocol.dart';
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

    Future<void> seedScheduleData() async {
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
          name: 'Room NLP 1',
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
          units: 3,
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
          endTime: '09:00',
          label: 'Morning Slot',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final lateTimeslot = await endpoints.admin.createTimeslot(
        sessionBuilder,
        Timeslot(
          day: today,
          startTime: '23:50',
          endTime: '23:59',
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
    }

    test('returns schedule matches for authenticated student queries', () async {
      await seedScheduleData();

      final studentSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '901',
          {const Scope('student')},
        ),
      );

      final startResponse = await endpoints.nLP.query(
        studentSession,
        'schedule today start at 8:00',
      );
      expect(startResponse.intent, NLPIntent.schedule);
      expect(startResponse.text, contains('Found 1 class'));
      expect(startResponse.schedules, isNotNull);
      expect(startResponse.schedules!, isNotEmpty);

      final endResponse = await endpoints.nLP.query(
        studentSession,
        'schedule today end at 9:00',
      );
      expect(endResponse.intent, NLPIntent.schedule);
      expect(endResponse.text, contains('Found 1 class'));
      expect(endResponse.schedules, isNotNull);
      expect(endResponse.schedules!, isNotEmpty);

      final firstResponse = await endpoints.nLP.query(
        studentSession,
        'first class today',
      );
      expect(firstResponse.intent, NLPIntent.schedule);
      expect(firstResponse.text, contains('first class'));
      expect(firstResponse.schedules, isNotNull);
      expect(firstResponse.schedules!, isNotEmpty);

      final lastResponse = await endpoints.nLP.query(
        studentSession,
        'last class today',
      );
      expect(lastResponse.intent, NLPIntent.schedule);
      expect(lastResponse.text, contains('last class'));
      expect(lastResponse.schedules, isNotNull);
      expect(lastResponse.schedules!, isNotEmpty);

      final genericResponse = await endpoints.nLP.query(
        studentSession,
        'schedule today',
      );
      expect(genericResponse.intent, NLPIntent.schedule);
      expect(genericResponse.schedules, isNotNull);
      expect(genericResponse.schedules!, isNotEmpty);
    });

    test('returns next class using a fixed clock', () async {
      await seedScheduleData();

      final fixedNow = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        10,
      );
      final service = NLPService(nowProvider: () => fixedNow);
      final studentSession = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '901',
          {const Scope('student')},
        ),
      );

      final response = await service.processQuery(
        studentSession.build(),
        'next class today',
        '901',
        ['student'],
      );

      expect(response.intent, NLPIntent.schedule);
      expect(response.text, contains('next class'));
      expect(response.schedules, isNotNull);
      expect(response.schedules!, isNotEmpty);
    });
  });
}
