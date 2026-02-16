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
import 'subject_type.dart' as _i2;

abstract class Schedule
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = ScheduleTable();

  static const db = ScheduleRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static ScheduleInclude include() {
    return ScheduleInclude._();
  }

  static ScheduleIncludeList includeList({
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    ScheduleInclude? include,
  }) {
    return ScheduleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Schedule.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Schedule.t),
      include: include,
    );
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

class ScheduleUpdateTable extends _i1.UpdateTable<ScheduleTable> {
  ScheduleUpdateTable(super.table);

  _i1.ColumnValue<int, int> subjectId(int value) => _i1.ColumnValue(
    table.subjectId,
    value,
  );

  _i1.ColumnValue<int, int> facultyId(int value) => _i1.ColumnValue(
    table.facultyId,
    value,
  );

  _i1.ColumnValue<int, int> roomId(int value) => _i1.ColumnValue(
    table.roomId,
    value,
  );

  _i1.ColumnValue<int, int> timeslotId(int value) => _i1.ColumnValue(
    table.timeslotId,
    value,
  );

  _i1.ColumnValue<String, String> section(String value) => _i1.ColumnValue(
    table.section,
    value,
  );

  _i1.ColumnValue<_i2.SubjectType, _i2.SubjectType> loadType(
    _i2.SubjectType? value,
  ) => _i1.ColumnValue(
    table.loadType,
    value,
  );

  _i1.ColumnValue<double, double> units(double? value) => _i1.ColumnValue(
    table.units,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ScheduleTable extends _i1.Table<int?> {
  ScheduleTable({super.tableRelation}) : super(tableName: 'schedule') {
    updateTable = ScheduleUpdateTable(this);
    subjectId = _i1.ColumnInt(
      'subjectId',
      this,
    );
    facultyId = _i1.ColumnInt(
      'facultyId',
      this,
    );
    roomId = _i1.ColumnInt(
      'roomId',
      this,
    );
    timeslotId = _i1.ColumnInt(
      'timeslotId',
      this,
    );
    section = _i1.ColumnString(
      'section',
      this,
    );
    loadType = _i1.ColumnEnum(
      'loadType',
      this,
      _i1.EnumSerialization.byName,
    );
    units = _i1.ColumnDouble(
      'units',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ScheduleUpdateTable updateTable;

  late final _i1.ColumnInt subjectId;

  late final _i1.ColumnInt facultyId;

  late final _i1.ColumnInt roomId;

  late final _i1.ColumnInt timeslotId;

  late final _i1.ColumnString section;

  late final _i1.ColumnEnum<_i2.SubjectType> loadType;

  late final _i1.ColumnDouble units;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    subjectId,
    facultyId,
    roomId,
    timeslotId,
    section,
    loadType,
    units,
    createdAt,
    updatedAt,
  ];
}

class ScheduleInclude extends _i1.IncludeObject {
  ScheduleInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Schedule.t;
}

class ScheduleIncludeList extends _i1.IncludeList {
  ScheduleIncludeList._({
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Schedule.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Schedule.t;
}

class ScheduleRepository {
  const ScheduleRepository._();

  /// Returns a list of [Schedule]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Schedule>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Schedule>(
      where: where?.call(Schedule.t),
      orderBy: orderBy?.call(Schedule.t),
      orderByList: orderByList?.call(Schedule.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Schedule] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Schedule?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Schedule>(
      where: where?.call(Schedule.t),
      orderBy: orderBy?.call(Schedule.t),
      orderByList: orderByList?.call(Schedule.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Schedule] by its [id] or null if no such row exists.
  Future<Schedule?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Schedule>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Schedule]s in the list and returns the inserted rows.
  ///
  /// The returned [Schedule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Schedule>> insert(
    _i1.Session session,
    List<Schedule> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Schedule>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Schedule] and returns the inserted row.
  ///
  /// The returned [Schedule] will have its `id` field set.
  Future<Schedule> insertRow(
    _i1.Session session,
    Schedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Schedule>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Schedule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Schedule>> update(
    _i1.Session session,
    List<Schedule> rows, {
    _i1.ColumnSelections<ScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Schedule>(
      rows,
      columns: columns?.call(Schedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Schedule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Schedule> updateRow(
    _i1.Session session,
    Schedule row, {
    _i1.ColumnSelections<ScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Schedule>(
      row,
      columns: columns?.call(Schedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Schedule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Schedule?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ScheduleUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Schedule>(
      id,
      columnValues: columnValues(Schedule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Schedule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Schedule>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ScheduleUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ScheduleTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Schedule>(
      columnValues: columnValues(Schedule.t.updateTable),
      where: where(Schedule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Schedule.t),
      orderByList: orderByList?.call(Schedule.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Schedule]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Schedule>> delete(
    _i1.Session session,
    List<Schedule> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Schedule>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Schedule].
  Future<Schedule> deleteRow(
    _i1.Session session,
    Schedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Schedule>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Schedule>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ScheduleTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Schedule>(
      where: where(Schedule.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Schedule>(
      where: where?.call(Schedule.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
