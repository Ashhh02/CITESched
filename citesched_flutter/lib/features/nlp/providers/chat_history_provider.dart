import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatHistoryProvider = FutureProvider.family<List<ChatHistory>, int>((
  ref,
  limit,
) async {
  return await client.chatHistory.getMyHistory(limit: limit);
});

final chatHistorySessionsProvider =
    FutureProvider.family<List<ChatSessionSummary>, int>((
  ref,
  limit,
) async {
  return await client.chatHistory.getMySessions(limit: limit);
});

final chatHistorySessionProvider =
    FutureProvider.family<List<ChatHistory>, String>((
  ref,
  sessionId,
) async {
  return await client.chatHistory.getSessionHistory(
    sessionId: sessionId,
    limit: 200,
  );
});

final chatHistoryDeleteProvider = FutureProvider.family<bool, String>((
  ref,
  sessionId,
) async {
  return await client.chatHistory.deleteSession(sessionId: sessionId);
});
