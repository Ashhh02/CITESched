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

abstract class ChatHistory implements _i1.SerializableModel {
  ChatHistory._({
    this.id,
    required this.userId,
    required this.role,
    this.sessionId,
    this.sessionTitle,
    required this.sender,
    required this.text,
    this.intent,
    this.metadataJson,
    required this.createdAt,
  });

  factory ChatHistory({
    int? id,
    required String userId,
    required String role,
    String? sessionId,
    String? sessionTitle,
    required String sender,
    required String text,
    String? intent,
    String? metadataJson,
    required DateTime createdAt,
  }) = _ChatHistoryImpl;

  factory ChatHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatHistory(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      role: jsonSerialization['role'] as String,
      sessionId: jsonSerialization['sessionId'] as String?,
      sessionTitle: jsonSerialization['sessionTitle'] as String?,
      sender: jsonSerialization['sender'] as String,
      text: jsonSerialization['text'] as String,
      intent: jsonSerialization['intent'] as String?,
      metadataJson: jsonSerialization['metadataJson'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String userId;

  String role;

  String? sessionId;

  String? sessionTitle;

  String sender;

  String text;

  String? intent;

  String? metadataJson;

  DateTime createdAt;

  /// Returns a shallow copy of this [ChatHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatHistory copyWith({
    int? id,
    String? userId,
    String? role,
    String? sessionId,
    String? sessionTitle,
    String? sender,
    String? text,
    String? intent,
    String? metadataJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatHistory',
      if (id != null) 'id': id,
      'userId': userId,
      'role': role,
      if (sessionId != null) 'sessionId': sessionId,
      if (sessionTitle != null) 'sessionTitle': sessionTitle,
      'sender': sender,
      'text': text,
      if (intent != null) 'intent': intent,
      if (metadataJson != null) 'metadataJson': metadataJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChatHistoryImpl extends ChatHistory {
  _ChatHistoryImpl({
    int? id,
    required String userId,
    required String role,
    String? sessionId,
    String? sessionTitle,
    required String sender,
    required String text,
    String? intent,
    String? metadataJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         role: role,
         sessionId: sessionId,
         sessionTitle: sessionTitle,
         sender: sender,
         text: text,
         intent: intent,
         metadataJson: metadataJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ChatHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatHistory copyWith({
    Object? id = _Undefined,
    String? userId,
    String? role,
    Object? sessionId = _Undefined,
    Object? sessionTitle = _Undefined,
    String? sender,
    String? text,
    Object? intent = _Undefined,
    Object? metadataJson = _Undefined,
    DateTime? createdAt,
  }) {
    return ChatHistory(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      sessionId: sessionId is String? ? sessionId : this.sessionId,
      sessionTitle: sessionTitle is String? ? sessionTitle : this.sessionTitle,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      intent: intent is String? ? intent : this.intent,
      metadataJson: metadataJson is String? ? metadataJson : this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
