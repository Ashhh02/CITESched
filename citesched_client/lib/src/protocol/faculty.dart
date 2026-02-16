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
import 'employment_status.dart' as _i2;
import 'faculty_shift_preference.dart' as _i3;

abstract class Faculty implements _i1.SerializableModel {
  Faculty._({
    this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.maxLoad,
    required this.employmentStatus,
    this.shiftPreference,
    this.preferredHours,
    required this.facultyId,
    required this.userInfoId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Faculty({
    int? id,
    required String name,
    required String email,
    required String department,
    required int maxLoad,
    required _i2.EmploymentStatus employmentStatus,
    _i3.FacultyShiftPreference? shiftPreference,
    String? preferredHours,
    required String facultyId,
    required int userInfoId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FacultyImpl;

  factory Faculty.fromJson(Map<String, dynamic> jsonSerialization) {
    return Faculty(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      department: jsonSerialization['department'] as String,
      maxLoad: jsonSerialization['maxLoad'] as int,
      employmentStatus: _i2.EmploymentStatus.fromJson(
        (jsonSerialization['employmentStatus'] as String),
      ),
      shiftPreference: jsonSerialization['shiftPreference'] == null
          ? null
          : _i3.FacultyShiftPreference.fromJson(
              (jsonSerialization['shiftPreference'] as String),
            ),
      preferredHours: jsonSerialization['preferredHours'] as String?,
      facultyId: jsonSerialization['facultyId'] as String,
      userInfoId: jsonSerialization['userInfoId'] as int,
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

  String name;

  String email;

  String department;

  int maxLoad;

  _i2.EmploymentStatus employmentStatus;

  _i3.FacultyShiftPreference? shiftPreference;

  String? preferredHours;

  String facultyId;

  int userInfoId;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Faculty]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Faculty copyWith({
    int? id,
    String? name,
    String? email,
    String? department,
    int? maxLoad,
    _i2.EmploymentStatus? employmentStatus,
    _i3.FacultyShiftPreference? shiftPreference,
    String? preferredHours,
    String? facultyId,
    int? userInfoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Faculty',
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'department': department,
      'maxLoad': maxLoad,
      'employmentStatus': employmentStatus.toJson(),
      if (shiftPreference != null) 'shiftPreference': shiftPreference?.toJson(),
      if (preferredHours != null) 'preferredHours': preferredHours,
      'facultyId': facultyId,
      'userInfoId': userInfoId,
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

class _FacultyImpl extends Faculty {
  _FacultyImpl({
    int? id,
    required String name,
    required String email,
    required String department,
    required int maxLoad,
    required _i2.EmploymentStatus employmentStatus,
    _i3.FacultyShiftPreference? shiftPreference,
    String? preferredHours,
    required String facultyId,
    required int userInfoId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         email: email,
         department: department,
         maxLoad: maxLoad,
         employmentStatus: employmentStatus,
         shiftPreference: shiftPreference,
         preferredHours: preferredHours,
         facultyId: facultyId,
         userInfoId: userInfoId,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Faculty]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Faculty copyWith({
    Object? id = _Undefined,
    String? name,
    String? email,
    String? department,
    int? maxLoad,
    _i2.EmploymentStatus? employmentStatus,
    Object? shiftPreference = _Undefined,
    Object? preferredHours = _Undefined,
    String? facultyId,
    int? userInfoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Faculty(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      maxLoad: maxLoad ?? this.maxLoad,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      shiftPreference: shiftPreference is _i3.FacultyShiftPreference?
          ? shiftPreference
          : this.shiftPreference,
      preferredHours: preferredHours is String?
          ? preferredHours
          : this.preferredHours,
      facultyId: facultyId ?? this.facultyId,
      userInfoId: userInfoId ?? this.userInfoId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
