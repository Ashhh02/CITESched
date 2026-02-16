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

abstract class ScheduleConflict implements _i1.SerializableModel {
  ScheduleConflict._({
    required this.type,
    required this.message,
    this.conflictingScheduleId,
    this.details,
  });

  factory ScheduleConflict({
    required String type,
    required String message,
    int? conflictingScheduleId,
    String? details,
  }) = _ScheduleConflictImpl;

  factory ScheduleConflict.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScheduleConflict(
      type: jsonSerialization['type'] as String,
      message: jsonSerialization['message'] as String,
      conflictingScheduleId: jsonSerialization['conflictingScheduleId'] as int?,
      details: jsonSerialization['details'] as String?,
    );
  }

  String type;

  String message;

  int? conflictingScheduleId;

  String? details;

  /// Returns a shallow copy of this [ScheduleConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ScheduleConflict copyWith({
    String? type,
    String? message,
    int? conflictingScheduleId,
    String? details,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScheduleConflict',
      'type': type,
      'message': message,
      if (conflictingScheduleId != null)
        'conflictingScheduleId': conflictingScheduleId,
      if (details != null) 'details': details,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScheduleConflictImpl extends ScheduleConflict {
  _ScheduleConflictImpl({
    required String type,
    required String message,
    int? conflictingScheduleId,
    String? details,
  }) : super._(
         type: type,
         message: message,
         conflictingScheduleId: conflictingScheduleId,
         details: details,
       );

  /// Returns a shallow copy of this [ScheduleConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ScheduleConflict copyWith({
    String? type,
    String? message,
    Object? conflictingScheduleId = _Undefined,
    Object? details = _Undefined,
  }) {
    return ScheduleConflict(
      type: type ?? this.type,
      message: message ?? this.message,
      conflictingScheduleId: conflictingScheduleId is int?
          ? conflictingScheduleId
          : this.conflictingScheduleId,
      details: details is String? ? details : this.details,
    );
  }
}
