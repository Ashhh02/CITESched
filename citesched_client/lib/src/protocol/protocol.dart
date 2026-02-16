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
import 'employment_status.dart' as _i4;
import 'faculty.dart' as _i5;
import 'faculty_load_data.dart' as _i6;
import 'faculty_shift_preference.dart' as _i7;
import 'generate_schedule_request.dart' as _i8;
import 'generate_schedule_response.dart' as _i9;
import 'greetings/greeting.dart' as _i10;
import 'room.dart' as _i11;
import 'room_type.dart' as _i12;
import 'schedule.dart' as _i13;
import 'schedule_conflict.dart' as _i14;
import 'student.dart' as _i15;
import 'subject.dart' as _i16;
import 'subject_type.dart' as _i17;
import 'timeslot.dart' as _i18;
import 'user_role.dart' as _i19;
import 'package:citesched_client/src/protocol/user_role.dart' as _i20;
import 'package:citesched_client/src/protocol/faculty.dart' as _i21;
import 'package:citesched_client/src/protocol/student.dart' as _i22;
import 'package:citesched_client/src/protocol/room.dart' as _i23;
import 'package:citesched_client/src/protocol/subject.dart' as _i24;
import 'package:citesched_client/src/protocol/timeslot.dart' as _i25;
import 'package:citesched_client/src/protocol/schedule.dart' as _i26;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i27;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i28;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i29;
export 'dashboard_stats.dart';
export 'day_of_week.dart';
export 'employment_status.dart';
export 'faculty.dart';
export 'faculty_load_data.dart';
export 'faculty_shift_preference.dart';
export 'generate_schedule_request.dart';
export 'generate_schedule_response.dart';
export 'greetings/greeting.dart';
export 'room.dart';
export 'room_type.dart';
export 'schedule.dart';
export 'schedule_conflict.dart';
export 'student.dart';
export 'subject.dart';
export 'subject_type.dart';
export 'timeslot.dart';
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
    if (t == _i4.EmploymentStatus) {
      return _i4.EmploymentStatus.fromJson(data) as T;
    }
    if (t == _i5.Faculty) {
      return _i5.Faculty.fromJson(data) as T;
    }
    if (t == _i6.FacultyLoadData) {
      return _i6.FacultyLoadData.fromJson(data) as T;
    }
    if (t == _i7.FacultyShiftPreference) {
      return _i7.FacultyShiftPreference.fromJson(data) as T;
    }
    if (t == _i8.GenerateScheduleRequest) {
      return _i8.GenerateScheduleRequest.fromJson(data) as T;
    }
    if (t == _i9.GenerateScheduleResponse) {
      return _i9.GenerateScheduleResponse.fromJson(data) as T;
    }
    if (t == _i10.Greeting) {
      return _i10.Greeting.fromJson(data) as T;
    }
    if (t == _i11.Room) {
      return _i11.Room.fromJson(data) as T;
    }
    if (t == _i12.RoomType) {
      return _i12.RoomType.fromJson(data) as T;
    }
    if (t == _i13.Schedule) {
      return _i13.Schedule.fromJson(data) as T;
    }
    if (t == _i14.ScheduleConflict) {
      return _i14.ScheduleConflict.fromJson(data) as T;
    }
    if (t == _i15.Student) {
      return _i15.Student.fromJson(data) as T;
    }
    if (t == _i16.Subject) {
      return _i16.Subject.fromJson(data) as T;
    }
    if (t == _i17.SubjectType) {
      return _i17.SubjectType.fromJson(data) as T;
    }
    if (t == _i18.Timeslot) {
      return _i18.Timeslot.fromJson(data) as T;
    }
    if (t == _i19.UserRole) {
      return _i19.UserRole.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.DashboardStats?>()) {
      return (data != null ? _i2.DashboardStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.DayOfWeek?>()) {
      return (data != null ? _i3.DayOfWeek.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.EmploymentStatus?>()) {
      return (data != null ? _i4.EmploymentStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Faculty?>()) {
      return (data != null ? _i5.Faculty.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.FacultyLoadData?>()) {
      return (data != null ? _i6.FacultyLoadData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.FacultyShiftPreference?>()) {
      return (data != null ? _i7.FacultyShiftPreference.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.GenerateScheduleRequest?>()) {
      return (data != null ? _i8.GenerateScheduleRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.GenerateScheduleResponse?>()) {
      return (data != null ? _i9.GenerateScheduleResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.Greeting?>()) {
      return (data != null ? _i10.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Room?>()) {
      return (data != null ? _i11.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.RoomType?>()) {
      return (data != null ? _i12.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Schedule?>()) {
      return (data != null ? _i13.Schedule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ScheduleConflict?>()) {
      return (data != null ? _i14.ScheduleConflict.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.Student?>()) {
      return (data != null ? _i15.Student.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Subject?>()) {
      return (data != null ? _i16.Subject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.SubjectType?>()) {
      return (data != null ? _i17.SubjectType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Timeslot?>()) {
      return (data != null ? _i18.Timeslot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.UserRole?>()) {
      return (data != null ? _i19.UserRole.fromJson(data) : null) as T;
    }
    if (t == List<_i6.FacultyLoadData>) {
      return (data as List)
              .map((e) => deserialize<_i6.FacultyLoadData>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.ScheduleConflict>) {
      return (data as List)
              .map((e) => deserialize<_i14.ScheduleConflict>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i13.Schedule>) {
      return (data as List).map((e) => deserialize<_i13.Schedule>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i13.Schedule>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i13.Schedule>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i14.ScheduleConflict>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.ScheduleConflict>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i20.UserRole>) {
      return (data as List).map((e) => deserialize<_i20.UserRole>(e)).toList()
          as T;
    }
    if (t == List<_i21.Faculty>) {
      return (data as List).map((e) => deserialize<_i21.Faculty>(e)).toList()
          as T;
    }
    if (t == List<_i22.Student>) {
      return (data as List).map((e) => deserialize<_i22.Student>(e)).toList()
          as T;
    }
    if (t == List<_i23.Room>) {
      return (data as List).map((e) => deserialize<_i23.Room>(e)).toList() as T;
    }
    if (t == List<_i24.Subject>) {
      return (data as List).map((e) => deserialize<_i24.Subject>(e)).toList()
          as T;
    }
    if (t == List<_i25.Timeslot>) {
      return (data as List).map((e) => deserialize<_i25.Timeslot>(e)).toList()
          as T;
    }
    if (t == List<_i26.Schedule>) {
      return (data as List).map((e) => deserialize<_i26.Schedule>(e)).toList()
          as T;
    }
    try {
      return _i27.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i28.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i29.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.DashboardStats => 'DashboardStats',
      _i3.DayOfWeek => 'DayOfWeek',
      _i4.EmploymentStatus => 'EmploymentStatus',
      _i5.Faculty => 'Faculty',
      _i6.FacultyLoadData => 'FacultyLoadData',
      _i7.FacultyShiftPreference => 'FacultyShiftPreference',
      _i8.GenerateScheduleRequest => 'GenerateScheduleRequest',
      _i9.GenerateScheduleResponse => 'GenerateScheduleResponse',
      _i10.Greeting => 'Greeting',
      _i11.Room => 'Room',
      _i12.RoomType => 'RoomType',
      _i13.Schedule => 'Schedule',
      _i14.ScheduleConflict => 'ScheduleConflict',
      _i15.Student => 'Student',
      _i16.Subject => 'Subject',
      _i17.SubjectType => 'SubjectType',
      _i18.Timeslot => 'Timeslot',
      _i19.UserRole => 'UserRole',
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
      case _i4.EmploymentStatus():
        return 'EmploymentStatus';
      case _i5.Faculty():
        return 'Faculty';
      case _i6.FacultyLoadData():
        return 'FacultyLoadData';
      case _i7.FacultyShiftPreference():
        return 'FacultyShiftPreference';
      case _i8.GenerateScheduleRequest():
        return 'GenerateScheduleRequest';
      case _i9.GenerateScheduleResponse():
        return 'GenerateScheduleResponse';
      case _i10.Greeting():
        return 'Greeting';
      case _i11.Room():
        return 'Room';
      case _i12.RoomType():
        return 'RoomType';
      case _i13.Schedule():
        return 'Schedule';
      case _i14.ScheduleConflict():
        return 'ScheduleConflict';
      case _i15.Student():
        return 'Student';
      case _i16.Subject():
        return 'Subject';
      case _i17.SubjectType():
        return 'SubjectType';
      case _i18.Timeslot():
        return 'Timeslot';
      case _i19.UserRole():
        return 'UserRole';
    }
    className = _i27.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i28.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth.$className';
    }
    className = _i29.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'EmploymentStatus') {
      return deserialize<_i4.EmploymentStatus>(data['data']);
    }
    if (dataClassName == 'Faculty') {
      return deserialize<_i5.Faculty>(data['data']);
    }
    if (dataClassName == 'FacultyLoadData') {
      return deserialize<_i6.FacultyLoadData>(data['data']);
    }
    if (dataClassName == 'FacultyShiftPreference') {
      return deserialize<_i7.FacultyShiftPreference>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleRequest') {
      return deserialize<_i8.GenerateScheduleRequest>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleResponse') {
      return deserialize<_i9.GenerateScheduleResponse>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i10.Greeting>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i11.Room>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i12.RoomType>(data['data']);
    }
    if (dataClassName == 'Schedule') {
      return deserialize<_i13.Schedule>(data['data']);
    }
    if (dataClassName == 'ScheduleConflict') {
      return deserialize<_i14.ScheduleConflict>(data['data']);
    }
    if (dataClassName == 'Student') {
      return deserialize<_i15.Student>(data['data']);
    }
    if (dataClassName == 'Subject') {
      return deserialize<_i16.Subject>(data['data']);
    }
    if (dataClassName == 'SubjectType') {
      return deserialize<_i17.SubjectType>(data['data']);
    }
    if (dataClassName == 'Timeslot') {
      return deserialize<_i18.Timeslot>(data['data']);
    }
    if (dataClassName == 'UserRole') {
      return deserialize<_i19.UserRole>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i27.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i28.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i29.Protocol().deserializeByClassName(data);
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
      return _i27.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i28.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i29.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
