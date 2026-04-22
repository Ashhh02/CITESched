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
            facultyId: 'F001',
            userInfoId: 1,
            name: 'Dr. Test',
            email: 'test@university.edu',
            program: Program.it,
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
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
              facultyId: 'F002',
              userInfoId: 2,
              name: 'Dr. Invalid',
              email: 'invalid-email',
              program: Program.it,
              maxLoad: 5,
              employmentStatus: EmploymentStatus.fullTime,
              isActive: true,
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
              facultyId: 'F003',
              userInfoId: 3,
              name: 'Dr. Zero',
              email: 'zero@test.com',
              program: Program.it,
              maxLoad: 0,
              employmentStatus: EmploymentStatus.fullTime,
              isActive: true,
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
            program: Program.it,
            isActive: true,
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
              program: Program.it,
              isActive: true,
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
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(subject.id, isNotNull);
        expect(subject.code, 'CS101');
      });

      test('Create subject with duplicate code fails', () async {
        await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'CS101',
            name: 'Introduction to Programming',
            units: 3,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () async => await endpoints.admin.createSubject(
            sessionBuilder,
            Subject(
              code: ' cs101 ',
              name: 'Another Intro Subject',
              units: 3,
              types: [SubjectType.laboratory],
              program: Program.it,
              studentsCount: 30,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Create subject with empty code fails', () async {
        expect(
          () async => await endpoints.admin.createSubject(
            sessionBuilder,
            Subject(
              code: '',
              name: 'Test Subject',
              units: 3,
              types: [SubjectType.lecture],
              program: Program.it,
              studentsCount: 30,
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
              units: 0,
              types: [SubjectType.lecture],
              program: Program.it,
              studentsCount: 30,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Update subject with duplicate code fails', () async {
        await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'UPD101',
            name: 'Original Subject',
            units: 3,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final otherSubject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'UPD102',
            name: 'Second Subject',
            units: 3,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () async => await endpoints.admin.updateSubject(
            sessionBuilder,
            otherSubject.copyWith(code: ' upd101 ', updatedAt: DateTime.now()),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Archive subject keeps inactive assigned faculty', () async {
        final faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'F-SUB-001',
            userInfoId: 10,
            name: 'Prof. Subject Archive',
            email: 'subject.archive@test.com',
            program: Program.it,
            maxLoad: 12,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final subject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'ARCH101',
            name: 'Archivable Subject',
            units: 3,
            facultyId: faculty.id,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await endpoints.admin.updateFaculty(
          sessionBuilder,
          faculty.copyWith(isActive: false, updatedAt: DateTime.now()),
        );

        final archived = await endpoints.admin.updateSubject(
          sessionBuilder,
          subject.copyWith(isActive: false, updatedAt: DateTime.now()),
        );

        expect(archived.isActive, isFalse);
        expect(archived.facultyId, faculty.id);
      });

      test('Archive subject with legacy duplicate code still succeeds', () async {
        final first = await Subject.db.insertRow(
          sessionBuilder,
          Subject(
            code: 'IT 101',
            name: 'Legacy Duplicate A',
            units: 3,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final second = await Subject.db.insertRow(
          sessionBuilder,
          Subject(
            code: 'IT 101',
            name: 'Legacy Duplicate B',
            units: 3,
            types: [SubjectType.laboratory],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final archived = await endpoints.admin.updateSubject(
          sessionBuilder,
          first.copyWith(isActive: false, updatedAt: DateTime.now()),
        );

        expect(archived.isActive, isFalse);
        expect(second.isActive, isTrue);
      });

      test('Archive subject with missing faculty still succeeds', () async {
        final faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'F-SUB-002',
            userInfoId: 11,
            name: 'Prof. Missing Faculty',
            email: 'missing.faculty@test.com',
            program: Program.it,
            maxLoad: 12,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final subject = await endpoints.admin.createSubject(
          sessionBuilder,
          Subject(
            code: 'MISS101',
            name: 'Subject With Missing Faculty',
            units: 3,
            facultyId: faculty.id,
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final deleted = await endpoints.admin.deleteFaculty(
          sessionBuilder,
          faculty.id!,
        );
        expect(deleted, isTrue);

        final archived = await endpoints.admin.updateSubject(
          sessionBuilder,
          subject.copyWith(isActive: false, updatedAt: DateTime.now()),
        );

        expect(archived.isActive, isFalse);
        expect(archived.facultyId, faculty.id);
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
            facultyId: 'F004',
            userInfoId: 4,
            name: 'Dr. Busy',
            email: 'busy@test.com',
            program: Program.it,
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
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
            program: Program.it,
            isActive: true,
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
            types: [SubjectType.lecture],
            program: Program.it,
            studentsCount: 30,
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

    group('Faculty update validation -', () {
      test('Update faculty with duplicate faculty ID fails', () async {
        final first = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'FAC-100',
            userInfoId: 100,
            name: 'Faculty One',
            email: 'faculty.one@test.com',
            program: Program.it,
            maxLoad: 12,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final second = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            facultyId: 'FAC-200',
            userInfoId: 101,
            name: 'Faculty Two',
            email: 'faculty.two@test.com',
            program: Program.it,
            maxLoad: 12,
            employmentStatus: EmploymentStatus.fullTime,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () async => await endpoints.admin.updateFaculty(
            sessionBuilder,
            second.copyWith(
              facultyId: first.facultyId,
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
