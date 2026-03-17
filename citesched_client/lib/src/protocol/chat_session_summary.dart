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

abstract class ChatSessionSummary implements _i1.SerializableModel {
  ChatSessionSummary._({
    required this.sessionId,
    required this.title,
    required this.lastMessageAt,
    required this.lastMessageText,
  });

  factory ChatSessionSummary({
    required String sessionId,
    required String title,
    required DateTime lastMessageAt,
    required String lastMessageText,
  }) = _ChatSessionSummaryImpl;

  factory ChatSessionSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatSessionSummary(
      sessionId: jsonSerialization['sessionId'] as String,
      title: jsonSerialization['title'] as String,
      lastMessageAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastMessageAt'],
      ),
      lastMessageText: jsonSerialization['lastMessageText'] as String,
    );
  }

  String sessionId;

  String title;

  DateTime lastMessageAt;

  String lastMessageText;

  /// Returns a shallow copy of this [ChatSessionSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatSessionSummary copyWith({
    String? sessionId,
    String? title,
    DateTime? lastMessageAt,
    String? lastMessageText,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatSessionSummary',
      'sessionId': sessionId,
      'title': title,
      'lastMessageAt': lastMessageAt.toJson(),
      'lastMessageText': lastMessageText,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ChatSessionSummaryImpl extends ChatSessionSummary {
  _ChatSessionSummaryImpl({
    required String sessionId,
    required String title,
    required DateTime lastMessageAt,
    required String lastMessageText,
  }) : super._(
         sessionId: sessionId,
         title: title,
         lastMessageAt: lastMessageAt,
         lastMessageText: lastMessageText,
       );

  /// Returns a shallow copy of this [ChatSessionSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatSessionSummary copyWith({
    String? sessionId,
    String? title,
    DateTime? lastMessageAt,
    String? lastMessageText,
  }) {
    return ChatSessionSummary(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
    );
  }
}
