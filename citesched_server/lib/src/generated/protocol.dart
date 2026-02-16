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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i4;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i5;
import 'dashboard_stats.dart' as _i6;
import 'day_of_week.dart' as _i7;
import 'employment_status.dart' as _i8;
import 'faculty.dart' as _i9;
import 'faculty_load_data.dart' as _i10;
import 'faculty_shift_preference.dart' as _i11;
import 'generate_schedule_request.dart' as _i12;
import 'generate_schedule_response.dart' as _i13;
import 'greetings/greeting.dart' as _i14;
import 'room.dart' as _i15;
import 'room_type.dart' as _i16;
import 'schedule.dart' as _i17;
import 'schedule_conflict.dart' as _i18;
import 'student.dart' as _i19;
import 'subject.dart' as _i20;
import 'subject_type.dart' as _i21;
import 'timeslot.dart' as _i22;
import 'user_role.dart' as _i23;
import 'package:citesched_server/src/generated/user_role.dart' as _i24;
import 'package:citesched_server/src/generated/faculty.dart' as _i25;
import 'package:citesched_server/src/generated/student.dart' as _i26;
import 'package:citesched_server/src/generated/room.dart' as _i27;
import 'package:citesched_server/src/generated/subject.dart' as _i28;
import 'package:citesched_server/src/generated/timeslot.dart' as _i29;
import 'package:citesched_server/src/generated/schedule.dart' as _i30;
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

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'faculty',
      dartName: 'Faculty',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'faculty_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'department',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'maxLoad',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'employmentStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:EmploymentStatus',
        ),
        _i2.ColumnDefinition(
          name: 'shiftPreference',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:FacultyShiftPreference?',
        ),
        _i2.ColumnDefinition(
          name: 'preferredHours',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'facultyId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userInfoId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'faculty_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'faculty_email_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'faculty_id_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'facultyId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'room',
      dartName: 'Room',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'room_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'capacity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RoomType',
        ),
        _i2.ColumnDefinition(
          name: 'building',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'room_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'schedule',
      dartName: 'Schedule',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'schedule_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'subjectId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'facultyId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'roomId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'timeslotId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'section',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'loadType',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:SubjectType?',
        ),
        _i2.ColumnDefinition(
          name: 'units',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_0',
          columns: ['subjectId'],
          referenceTable: 'subject',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_1',
          columns: ['facultyId'],
          referenceTable: 'faculty',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_2',
          columns: ['roomId'],
          referenceTable: 'room',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_3',
          columns: ['timeslotId'],
          referenceTable: 'timeslot',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'schedule_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'student',
      dartName: 'Student',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'student_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'studentNumber',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'course',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'yearLevel',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userInfoId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'student_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'student_email_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'student_number_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'studentNumber',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'subject',
      dartName: 'Subject',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'subject_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'code',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'units',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'yearLevel',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'term',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SubjectType',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'subject_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'timeslot',
      dartName: 'Timeslot',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'timeslot_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'day',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DayOfWeek',
        ),
        _i2.ColumnDefinition(
          name: 'startTime',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'endTime',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'label',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'timeslot_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_role',
      dartName: 'UserRole',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_role_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_role_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_role_user_id_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i5.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i6.DashboardStats) {
      return _i6.DashboardStats.fromJson(data) as T;
    }
    if (t == _i7.DayOfWeek) {
      return _i7.DayOfWeek.fromJson(data) as T;
    }
    if (t == _i8.EmploymentStatus) {
      return _i8.EmploymentStatus.fromJson(data) as T;
    }
    if (t == _i9.Faculty) {
      return _i9.Faculty.fromJson(data) as T;
    }
    if (t == _i10.FacultyLoadData) {
      return _i10.FacultyLoadData.fromJson(data) as T;
    }
    if (t == _i11.FacultyShiftPreference) {
      return _i11.FacultyShiftPreference.fromJson(data) as T;
    }
    if (t == _i12.GenerateScheduleRequest) {
      return _i12.GenerateScheduleRequest.fromJson(data) as T;
    }
    if (t == _i13.GenerateScheduleResponse) {
      return _i13.GenerateScheduleResponse.fromJson(data) as T;
    }
    if (t == _i14.Greeting) {
      return _i14.Greeting.fromJson(data) as T;
    }
    if (t == _i15.Room) {
      return _i15.Room.fromJson(data) as T;
    }
    if (t == _i16.RoomType) {
      return _i16.RoomType.fromJson(data) as T;
    }
    if (t == _i17.Schedule) {
      return _i17.Schedule.fromJson(data) as T;
    }
    if (t == _i18.ScheduleConflict) {
      return _i18.ScheduleConflict.fromJson(data) as T;
    }
    if (t == _i19.Student) {
      return _i19.Student.fromJson(data) as T;
    }
    if (t == _i20.Subject) {
      return _i20.Subject.fromJson(data) as T;
    }
    if (t == _i21.SubjectType) {
      return _i21.SubjectType.fromJson(data) as T;
    }
    if (t == _i22.Timeslot) {
      return _i22.Timeslot.fromJson(data) as T;
    }
    if (t == _i23.UserRole) {
      return _i23.UserRole.fromJson(data) as T;
    }
    if (t == _i1.getType<_i6.DashboardStats?>()) {
      return (data != null ? _i6.DashboardStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.DayOfWeek?>()) {
      return (data != null ? _i7.DayOfWeek.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.EmploymentStatus?>()) {
      return (data != null ? _i8.EmploymentStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Faculty?>()) {
      return (data != null ? _i9.Faculty.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.FacultyLoadData?>()) {
      return (data != null ? _i10.FacultyLoadData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.FacultyShiftPreference?>()) {
      return (data != null ? _i11.FacultyShiftPreference.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.GenerateScheduleRequest?>()) {
      return (data != null ? _i12.GenerateScheduleRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.GenerateScheduleResponse?>()) {
      return (data != null
              ? _i13.GenerateScheduleResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.Greeting?>()) {
      return (data != null ? _i14.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.Room?>()) {
      return (data != null ? _i15.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.RoomType?>()) {
      return (data != null ? _i16.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.Schedule?>()) {
      return (data != null ? _i17.Schedule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ScheduleConflict?>()) {
      return (data != null ? _i18.ScheduleConflict.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.Student?>()) {
      return (data != null ? _i19.Student.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.Subject?>()) {
      return (data != null ? _i20.Subject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.SubjectType?>()) {
      return (data != null ? _i21.SubjectType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.Timeslot?>()) {
      return (data != null ? _i22.Timeslot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.UserRole?>()) {
      return (data != null ? _i23.UserRole.fromJson(data) : null) as T;
    }
    if (t == List<_i10.FacultyLoadData>) {
      return (data as List)
              .map((e) => deserialize<_i10.FacultyLoadData>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.ScheduleConflict>) {
      return (data as List)
              .map((e) => deserialize<_i18.ScheduleConflict>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i17.Schedule>) {
      return (data as List).map((e) => deserialize<_i17.Schedule>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i17.Schedule>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.Schedule>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i18.ScheduleConflict>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i18.ScheduleConflict>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i24.UserRole>) {
      return (data as List).map((e) => deserialize<_i24.UserRole>(e)).toList()
          as T;
    }
    if (t == List<_i25.Faculty>) {
      return (data as List).map((e) => deserialize<_i25.Faculty>(e)).toList()
          as T;
    }
    if (t == List<_i26.Student>) {
      return (data as List).map((e) => deserialize<_i26.Student>(e)).toList()
          as T;
    }
    if (t == List<_i27.Room>) {
      return (data as List).map((e) => deserialize<_i27.Room>(e)).toList() as T;
    }
    if (t == List<_i28.Subject>) {
      return (data as List).map((e) => deserialize<_i28.Subject>(e)).toList()
          as T;
    }
    if (t == List<_i29.Timeslot>) {
      return (data as List).map((e) => deserialize<_i29.Timeslot>(e)).toList()
          as T;
    }
    if (t == List<_i30.Schedule>) {
      return (data as List).map((e) => deserialize<_i30.Schedule>(e)).toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i5.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i6.DashboardStats => 'DashboardStats',
      _i7.DayOfWeek => 'DayOfWeek',
      _i8.EmploymentStatus => 'EmploymentStatus',
      _i9.Faculty => 'Faculty',
      _i10.FacultyLoadData => 'FacultyLoadData',
      _i11.FacultyShiftPreference => 'FacultyShiftPreference',
      _i12.GenerateScheduleRequest => 'GenerateScheduleRequest',
      _i13.GenerateScheduleResponse => 'GenerateScheduleResponse',
      _i14.Greeting => 'Greeting',
      _i15.Room => 'Room',
      _i16.RoomType => 'RoomType',
      _i17.Schedule => 'Schedule',
      _i18.ScheduleConflict => 'ScheduleConflict',
      _i19.Student => 'Student',
      _i20.Subject => 'Subject',
      _i21.SubjectType => 'SubjectType',
      _i22.Timeslot => 'Timeslot',
      _i23.UserRole => 'UserRole',
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
      case _i6.DashboardStats():
        return 'DashboardStats';
      case _i7.DayOfWeek():
        return 'DayOfWeek';
      case _i8.EmploymentStatus():
        return 'EmploymentStatus';
      case _i9.Faculty():
        return 'Faculty';
      case _i10.FacultyLoadData():
        return 'FacultyLoadData';
      case _i11.FacultyShiftPreference():
        return 'FacultyShiftPreference';
      case _i12.GenerateScheduleRequest():
        return 'GenerateScheduleRequest';
      case _i13.GenerateScheduleResponse():
        return 'GenerateScheduleResponse';
      case _i14.Greeting():
        return 'Greeting';
      case _i15.Room():
        return 'Room';
      case _i16.RoomType():
        return 'RoomType';
      case _i17.Schedule():
        return 'Schedule';
      case _i18.ScheduleConflict():
        return 'ScheduleConflict';
      case _i19.Student():
        return 'Student';
      case _i20.Subject():
        return 'Subject';
      case _i21.SubjectType():
        return 'SubjectType';
      case _i22.Timeslot():
        return 'Timeslot';
      case _i23.UserRole():
        return 'UserRole';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth.$className';
    }
    className = _i5.Protocol().getClassNameForObject(data);
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
      return deserialize<_i6.DashboardStats>(data['data']);
    }
    if (dataClassName == 'DayOfWeek') {
      return deserialize<_i7.DayOfWeek>(data['data']);
    }
    if (dataClassName == 'EmploymentStatus') {
      return deserialize<_i8.EmploymentStatus>(data['data']);
    }
    if (dataClassName == 'Faculty') {
      return deserialize<_i9.Faculty>(data['data']);
    }
    if (dataClassName == 'FacultyLoadData') {
      return deserialize<_i10.FacultyLoadData>(data['data']);
    }
    if (dataClassName == 'FacultyShiftPreference') {
      return deserialize<_i11.FacultyShiftPreference>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleRequest') {
      return deserialize<_i12.GenerateScheduleRequest>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleResponse') {
      return deserialize<_i13.GenerateScheduleResponse>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i14.Greeting>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i15.Room>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i16.RoomType>(data['data']);
    }
    if (dataClassName == 'Schedule') {
      return deserialize<_i17.Schedule>(data['data']);
    }
    if (dataClassName == 'ScheduleConflict') {
      return deserialize<_i18.ScheduleConflict>(data['data']);
    }
    if (dataClassName == 'Student') {
      return deserialize<_i19.Student>(data['data']);
    }
    if (dataClassName == 'Subject') {
      return deserialize<_i20.Subject>(data['data']);
    }
    if (dataClassName == 'SubjectType') {
      return deserialize<_i21.SubjectType>(data['data']);
    }
    if (dataClassName == 'Timeslot') {
      return deserialize<_i22.Timeslot>(data['data']);
    }
    if (dataClassName == 'UserRole') {
      return deserialize<_i23.UserRole>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i4.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i5.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i5.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i9.Faculty:
        return _i9.Faculty.t;
      case _i15.Room:
        return _i15.Room.t;
      case _i17.Schedule:
        return _i17.Schedule.t;
      case _i19.Student:
        return _i19.Student.t;
      case _i20.Subject:
        return _i20.Subject.t;
      case _i22.Timeslot:
        return _i22.Timeslot.t;
      case _i23.UserRole:
        return _i23.UserRole.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'citesched';

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
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i5.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
