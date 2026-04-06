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
                "Hello! I'm your CITESched Assistant. I can help with schedules, teaching loads, timetables, room assignments, and conflict checks.",
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
              "Hello! I'm your CITESched Assistant. I can help with schedules, teaching loads, timetables, room assignments, and conflict checks.",
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

  void loadSessionHistory({
    required String sessionId,
    String? sessionTitle,
    required List<ChatHistory> history,
  }) {
    _pendingTimetable = false;
    final restoredMessages = history
        .map(
          (entry) => <String, dynamic>{
            'isUser': entry.sender == 'user',
            'text': entry.text,
          },
        )
        .toList();

    state = NLPQueryChatState(
      messages: restoredMessages,
      isLoading: false,
      sessionId: sessionId,
      sessionTitle: sessionTitle ?? state.sessionTitle,
    );
  }

  Future<void> sendQuery(String query) async {
    if (query.trim().isEmpty) return;

    final userQuery = query.trim();
    var outbound = _rewriteSimpleQuery(userQuery);
    final normalized = _normalizeQuery(outbound);
    if (_isTimetableQuery(normalized)) {
      _pendingTimetable = true;
      if (!_hasExplicitScheduleTarget(normalized) && !_isAdmin()) {
        outbound = _isStudent()
            ? 'section schedule $outbound'
            : 'my schedule $outbound';
      }
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        {'isUser': true, 'text': userQuery},
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
    return query.contains('timetable') ||
        query.contains('calendar') ||
        query.contains('weekly schedule');
  }

  bool _hasExplicitScheduleTarget(String query) {
    if (query.contains('my ')) return true;
    if (query.contains('our ')) return true;
    if (query.contains('section')) return true;
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

  String _rewriteSimpleQuery(String query) {
    var normalized = _normalizeQuery(query);
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    final isStudent = scopes.contains('student');
    final isFaculty = scopes.contains('faculty');

    final asksSchedule = RegExp(
      r'\b(schedule|schedules|class schedule|classes|timetable|calendar|routine)\b',
    ).hasMatch(normalized);
    final asksConflict = RegExp(r'\b(conflict|conflicts|overlap|clash)\b')
        .hasMatch(normalized);
    final asksLoad = RegExp(r'\b(load|units|teaching load)\b')
        .hasMatch(normalized);
    final asksRoom = RegExp(r'\b(room|classroom|venue)\b').hasMatch(normalized);
    final asksSection = RegExp(r'\b(section)\b').hasMatch(normalized);
    final hasDayContext = RegExp(
      r'\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    ).hasMatch(normalized);

    if (asksSchedule) {
      normalized = normalized
          .replaceAll('schedules', 'schedule')
          .replaceAll('timetable', 'weekly schedule')
          .replaceAll('calendar', 'weekly schedule')
          .replaceAll('routine', 'schedule');

      if (isStudent) {
        normalized = normalized
            .replaceAll('my schedule', 'section schedule')
            .replaceAll('my class schedule', 'section schedule')
            .replaceAll('my weekly schedule', 'section weekly schedule');
        if (!normalized.contains('section') && !asksSection) {
          normalized = 'section $normalized';
        }
      } else if (isFaculty && !normalized.contains('my')) {
        normalized = 'my $normalized';
      }

      if (hasDayContext && !normalized.contains('on ')) {
        normalized = normalized.replaceFirst(' schedule ', ' schedule on ');
      }
    }

    if (asksConflict) {
      normalized = isStudent
          ? 'check conflicts for section'
          : isFaculty
              ? 'check my teaching conflicts'
              : 'check conflicts';
    }

    if (isFaculty && asksLoad && !normalized.contains('teaching load')) {
      normalized = 'my teaching load';
    }

    if (isStudent && asksRoom) {
      final asksNextClass =
          normalized.contains('next') && normalized.contains('class');
      normalized = asksNextClass
          ? 'what is the next class for section'
          : 'show section schedule';
    }

    return normalized;
  }

  bool _isAdmin() {
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    return scopes.contains('admin');
  }

  bool _isStudent() {
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    return scopes.contains('student');
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
