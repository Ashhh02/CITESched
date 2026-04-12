import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/nlp/models/chat_message.dart';
import 'package:citesched_flutter/features/nlp/widgets/response_display.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.sender == MessageSender.user;
    const maroonColor = Color(0xFF720045);

    if (isUserMessage) {
      return _buildUserBubble(context, maroonColor);
    } else {
      return _buildAssistantBubble(context, maroonColor);
    }
  }

  Widget _buildUserBubble(BuildContext context, Color maroonColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: maroonColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context, Color maroonColor) {
    const bubbleColor = Color(0xFF2a2a3e);

    // If we have a response type (and optional schedules), use the ResponseDisplay widget
    if (message.responseType != null &&
        (message.metadata != null || message.schedules != null)) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: Border.all(color: maroonColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ResponseDisplay(
            intent: _parseResponseIntent(message.responseType!),
            message: message.text,
            metadata: message.metadata ?? const {},
            schedules: message.schedules?.cast<Schedule>(),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: Border.all(color: maroonColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  NLPIntent _parseResponseIntent(String intentName) {
    try {
      return NLPIntent.values.firstWhere(
        (intent) => intent.name == intentName.toLowerCase(),
      );
    } catch (e) {
      return NLPIntent.unknown;
    }
  }
}
