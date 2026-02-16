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

abstract class FacultyLoadData
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  FacultyLoadData._({
    required this.facultyName,
    required this.currentLoad,
    required this.maxLoad,
  });

  factory FacultyLoadData({
    required String facultyName,
    required double currentLoad,
    required double maxLoad,
  }) = _FacultyLoadDataImpl;

  factory FacultyLoadData.fromJson(Map<String, dynamic> jsonSerialization) {
    return FacultyLoadData(
      facultyName: jsonSerialization['facultyName'] as String,
      currentLoad: (jsonSerialization['currentLoad'] as num).toDouble(),
      maxLoad: (jsonSerialization['maxLoad'] as num).toDouble(),
    );
  }

  String facultyName;

  double currentLoad;

  double maxLoad;

  /// Returns a shallow copy of this [FacultyLoadData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FacultyLoadData copyWith({
    String? facultyName,
    double? currentLoad,
    double? maxLoad,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FacultyLoadData',
      'facultyName': facultyName,
      'currentLoad': currentLoad,
      'maxLoad': maxLoad,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FacultyLoadData',
      'facultyName': facultyName,
      'currentLoad': currentLoad,
      'maxLoad': maxLoad,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _FacultyLoadDataImpl extends FacultyLoadData {
  _FacultyLoadDataImpl({
    required String facultyName,
    required double currentLoad,
    required double maxLoad,
  }) : super._(
         facultyName: facultyName,
         currentLoad: currentLoad,
         maxLoad: maxLoad,
       );

  /// Returns a shallow copy of this [FacultyLoadData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FacultyLoadData copyWith({
    String? facultyName,
    double? currentLoad,
    double? maxLoad,
  }) {
    return FacultyLoadData(
      facultyName: facultyName ?? this.facultyName,
      currentLoad: currentLoad ?? this.currentLoad,
      maxLoad: maxLoad ?? this.maxLoad,
    );
  }
}
