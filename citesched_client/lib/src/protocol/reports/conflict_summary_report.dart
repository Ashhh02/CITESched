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

abstract class ConflictSummaryReport implements _i1.SerializableModel {
  ConflictSummaryReport._({
    required this.totalConflicts,
    required this.conflictsByType,
    required this.resolvedConflicts,
    this.mostFrequentConflictType,
  });

  factory ConflictSummaryReport({
    required int totalConflicts,
    required Map<String, int> conflictsByType,
    required int resolvedConflicts,
    String? mostFrequentConflictType,
  }) = _ConflictSummaryReportImpl;

  factory ConflictSummaryReport.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConflictSummaryReport(
      totalConflicts: jsonSerialization['totalConflicts'] as int,
      conflictsByType: _i2.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['conflictsByType'],
      ),
      resolvedConflicts: jsonSerialization['resolvedConflicts'] as int,
      mostFrequentConflictType:
          jsonSerialization['mostFrequentConflictType'] as String?,
    );
  }

  int totalConflicts;

  Map<String, int> conflictsByType;

  int resolvedConflicts;

  String? mostFrequentConflictType;

  /// Returns a shallow copy of this [ConflictSummaryReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConflictSummaryReport copyWith({
    int? totalConflicts,
    Map<String, int>? conflictsByType,
    int? resolvedConflicts,
    String? mostFrequentConflictType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConflictSummaryReport',
      'totalConflicts': totalConflicts,
      'conflictsByType': conflictsByType.toJson(),
      'resolvedConflicts': resolvedConflicts,
      if (mostFrequentConflictType != null)
        'mostFrequentConflictType': mostFrequentConflictType,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConflictSummaryReportImpl extends ConflictSummaryReport {
  _ConflictSummaryReportImpl({
    required int totalConflicts,
    required Map<String, int> conflictsByType,
    required int resolvedConflicts,
    String? mostFrequentConflictType,
  }) : super._(
         totalConflicts: totalConflicts,
         conflictsByType: conflictsByType,
         resolvedConflicts: resolvedConflicts,
         mostFrequentConflictType: mostFrequentConflictType,
       );

  /// Returns a shallow copy of this [ConflictSummaryReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConflictSummaryReport copyWith({
    int? totalConflicts,
    Map<String, int>? conflictsByType,
    int? resolvedConflicts,
    Object? mostFrequentConflictType = _Undefined,
  }) {
    return ConflictSummaryReport(
      totalConflicts: totalConflicts ?? this.totalConflicts,
      conflictsByType:
          conflictsByType ??
          this.conflictsByType.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      resolvedConflicts: resolvedConflicts ?? this.resolvedConflicts,
      mostFrequentConflictType: mostFrequentConflictType is String?
          ? mostFrequentConflictType
          : this.mostFrequentConflictType,
    );
  }
}
