import 'package:test/test.dart';

// Import the generated test helper file, it contains everything you need.
import 'test_tools/serverpod_test_tools.dart';
import 'package:citesched_server/src/generated/protocol.dart';

void main() {
  withServerpod('Given Admin Endpoint CRUD Operations', (
    sessionBuilder,
    endpoints,
  ) {
    group('Faculty CRUD -', () {
      test('Create faculty with valid data succeeds', () async {
        var faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            name: 'Dr. Test',
            email: 'test@university.edu',
            department: 'Computer Science',
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(faculty.id, isNotNull);
        expect(faculty.email, 'test@university.edu');
      });

      test('Create faculty with invalid email fails', () async {
        expect(
          () async => await endpoints.admin.createFaculty(
            sessionBuilder,
            Faculty(
              name: 'Dr. Invalid',
              email: 'invalid-email', // Invalid format
              department: 'CS',
              maxLoad: 5,
              employmentStatus: EmploymentStatus.fullTime,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Create faculty with zero maxLoad fails', () async {
        expect(
          () async => await endpoints.admin.createFaculty(
            sessionBuilder,
            Faculty(
              name: 'Dr. Zero',
              email: 'zero@test.com',
              department: 'CS',
              maxLoad: 0, // Invalid
              employmentStatus: EmploymentStatus.fullTime,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Room CRUD -', () {
      test('Create room with valid data succeeds', () async {
        var room = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'Lab 101',
            capacity: 40,
            type: RoomType.laboratory,
            building: 'Science Building',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(room.id, isNotNull);
        expect(room.capacity, 40);
      });

      test('Create room with zero capacity fails', () async {
        expect(
          () async => await endpoints.admin.createRoom(
            sessionBuilder,
            Room(
              name: 'Invalid Room',
              capacity: 0, // Invalid
              type: RoomType.lecture,
              building: 'Main',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Subject CRUD -', () {
      test('Create subject with valid data succeeds', () async {
        var subject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'CS101',
            name: 'Introduction to Programming',
            units: 3,
            type: SubjectType.lecture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(subject.id, isNotNull);
        expect(subject.code, 'CS101');
      });

      test('Create subject with empty code fails', () async {
        expect(
          () async => await endpoints.admin.createSubject(
            sessionBuilder,
            Subject(
              code: '', // Invalid
              name: 'Test Subject',
              units: 3,
              type: SubjectType.lecture,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Create subject with zero units fails', () async {
        expect(
          () async => await endpoints.admin.createSubject(
            sessionBuilder,
            Subject(
              code: 'TEST101',
              name: 'Test Subject',
              units: 0, // Invalid
              type: SubjectType.lecture,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Timeslot CRUD -', () {
      test('Create timeslot with valid data succeeds', () async {
        var timeslot = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.mon,
            startTime: '08:00',
            endTime: '09:00',
            label: 'Period 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(timeslot.id, isNotNull);
        expect(timeslot.startTime, '08:00');
      });

      test('Create timeslot with invalid time format fails', () async {
        expect(
          () async => await endpoints.admin.createTimeslot(
            sessionBuilder,
            Timeslot(
              day: DayOfWeek.mon,
              startTime: '8:00 AM', // Invalid format
              endTime: '09:00',
              label: 'Period 1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Create timeslot with start after end fails', () async {
        expect(
          () async => await endpoints.admin.createTimeslot(
            sessionBuilder,
            Timeslot(
              day: DayOfWeek.mon,
              startTime: '10:00',
              endTime: '09:00', // End before start
              label: 'Invalid Period',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Deletion with Dependencies -', () {
      test('Cannot delete faculty with active schedules', () async {
        // Create faculty, room, subject, timeslot
        var faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            name: 'Dr. Busy',
            email: 'busy@test.com',
            department: 'CS',
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'Room 401',
            capacity: 30,
            type: RoomType.lecture,
            building: 'Main',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var subject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'CS301',
            name: 'Advanced Programming',
            units: 3,
            type: SubjectType.lecture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.fri,
            startTime: '14:00',
            endTime: '15:00',
            label: 'Period 7',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create schedule
        await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: subject.id!,
            facultyId: faculty.id!,
            roomId: room.id!,
            timeslotId: timeslot.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Try to delete faculty (should fail)
        expect(
          () async =>
              await endpoints.admin.deleteFaculty(sessionBuilder, faculty.id!),
          throwsA(isA<Exception>()),
        );

        // Try to delete room (should fail)
        expect(
          () async =>
              await endpoints.admin.deleteRoom(sessionBuilder, room.id!),
          throwsA(isA<Exception>()),
        );

        // Try to delete subject (should fail)
        expect(
          () async =>
              await endpoints.admin.deleteSubject(sessionBuilder, subject.id!),
          throwsA(isA<Exception>()),
        );

        // Try to delete timeslot (should fail)
        expect(
          () async => await endpoints.admin.deleteTimeslot(
            sessionBuilder,
            timeslot.id!,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
