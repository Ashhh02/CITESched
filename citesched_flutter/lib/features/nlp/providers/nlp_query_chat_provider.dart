import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nlpQueryChatProvider =
    NotifierProvider<NLPQueryChatNotifier, NLPQueryChatState>(
  NLPQueryChatNotifier.new,
);

class NLPQueryChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? sessionId;
  final String? sessionTitle;

  NLPQueryChatState({
    this.messages = const [],
    this.isLoading = false,
    this.sessionId,
    this.sessionTitle,
  });

  NLPQueryChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? sessionId,
    String? sessionTitle,
  }) {
    return NLPQueryChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
    );
  }
}

class NLPQueryChatNotifier extends Notifier<NLPQueryChatState> {
  bool _initialized = false;
  bool _pendingTimetable = false;

  @override
  NLPQueryChatState build() {
    if (!_initialized) {
      _initialized = true;
      return NLPQueryChatState(
        messages: [
          {
            'isUser': false,
            'text':
                "Hello! I'm your CITESched Assistant. I can help you find schedules, check room availability, or (for admins) analyze conflicts and faculty load.",
          },
        ],
        sessionId: _generateSessionId(),
        sessionTitle: _generateSessionTitle(),
      );
    }
    return NLPQueryChatState();
  }

  void clearChat() {
    _pendingTimetable = false;
    state = NLPQueryChatState(
      messages: [
        {
          'isUser': false,
          'text':
              "Hello! I'm your CITESched Assistant. I can help you find schedules, check room availability, or (for admins) analyze conflicts and faculty load.",
        },
      ],
      isLoading: false,
      sessionId: _generateSessionId(),
      sessionTitle: _generateSessionTitle(),
    );
  }

  void setActiveSession(String sessionId, String? sessionTitle) {
    _pendingTimetable = false;
    state = state.copyWith(
      sessionId: sessionId,
      sessionTitle: sessionTitle ?? state.sessionTitle,
    );
  }

  Future<void> sendQuery(String query) async {
    if (query.trim().isEmpty) return;

    final normalized = _normalizeQuery(query);
    var outbound = query.trim();
    if (_isTimetableQuery(normalized)) {
      _pendingTimetable = true;
      if (!_hasExplicitScheduleTarget(normalized) && !_isAdmin()) {
        outbound = 'my schedule $outbound';
      }
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        {'isUser': true, 'text': outbound},
      ],
      isLoading: true,
    );

    try {
      final response = await client.nLP.query(
        outbound,
        sessionId: state.sessionId,
        sessionTitle: state.sessionTitle,
      );
      final dataJson = response.dataJson;
      final message = {
        'isUser': false,
        'text': response.text,
        'intent': response.intent,
        'schedules': response.schedules,
        'dataJson': dataJson,
      };
      if (_pendingTimetable) {
        message['showTimetable'] = true;
        _pendingTimetable = false;
      }
      state = state.copyWith(
        messages: [
          ...state.messages,
          message,
        ],
        isLoading: false,
      );
      ref.invalidate(chatHistorySessionsProvider);
      if (state.sessionId != null) {
        ref.invalidate(chatHistorySessionProvider(state.sessionId!));
      }
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          {
            'isUser': false,
            'text':
                "I encountered an error while processing your request. Please try again later.",
            'isError': true,
          },
        ],
        isLoading: false,
      );
      ref.invalidate(chatHistorySessionsProvider);
      if (state.sessionId != null) {
        ref.invalidate(chatHistorySessionProvider(state.sessionId!));
      }
    }
  }

  bool _isTimetableQuery(String query) {
    return query.contains('timetable') || query.contains('calendar');
  }

  bool _hasExplicitScheduleTarget(String query) {
    if (query.contains('my ')) return true;
    if (query.contains('prof') ||
        query.contains('sir') ||
        query.contains('maam')) {
      return true;
    }
    final sectionRegex = RegExp(r'\b([a-zA-Z]{1,4})?\s?\d[a-zA-Z]\b');
    return sectionRegex.hasMatch(query);
  }

  String _normalizeQuery(String query) {
    return query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isAdmin() {
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    return scopes.contains('admin');
  }

  String _generateSessionId() {
    return 'chat_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _generateSessionTitle() {
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    final now = DateTime.now();
    final dateLabel =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (scopes.contains('admin')) return 'Admin Chat $dateLabel';
    if (scopes.contains('faculty')) return 'Faculty Chat $dateLabel';
    if (scopes.contains('student')) return 'Student Chat $dateLabel';
    return 'Chat $dateLabel';
  }
}
