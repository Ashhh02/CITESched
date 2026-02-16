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
import 'subject_type.dart' as _i2;

abstract class Schedule implements _i1.SerializableModel {
  Schedule._({
    this.id,
    required this.subjectId,
    required this.facultyId,
    required this.roomId,
    required this.timeslotId,
    required this.section,
    this.loadType,
    this.units,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule({
    int? id,
    required int subjectId,
    required int facultyId,
    required int roomId,
    required int timeslotId,
    required String section,
    _i2.SubjectType? loadType,
    double? units,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ScheduleImpl;

  factory Schedule.fromJson(Map<String, dynamic> jsonSerialization) {
    return Schedule(
      id: jsonSerialization['id'] as int?,
      subjectId: jsonSerialization['subjectId'] as int,
      facultyId: jsonSerialization['facultyId'] as int,
      roomId: jsonSerialization['roomId'] as int,
      timeslotId: jsonSerialization['timeslotId'] as int,
      section: jsonSerialization['section'] as String,
      loadType: jsonSerialization['loadType'] == null
          ? null
          : _i2.SubjectType.fromJson((jsonSerialization['loadType'] as String)),
      units: (jsonSerialization['units'] as num?)?.toDouble(),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int subjectId;

  int facultyId;

  int roomId;

  int timeslotId;

  String section;

  _i2.SubjectType? loadType;

  double? units;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Schedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Schedule copyWith({
    int? id,
    int? subjectId,
    int? facultyId,
    int? roomId,
    int? timeslotId,
    String? section,
    _i2.SubjectType? loadType,
    double? units,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Schedule',
      if (id != null) 'id': id,
      'subjectId': subjectId,
      'facultyId': facultyId,
      'roomId': roomId,
      'timeslotId': timeslotId,
      'section': section,
      if (loadType != null) 'loadType': loadType?.toJson(),
      if (units != null) 'units': units,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScheduleImpl extends Schedule {
  _ScheduleImpl({
    int? id,
    required int subjectId,
    required int facultyId,
    required int roomId,
    required int timeslotId,
    required String section,
    _i2.SubjectType? loadType,
    double? units,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         subjectId: subjectId,
         facultyId: facultyId,
         roomId: roomId,
         timeslotId: timeslotId,
         section: section,
         loadType: loadType,
         units: units,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Schedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Schedule copyWith({
    Object? id = _Undefined,
    int? subjectId,
    int? facultyId,
    int? roomId,
    int? timeslotId,
    String? section,
    Object? loadType = _Undefined,
    Object? units = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id is int? ? id : this.id,
      subjectId: subjectId ?? this.subjectId,
      facultyId: facultyId ?? this.facultyId,
      roomId: roomId ?? this.roomId,
      timeslotId: timeslotId ?? this.timeslotId,
      section: section ?? this.section,
      loadType: loadType is _i2.SubjectType? ? loadType : this.loadType,
      units: units is double? ? units : this.units,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
