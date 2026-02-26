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

abstract class FacultyLoadReport implements _i1.SerializableModel {
  FacultyLoadReport._({
    required this.facultyId,
    required this.facultyName,
    required this.totalUnits,
    required this.totalHours,
    required this.totalSubjects,
    required this.loadStatus,
    this.program,
  });

  factory FacultyLoadReport({
    required int facultyId,
    required String facultyName,
    required double totalUnits,
    required double totalHours,
    required int totalSubjects,
    required String loadStatus,
    String? program,
  }) = _FacultyLoadReportImpl;

  factory FacultyLoadReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return FacultyLoadReport(
      facultyId: jsonSerialization['facultyId'] as int,
      facultyName: jsonSerialization['facultyName'] as String,
      totalUnits: (jsonSerialization['totalUnits'] as num).toDouble(),
      totalHours: (jsonSerialization['totalHours'] as num).toDouble(),
      totalSubjects: jsonSerialization['totalSubjects'] as int,
      loadStatus: jsonSerialization['loadStatus'] as String,
      program: jsonSerialization['program'] as String?,
    );
  }

  int facultyId;

  String facultyName;

  double totalUnits;

  double totalHours;

  int totalSubjects;

  String loadStatus;

  String? program;

  /// Returns a shallow copy of this [FacultyLoadReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FacultyLoadReport copyWith({
    int? facultyId,
    String? facultyName,
    double? totalUnits,
    double? totalHours,
    int? totalSubjects,
    String? loadStatus,
    String? program,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FacultyLoadReport',
      'facultyId': facultyId,
      'facultyName': facultyName,
      'totalUnits': totalUnits,
      'totalHours': totalHours,
      'totalSubjects': totalSubjects,
      'loadStatus': loadStatus,
      if (program != null) 'program': program,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FacultyLoadReportImpl extends FacultyLoadReport {
  _FacultyLoadReportImpl({
    required int facultyId,
    required String facultyName,
    required double totalUnits,
    required double totalHours,
    required int totalSubjects,
    required String loadStatus,
    String? program,
  }) : super._(
         facultyId: facultyId,
         facultyName: facultyName,
         totalUnits: totalUnits,
         totalHours: totalHours,
         totalSubjects: totalSubjects,
         loadStatus: loadStatus,
         program: program,
       );

  /// Returns a shallow copy of this [FacultyLoadReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FacultyLoadReport copyWith({
    int? facultyId,
    String? facultyName,
    double? totalUnits,
    double? totalHours,
    int? totalSubjects,
    String? loadStatus,
    Object? program = _Undefined,
  }) {
    return FacultyLoadReport(
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      totalUnits: totalUnits ?? this.totalUnits,
      totalHours: totalHours ?? this.totalHours,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      loadStatus: loadStatus ?? this.loadStatus,
      program: program is String? ? program : this.program,
    );
  }
}
