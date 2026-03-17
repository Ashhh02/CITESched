import 'package:citesched_server/src/generated/day_of_week.dart';
import 'package:citesched_server/src/generated/employment_status.dart';
import 'package:citesched_server/src/generated/faculty_shift_preference.dart';
import 'package:citesched_server/src/generated/nlp_intent.dart';
import 'package:citesched_server/src/generated/program.dart';
import 'package:citesched_server/src/generated/subject_type.dart';
import 'package:test/test.dart';

void main() {
  test('generated enums support fromJson and toJson', () {
    expect(EmploymentStatus.fromJson('fullTime'), EmploymentStatus.fullTime);
    expect(EmploymentStatus.partTime.toJson(), 'partTime');

    expect(Program.fromJson('it'), Program.it);
    expect(Program.emc.toJson(), 'emc');

    expect(DayOfWeek.fromJson('mon'), DayOfWeek.mon);
    expect(DayOfWeek.sat.toJson(), 'sat');

    expect(
      FacultyShiftPreference.fromJson('morning'),
      FacultyShiftPreference.morning,
    );
    expect(FacultyShiftPreference.evening.toJson(), 'evening');

    expect(NLPIntent.fromJson('schedule'), NLPIntent.schedule);
    expect(NLPIntent.unknown.toJson(), 'unknown');

    expect(SubjectType.fromJson('lecture'), SubjectType.lecture);
    expect(SubjectType.blended.toJson(), 'blended');
  });
}
