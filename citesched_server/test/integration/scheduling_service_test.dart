import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'package:citesched_server/src/generated/protocol.dart';

void main() {
  withServerpod('Given SchedulingService', (sessionBuilder, endpoints) {
    group('Conflict Detection -', () {
      test('Room availability - detects double booking', () async {
        // Create test data
        var faculty1 = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            name: 'Dr. Smith',
            email: 'smith@test.com',
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
            name: 'Room 101',
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
            code: 'CS101',
            name: 'Intro to CS',
            units: 3,
            type: SubjectType.lecture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

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

        // Create first schedule
        var schedule1 = await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: subject.id!,
            facultyId: faculty1.id!,
            roomId: room.id!,
            timeslotId: timeslot.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(schedule1.id, isNotNull);

        // Try to create conflicting schedule (same room, same timeslot)
        expect(
          () async => await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty1.id!,
              roomId: room.id!, // Same room
              timeslotId: timeslot.id!, // Same timeslot
              section: 'B',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Faculty availability - detects overlapping schedules', () async {
        // Create test data
        var faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            name: 'Dr. Jones',
            email: 'jones@test.com',
            department: 'Math',
            maxLoad: 5,
            employmentStatus: EmploymentStatus.fullTime,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room1 = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'Room 201',
            capacity: 30,
            type: RoomType.lecture,
            building: 'Main',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room2 = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'Room 202',
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
            code: 'MATH101',
            name: 'Calculus I',
            units: 3,
            type: SubjectType.lecture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.tue,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Period 3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create first schedule
        await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: subject.id!,
            facultyId: faculty.id!,
            roomId: room1.id!,
            timeslotId: timeslot.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Try to assign same faculty to different room at same time
        expect(
          () async => await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!, // Same faculty
              roomId: room2.id!, // Different room
              timeslotId: timeslot.id!, // Same timeslot
              section: 'B',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('Faculty max load - prevents exceeding limit', () async {
        // Create faculty with low max load
        var faculty = await endpoints.admin.createFaculty(
          sessionBuilder,
          Faculty(
            name: 'Dr. Limited',
            email: 'limited@test.com',
            department: 'CS',
            maxLoad: 1, // Only 1 class allowed
            employmentStatus: EmploymentStatus.partTime,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var room = await endpoints.admin.createRoom(
          sessionBuilder,
          Room(
            name: 'Room 301',
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
            code: 'CS201',
            name: 'Data Structures',
            units: 3,
            type: SubjectType.lecture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot1 = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.wed,
            startTime: '08:00',
            endTime: '09:00',
            label: 'Period 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        var timeslot2 = await endpoints.admin.createTimeslot(
          sessionBuilder,
          Timeslot(
            day: DayOfWeek.wed,
            startTime: '10:00',
            endTime: '11:00',
            label: 'Period 3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create first schedule (should succeed)
        await endpoints.admin.createSchedule(
          sessionBuilder,
          Schedule(
            subjectId: subject.id!,
            facultyId: faculty.id!,
            roomId: room.id!,
            timeslotId: timeslot1.id!,
            section: 'A',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Try to create second schedule (should fail - exceeds max load)
        expect(
          () async => await endpoints.admin.createSchedule(
            sessionBuilder,
            Schedule(
              subjectId: subject.id!,
              facultyId: faculty.id!,
              roomId: room.id!,
              timeslotId: timeslot2.id!, // Different timeslot
              section: 'B',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
