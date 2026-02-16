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

abstract class Subject implements _i1.SerializableModel {
  Subject._({
    this.id,
    required this.code,
    required this.name,
    required this.units,
    this.yearLevel,
    this.term,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject({
    int? id,
    required String code,
    required String name,
    required int units,
    int? yearLevel,
    int? term,
    required _i2.SubjectType type,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SubjectImpl;

  factory Subject.fromJson(Map<String, dynamic> jsonSerialization) {
    return Subject(
      id: jsonSerialization['id'] as int?,
      code: jsonSerialization['code'] as String,
      name: jsonSerialization['name'] as String,
      units: jsonSerialization['units'] as int,
      yearLevel: jsonSerialization['yearLevel'] as int?,
      term: jsonSerialization['term'] as int?,
      type: _i2.SubjectType.fromJson((jsonSerialization['type'] as String)),
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

  String code;

  String name;

  int units;

  int? yearLevel;

  int? term;

  _i2.SubjectType type;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Subject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Subject copyWith({
    int? id,
    String? code,
    String? name,
    int? units,
    int? yearLevel,
    int? term,
    _i2.SubjectType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Subject',
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'units': units,
      if (yearLevel != null) 'yearLevel': yearLevel,
      if (term != null) 'term': term,
      'type': type.toJson(),
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

class _SubjectImpl extends Subject {
  _SubjectImpl({
    int? id,
    required String code,
    required String name,
    required int units,
    int? yearLevel,
    int? term,
    required _i2.SubjectType type,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         code: code,
         name: name,
         units: units,
         yearLevel: yearLevel,
         term: term,
         type: type,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Subject]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Subject copyWith({
    Object? id = _Undefined,
    String? code,
    String? name,
    int? units,
    Object? yearLevel = _Undefined,
    Object? term = _Undefined,
    _i2.SubjectType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id is int? ? id : this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      units: units ?? this.units,
      yearLevel: yearLevel is int? ? yearLevel : this.yearLevel,
      term: term is int? ? term : this.term,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
