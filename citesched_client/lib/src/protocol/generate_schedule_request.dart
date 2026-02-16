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
import 'package:citesched_client/src/protocol/protocol.dart' as _i2;

abstract class GenerateScheduleRequest implements _i1.SerializableModel {
  GenerateScheduleRequest._({
    required this.subjectIds,
    required this.facultyIds,
    required this.roomIds,
    required this.timeslotIds,
    required this.sections,
  });

  factory GenerateScheduleRequest({
    required List<int> subjectIds,
    required List<int> facultyIds,
    required List<int> roomIds,
    required List<int> timeslotIds,
    required List<String> sections,
  }) = _GenerateScheduleRequestImpl;

  factory GenerateScheduleRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GenerateScheduleRequest(
      subjectIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['subjectIds'],
      ),
      facultyIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['facultyIds'],
      ),
      roomIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['roomIds'],
      ),
      timeslotIds: _i2.Protocol().deserialize<List<int>>(
        jsonSerialization['timeslotIds'],
      ),
      sections: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['sections'],
      ),
    );
  }

  List<int> subjectIds;

  List<int> facultyIds;

  List<int> roomIds;

  List<int> timeslotIds;

  List<String> sections;

  /// Returns a shallow copy of this [GenerateScheduleRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GenerateScheduleRequest copyWith({
    List<int>? subjectIds,
    List<int>? facultyIds,
    List<int>? roomIds,
    List<int>? timeslotIds,
    List<String>? sections,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GenerateScheduleRequest',
      'subjectIds': subjectIds.toJson(),
      'facultyIds': facultyIds.toJson(),
      'roomIds': roomIds.toJson(),
      'timeslotIds': timeslotIds.toJson(),
      'sections': sections.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GenerateScheduleRequestImpl extends GenerateScheduleRequest {
  _GenerateScheduleRequestImpl({
    required List<int> subjectIds,
    required List<int> facultyIds,
    required List<int> roomIds,
    required List<int> timeslotIds,
    required List<String> sections,
  }) : super._(
         subjectIds: subjectIds,
         facultyIds: facultyIds,
         roomIds: roomIds,
         timeslotIds: timeslotIds,
         sections: sections,
       );

  /// Returns a shallow copy of this [GenerateScheduleRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GenerateScheduleRequest copyWith({
    List<int>? subjectIds,
    List<int>? facultyIds,
    List<int>? roomIds,
    List<int>? timeslotIds,
    List<String>? sections,
  }) {
    return GenerateScheduleRequest(
      subjectIds: subjectIds ?? this.subjectIds.map((e0) => e0).toList(),
      facultyIds: facultyIds ?? this.facultyIds.map((e0) => e0).toList(),
      roomIds: roomIds ?? this.roomIds.map((e0) => e0).toList(),
      timeslotIds: timeslotIds ?? this.timeslotIds.map((e0) => e0).toList(),
      sections: sections ?? this.sections.map((e0) => e0).toList(),
    );
  }
}
