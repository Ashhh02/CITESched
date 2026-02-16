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
import 'day_of_week.dart' as _i2;

abstract class Timeslot implements _i1.SerializableModel {
  Timeslot._({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Timeslot({
    int? id,
    required _i2.DayOfWeek day,
    required String startTime,
    required String endTime,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TimeslotImpl;

  factory Timeslot.fromJson(Map<String, dynamic> jsonSerialization) {
    return Timeslot(
      id: jsonSerialization['id'] as int?,
      day: _i2.DayOfWeek.fromJson((jsonSerialization['day'] as String)),
      startTime: jsonSerialization['startTime'] as String,
      endTime: jsonSerialization['endTime'] as String,
      label: jsonSerialization['label'] as String,
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

  _i2.DayOfWeek day;

  String startTime;

  String endTime;

  String label;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Timeslot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Timeslot copyWith({
    int? id,
    _i2.DayOfWeek? day,
    String? startTime,
    String? endTime,
    String? label,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Timeslot',
      if (id != null) 'id': id,
      'day': day.toJson(),
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
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

class _TimeslotImpl extends Timeslot {
  _TimeslotImpl({
    int? id,
    required _i2.DayOfWeek day,
    required String startTime,
    required String endTime,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         day: day,
         startTime: startTime,
         endTime: endTime,
         label: label,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Timeslot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Timeslot copyWith({
    Object? id = _Undefined,
    _i2.DayOfWeek? day,
    String? startTime,
    String? endTime,
    String? label,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timeslot(
      id: id is int? ? id : this.id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
