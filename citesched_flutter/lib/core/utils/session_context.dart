import 'dart:convert';

import 'package:citesched_flutter/main.dart';

class SessionContext {
  const SessionContext({
    required this.authenticatedUserId,
    required this.email,
    required this.userName,
    required this.resolvedRole,
    required this.scopeNames,
  });

  final String? authenticatedUserId;
  final String? email;
  final String? userName;
  final String? resolvedRole;
  final List<String> scopeNames;

  static const empty = SessionContext(
    authenticatedUserId: null,
    email: null,
    userName: null,
    resolvedRole: null,
    scopeNames: <String>[],
  );

  factory SessionContext.fromJson(Map<String, dynamic> json) {
    final scopesRaw = json['scopeNames'];
    final scopes =
        scopesRaw is List
            ? scopesRaw.whereType<String>().toList()
            : const <String>[];

    return SessionContext(
      authenticatedUserId: json['authenticatedUserId']?.toString(),
      email: json['email']?.toString(),
      userName: json['userName']?.toString(),
      resolvedRole: json['resolvedRole']?.toString(),
      scopeNames: scopes,
    );
  }
}

Future<SessionContext> fetchSessionContext() async {
  try {
    final payload = await client.debug.getSessionInfo();
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      return SessionContext.fromJson(decoded);
    }
  } catch (_) {}

  return SessionContext.empty;
}
