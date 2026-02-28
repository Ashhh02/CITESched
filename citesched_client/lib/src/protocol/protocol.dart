/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dashboard_stats.dart' as _i2;
import 'day_of_week.dart' as _i3;
import 'distribution_data.dart' as _i4;
import 'employment_status.dart' as _i5;
import 'faculty.dart' as _i6;
import 'faculty_availability.dart' as _i7;
import 'faculty_load_data.dart' as _i8;
import 'faculty_shift_preference.dart' as _i9;
import 'generate_schedule_request.dart' as _i10;
import 'generate_schedule_response.dart' as _i11;
import 'greetings/greeting.dart' as _i12;
import 'nlp_intent.dart' as _i13;
import 'nlp_response.dart' as _i14;
import 'program.dart' as _i15;
import 'reports/conflict_summary_report.dart' as _i16;
import 'reports/faculty_load_report.dart' as _i17;
import 'reports/room_utilization_report.dart' as _i18;
import 'reports/schedule_overview_report.dart' as _i19;
import 'room.dart' as _i20;
import 'room_type.dart' as _i21;
import 'schedule.dart' as _i22;
import 'schedule_conflict.dart' as _i23;
import 'schedule_info.dart' as _i24;
import 'section.dart' as _i25;
import 'student.dart' as _i26;
import 'subject.dart' as _i27;
import 'subject_type.dart' as _i28;
import 'timeslot.dart' as _i29;
import 'timetable_filter_request.dart' as _i30;
import 'timetable_summary.dart' as _i31;
import 'user_role.dart' as _i32;
import 'package:citesched_client/src/protocol/user_role.dart' as _i33;
import 'package:citesched_client/src/protocol/faculty.dart' as _i34;
import 'package:citesched_client/src/protocol/student.dart' as _i35;
import 'package:citesched_client/src/protocol/room.dart' as _i36;
import 'package:citesched_client/src/protocol/subject.dart' as _i37;
import 'package:citesched_client/src/protocol/timeslot.dart' as _i38;
import 'package:citesched_client/src/protocol/schedule.dart' as _i39;
import 'package:citesched_client/src/protocol/schedule_conflict.dart' as _i40;
import 'package:citesched_client/src/protocol/reports/faculty_load_report.dart'
    as _i41;
import 'package:citesched_client/src/protocol/reports/room_utilization_report.dart'
    as _i42;
import 'package:citesched_client/src/protocol/section.dart' as _i43;
import 'package:citesched_client/src/protocol/faculty_availability.dart'
    as _i44;
import 'package:citesched_client/src/protocol/schedule_info.dart' as _i45;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i46;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i47;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i48;
export 'dashboard_stats.dart';
export 'day_of_week.dart';
export 'distribution_data.dart';
export 'employment_status.dart';
export 'faculty.dart';
export 'faculty_availability.dart';
export 'faculty_load_data.dart';
export 'faculty_shift_preference.dart';
export 'generate_schedule_request.dart';
export 'generate_schedule_response.dart';
export 'greetings/greeting.dart';
export 'nlp_intent.dart';
export 'nlp_response.dart';
export 'program.dart';
export 'reports/conflict_summary_report.dart';
export 'reports/faculty_load_report.dart';
export 'reports/room_utilization_report.dart';
export 'reports/schedule_overview_report.dart';
export 'room.dart';
export 'room_type.dart';
export 'schedule.dart';
export 'schedule_conflict.dart';
export 'schedule_info.dart';
export 'section.dart';
export 'student.dart';
export 'subject.dart';
export 'subject_type.dart';
export 'timeslot.dart';
export 'timetable_filter_request.dart';
export 'timetable_summary.dart';
export 'user_role.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.DashboardStats) {
      return _i2.DashboardStats.fromJson(data) as T;
    }
    if (t == _i3.DayOfWeek) {
      return _i3.DayOfWeek.fromJson(data) as T;
    }
    if (t == _i4.DistributionData) {
      return _i4.DistributionData.fromJson(data) as T;
    }
    if (t == _i5.EmploymentStatus) {
      return _i5.EmploymentStatus.fromJson(data) as T;
    }
    if (t == _i6.Faculty) {
      return _i6.Faculty.fromJson(data) as T;
    }
    if (t == _i7.FacultyAvailability) {
      return _i7.FacultyAvailability.fromJson(data) as T;
    }
    if (t == _i8.FacultyLoadData) {
      return _i8.FacultyLoadData.fromJson(data) as T;
    }
    if (t == _i9.FacultyShiftPreference) {
      return _i9.FacultyShiftPreference.fromJson(data) as T;
    }
    if (t == _i10.GenerateScheduleRequest) {
      return _i10.GenerateScheduleRequest.fromJson(data) as T;
    }
    if (t == _i11.GenerateScheduleResponse) {
      return _i11.GenerateScheduleResponse.fromJson(data) as T;
    }
    if (t == _i12.Greeting) {
      return _i12.Greeting.fromJson(data) as T;
    }
    if (t == _i13.NLPIntent) {
      return _i13.NLPIntent.fromJson(data) as T;
    }
    if (t == _i14.NLPResponse) {
      return _i14.NLPResponse.fromJson(data) as T;
    }
    if (t == _i15.Program) {
      return _i15.Program.fromJson(data) as T;
    }
    if (t == _i16.ConflictSummaryReport) {
      return _i16.ConflictSummaryReport.fromJson(data) as T;
    }
    if (t == _i17.FacultyLoadReport) {
      return _i17.FacultyLoadReport.fromJson(data) as T;
    }
    if (t == _i18.RoomUtilizationReport) {
      return _i18.RoomUtilizationReport.fromJson(data) as T;
    }
    if (t == _i19.ScheduleOverviewReport) {
      return _i19.ScheduleOverviewReport.fromJson(data) as T;
    }
    if (t == _i20.Room) {
      return _i20.Room.fromJson(data) as T;
    }
    if (t == _i21.RoomType) {
      return _i21.RoomType.fromJson(data) as T;
    }
    if (t == _i22.Schedule) {
      return _i22.Schedule.fromJson(data) as T;
    }
    if (t == _i23.ScheduleConflict) {
      return _i23.ScheduleConflict.fromJson(data) as T;
    }
    if (t == _i24.ScheduleInfo) {
      return _i24.ScheduleInfo.fromJson(data) as T;
    }
    if (t == _i25.Section) {
      return _i25.Section.fromJson(data) as T;
    }
    if (t == _i26.Student) {
      return _i26.Student.fromJson(data) as T;
    }
    if (t == _i27.Subject) {
      return _i27.Subject.fromJson(data) as T;
    }
    if (t == _i28.SubjectType) {
      return _i28.SubjectType.fromJson(data) as T;
    }
    if (t == _i29.Timeslot) {
      return _i29.Timeslot.fromJson(data) as T;
    }
    if (t == _i30.TimetableFilterRequest) {
      return _i30.TimetableFilterRequest.fromJson(data) as T;
    }
    if (t == _i31.TimetableSummary) {
      return _i31.TimetableSummary.fromJson(data) as T;
    }
    if (t == _i32.UserRole) {
      return _i32.UserRole.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.DashboardStats?>()) {
      return (data != null ? _i2.DashboardStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.DayOfWeek?>()) {
      return (data != null ? _i3.DayOfWeek.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.DistributionData?>()) {
      return (data != null ? _i4.DistributionData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.EmploymentStatus?>()) {
      return (data != null ? _i5.EmploymentStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Faculty?>()) {
      return (data != null ? _i6.Faculty.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.FacultyAvailability?>()) {
      return (data != null ? _i7.FacultyAvailability.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.FacultyLoadData?>()) {
      return (data != null ? _i8.FacultyLoadData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.FacultyShiftPreference?>()) {
      return (data != null ? _i9.FacultyShiftPreference.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.GenerateScheduleRequest?>()) {
      return (data != null ? _i10.GenerateScheduleRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.GenerateScheduleResponse?>()) {
      return (data != null
              ? _i11.GenerateScheduleResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i12.Greeting?>()) {
      return (data != null ? _i12.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.NLPIntent?>()) {
      return (data != null ? _i13.NLPIntent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.NLPResponse?>()) {
      return (data != null ? _i14.NLPResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.Program?>()) {
      return (data != null ? _i15.Program.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.ConflictSummaryReport?>()) {
      return (data != null ? _i16.ConflictSummaryReport.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.FacultyLoadReport?>()) {
      return (data != null ? _i17.FacultyLoadReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.RoomUtilizationReport?>()) {
      return (data != null ? _i18.RoomUtilizationReport.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.ScheduleOverviewReport?>()) {
      return (data != null ? _i19.ScheduleOverviewReport.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.Room?>()) {
      return (data != null ? _i20.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.RoomType?>()) {
      return (data != null ? _i21.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.Schedule?>()) {
      return (data != null ? _i22.Schedule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ScheduleConflict?>()) {
      return (data != null ? _i23.ScheduleConflict.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ScheduleInfo?>()) {
      return (data != null ? _i24.ScheduleInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.Section?>()) {
      return (data != null ? _i25.Section.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.Student?>()) {
      return (data != null ? _i26.Student.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.Subject?>()) {
      return (data != null ? _i27.Subject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.SubjectType?>()) {
      return (data != null ? _i28.SubjectType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.Timeslot?>()) {
      return (data != null ? _i29.Timeslot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.TimetableFilterRequest?>()) {
      return (data != null ? _i30.TimetableFilterRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.TimetableSummary?>()) {
      return (data != null ? _i31.TimetableSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.UserRole?>()) {
      return (data != null ? _i32.UserRole.fromJson(data) : null) as T;
    }
    if (t == List<_i8.FacultyLoadData>) {
      return (data as List)
              .map((e) => deserialize<_i8.FacultyLoadData>(e))
              .toList()
          as T;
    }
    if (t == List<_i23.ScheduleConflict>) {
      return (data as List)
              .map((e) => deserialize<_i23.ScheduleConflict>(e))
              .toList()
          as T;
    }
    if (t == List<_i4.DistributionData>) {
      return (data as List)
              .map((e) => deserialize<_i4.DistributionData>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i22.Schedule>) {
      return (data as List).map((e) => deserialize<_i22.Schedule>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i22.Schedule>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i22.Schedule>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i23.ScheduleConflict>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i23.ScheduleConflict>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i28.SubjectType>) {
      return (data as List)
              .map((e) => deserialize<_i28.SubjectType>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i28.SubjectType>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i28.SubjectType>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i33.UserRole>) {
      return (data as List).map((e) => deserialize<_i33.UserRole>(e)).toList()
          as T;
    }
    if (t == List<_i34.Faculty>) {
      return (data as List).map((e) => deserialize<_i34.Faculty>(e)).toList()
          as T;
    }
    if (t == List<_i35.Student>) {
      return (data as List).map((e) => deserialize<_i35.Student>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i36.Room>) {
      return (data as List).map((e) => deserialize<_i36.Room>(e)).toList() as T;
    }
    if (t == List<_i37.Subject>) {
      return (data as List).map((e) => deserialize<_i37.Subject>(e)).toList()
          as T;
    }
    if (t == List<_i38.Timeslot>) {
      return (data as List).map((e) => deserialize<_i38.Timeslot>(e)).toList()
          as T;
    }
    if (t == List<_i39.Schedule>) {
      return (data as List).map((e) => deserialize<_i39.Schedule>(e)).toList()
          as T;
    }
    if (t == List<_i40.ScheduleConflict>) {
      return (data as List)
              .map((e) => deserialize<_i40.ScheduleConflict>(e))
              .toList()
          as T;
    }
    if (t == List<_i41.FacultyLoadReport>) {
      return (data as List)
              .map((e) => deserialize<_i41.FacultyLoadReport>(e))
              .toList()
          as T;
    }
    if (t == List<_i42.RoomUtilizationReport>) {
      return (data as List)
              .map((e) => deserialize<_i42.RoomUtilizationReport>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.Section>) {
      return (data as List).map((e) => deserialize<_i43.Section>(e)).toList()
          as T;
    }
    if (t == List<_i44.FacultyAvailability>) {
      return (data as List)
              .map((e) => deserialize<_i44.FacultyAvailability>(e))
              .toList()
          as T;
    }
    if (t == List<_i45.ScheduleInfo>) {
      return (data as List)
              .map((e) => deserialize<_i45.ScheduleInfo>(e))
              .toList()
          as T;
    }
    try {
      return _i46.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i47.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i48.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.DashboardStats => 'DashboardStats',
      _i3.DayOfWeek => 'DayOfWeek',
      _i4.DistributionData => 'DistributionData',
      _i5.EmploymentStatus => 'EmploymentStatus',
      _i6.Faculty => 'Faculty',
      _i7.FacultyAvailability => 'FacultyAvailability',
      _i8.FacultyLoadData => 'FacultyLoadData',
      _i9.FacultyShiftPreference => 'FacultyShiftPreference',
      _i10.GenerateScheduleRequest => 'GenerateScheduleRequest',
      _i11.GenerateScheduleResponse => 'GenerateScheduleResponse',
      _i12.Greeting => 'Greeting',
      _i13.NLPIntent => 'NLPIntent',
      _i14.NLPResponse => 'NLPResponse',
      _i15.Program => 'Program',
      _i16.ConflictSummaryReport => 'ConflictSummaryReport',
      _i17.FacultyLoadReport => 'FacultyLoadReport',
      _i18.RoomUtilizationReport => 'RoomUtilizationReport',
      _i19.ScheduleOverviewReport => 'ScheduleOverviewReport',
      _i20.Room => 'Room',
      _i21.RoomType => 'RoomType',
      _i22.Schedule => 'Schedule',
      _i23.ScheduleConflict => 'ScheduleConflict',
      _i24.ScheduleInfo => 'ScheduleInfo',
      _i25.Section => 'Section',
      _i26.Student => 'Student',
      _i27.Subject => 'Subject',
      _i28.SubjectType => 'SubjectType',
      _i29.Timeslot => 'Timeslot',
      _i30.TimetableFilterRequest => 'TimetableFilterRequest',
      _i31.TimetableSummary => 'TimetableSummary',
      _i32.UserRole => 'UserRole',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('citesched.', '');
    }

    switch (data) {
      case _i2.DashboardStats():
        return 'DashboardStats';
      case _i3.DayOfWeek():
        return 'DayOfWeek';
      case _i4.DistributionData():
        return 'DistributionData';
      case _i5.EmploymentStatus():
        return 'EmploymentStatus';
      case _i6.Faculty():
        return 'Faculty';
      case _i7.FacultyAvailability():
        return 'FacultyAvailability';
      case _i8.FacultyLoadData():
        return 'FacultyLoadData';
      case _i9.FacultyShiftPreference():
        return 'FacultyShiftPreference';
      case _i10.GenerateScheduleRequest():
        return 'GenerateScheduleRequest';
      case _i11.GenerateScheduleResponse():
        return 'GenerateScheduleResponse';
      case _i12.Greeting():
        return 'Greeting';
      case _i13.NLPIntent():
        return 'NLPIntent';
      case _i14.NLPResponse():
        return 'NLPResponse';
      case _i15.Program():
        return 'Program';
      case _i16.ConflictSummaryReport():
        return 'ConflictSummaryReport';
      case _i17.FacultyLoadReport():
        return 'FacultyLoadReport';
      case _i18.RoomUtilizationReport():
        return 'RoomUtilizationReport';
      case _i19.ScheduleOverviewReport():
        return 'ScheduleOverviewReport';
      case _i20.Room():
        return 'Room';
      case _i21.RoomType():
        return 'RoomType';
      case _i22.Schedule():
        return 'Schedule';
      case _i23.ScheduleConflict():
        return 'ScheduleConflict';
      case _i24.ScheduleInfo():
        return 'ScheduleInfo';
      case _i25.Section():
        return 'Section';
      case _i26.Student():
        return 'Student';
      case _i27.Subject():
        return 'Subject';
      case _i28.SubjectType():
        return 'SubjectType';
      case _i29.Timeslot():
        return 'Timeslot';
      case _i30.TimetableFilterRequest():
        return 'TimetableFilterRequest';
      case _i31.TimetableSummary():
        return 'TimetableSummary';
      case _i32.UserRole():
        return 'UserRole';
    }
    className = _i46.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i47.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth.$className';
    }
    className = _i48.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'DashboardStats') {
      return deserialize<_i2.DashboardStats>(data['data']);
    }
    if (dataClassName == 'DayOfWeek') {
      return deserialize<_i3.DayOfWeek>(data['data']);
    }
    if (dataClassName == 'DistributionData') {
      return deserialize<_i4.DistributionData>(data['data']);
    }
    if (dataClassName == 'EmploymentStatus') {
      return deserialize<_i5.EmploymentStatus>(data['data']);
    }
    if (dataClassName == 'Faculty') {
      return deserialize<_i6.Faculty>(data['data']);
    }
    if (dataClassName == 'FacultyAvailability') {
      return deserialize<_i7.FacultyAvailability>(data['data']);
    }
    if (dataClassName == 'FacultyLoadData') {
      return deserialize<_i8.FacultyLoadData>(data['data']);
    }
    if (dataClassName == 'FacultyShiftPreference') {
      return deserialize<_i9.FacultyShiftPreference>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleRequest') {
      return deserialize<_i10.GenerateScheduleRequest>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleResponse') {
      return deserialize<_i11.GenerateScheduleResponse>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i12.Greeting>(data['data']);
    }
    if (dataClassName == 'NLPIntent') {
      return deserialize<_i13.NLPIntent>(data['data']);
    }
    if (dataClassName == 'NLPResponse') {
      return deserialize<_i14.NLPResponse>(data['data']);
    }
    if (dataClassName == 'Program') {
      return deserialize<_i15.Program>(data['data']);
    }
    if (dataClassName == 'ConflictSummaryReport') {
      return deserialize<_i16.ConflictSummaryReport>(data['data']);
    }
    if (dataClassName == 'FacultyLoadReport') {
      return deserialize<_i17.FacultyLoadReport>(data['data']);
    }
    if (dataClassName == 'RoomUtilizationReport') {
      return deserialize<_i18.RoomUtilizationReport>(data['data']);
    }
    if (dataClassName == 'ScheduleOverviewReport') {
      return deserialize<_i19.ScheduleOverviewReport>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i20.Room>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i21.RoomType>(data['data']);
    }
    if (dataClassName == 'Schedule') {
      return deserialize<_i22.Schedule>(data['data']);
    }
    if (dataClassName == 'ScheduleConflict') {
      return deserialize<_i23.ScheduleConflict>(data['data']);
    }
    if (dataClassName == 'ScheduleInfo') {
      return deserialize<_i24.ScheduleInfo>(data['data']);
    }
    if (dataClassName == 'Section') {
      return deserialize<_i25.Section>(data['data']);
    }
    if (dataClassName == 'Student') {
      return deserialize<_i26.Student>(data['data']);
    }
    if (dataClassName == 'Subject') {
      return deserialize<_i27.Subject>(data['data']);
    }
    if (dataClassName == 'SubjectType') {
      return deserialize<_i28.SubjectType>(data['data']);
    }
    if (dataClassName == 'Timeslot') {
      return deserialize<_i29.Timeslot>(data['data']);
    }
    if (dataClassName == 'TimetableFilterRequest') {
      return deserialize<_i30.TimetableFilterRequest>(data['data']);
    }
    if (dataClassName == 'TimetableSummary') {
      return deserialize<_i31.TimetableSummary>(data['data']);
    }
    if (dataClassName == 'UserRole') {
      return deserialize<_i32.UserRole>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i46.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i47.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i48.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i46.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i47.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i48.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
