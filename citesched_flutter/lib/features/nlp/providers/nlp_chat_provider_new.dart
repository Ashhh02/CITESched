import 'dart:convert';
import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/nlp/models/chat_message.dart';
import 'package:citesched_flutter/features/nlp/services/nlp_service.dart';
import 'package:citesched_flutter/features/nlp/utils/nlp_constants.dart';
import 'package:citesched_flutter/features/nlp/utils/nlp_query_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final nlpChatProvider = NotifierProvider<NLPChatNotifier, NLPChatState>(
  NLPChatNotifier.new,
);

class NLPChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  NLPChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  NLPChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return NLPChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NLPChatNotifier extends Notifier<NLPChatState> {
  bool _initialized = false;

  @override
  NLPChatState build() {
    Future.microtask(_initializeWelcome);
    return NLPChatState();
  }

  void _initializeWelcome() {
    if (!_initialized) {
      _addMessage(
        NLPConstants.defaultHelpMessage,
        MessageSender.assistant,
      );
      _initialized = true;
    }
  }

  /// Clears all messages from the chat history
  void clearChat() {
    state = NLPChatState();
  }

  /// Sends a user query to the NLP service
  Future<void> sendQuery(String userQuery) async {
    // Validate query
    if (!NLPQueryParser.isValidQuery(userQuery)) {
      _addMessage(
        'Please enter a valid query.',
        MessageSender.assistant,
      );
      return;
    }

    // Sanitize query
    final sanitizedQuery = NLPQueryParser.sanitizeQuery(userQuery);

    // Add user message
    _addMessage(sanitizedQuery, MessageSender.user);

    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call NLP service
      final response = await ref
          .read(nlpServiceProvider)
          .queryNLP(sanitizedQuery);

      // Add assistant response
      _addMessage(
        response.text,
        MessageSender.assistant,
        responseType: response.intent.name,
        metadata: response.dataJson != null
            ? _parseMetadata(response.dataJson!)
            : null,
        schedules: response.schedules,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('NLP Error: $e');
      _addMessage(
        'Sorry, I encountered an error processing your request. Please try again.',
        MessageSender.assistant,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Adds a message to the chat
  void _addMessage(
    String text,
    MessageSender sender, {
    String? responseType,
    Map<String, dynamic>? metadata,
    List<Schedule>? schedules,
  }) {
    final message = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      responseType: responseType,
      metadata: metadata,
    );

    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  /// Parses metadata from JSON string if available
  Map<String, dynamic>? _parseMetadata(String jsonStr) {
    if (jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('Failed to parse metadata: $e');
      return null;
    }
  }
}
