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
    final maroonColor = const Color(0xFF720045);

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
    final bubbleColor = const Color(0xFF2a2a3e);

    // If we have a response type and metadata, use the ResponseDisplay widget
    if (message.responseType != null && message.metadata != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: Border.all(color: maroonColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ResponseDisplay(
            intent: _parseResponseIntent(message.responseType!),
            message: message.text,
            metadata: message.metadata,
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
          border: Border.all(color: maroonColor.withOpacity(0.3)),
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

  Widget _buildResponseTypeIndicator(String type, Color maroonColor) {
    final label = _getResponseTypeLabel(type);
    final icon = _getResponseTypeIcon(type);
    final color = _getResponseTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataWidget(
    BuildContext context,
    Map<String, dynamic> metadata,
    Color maroonColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: maroonColor.withOpacity(0.1),
        border: Border.all(color: maroonColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${entry.key}: ${_formatMetadataValue(entry.value)}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getResponseTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'conflict':
        return 'Conflict Alert';
      case 'overload':
        return 'Overload Warning';
      case 'schedule':
        return 'Schedule';
      case 'availability':
        return 'Availability';
      case 'facultyload':
        return 'Faculty Load';
      case 'roomstatus':
        return 'Room Status';
      default:
        return type;
    }
  }

  IconData _getResponseTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'conflict':
        return Icons.warning;
      case 'overload':
        return Icons.error;
      case 'schedule':
        return Icons.schedule;
      case 'availability':
        return Icons.check_circle;
      case 'facultyload':
        return Icons.person;
      case 'roomstatus':
        return Icons.meeting_room;
      default:
        return Icons.info;
    }
  }

  Color _getResponseTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'conflict':
        return Colors.orange;
      case 'overload':
        return Colors.red;
      case 'schedule':
        return Colors.blue;
      case 'availability':
        return Colors.green;
      case 'facultyload':
        return Colors.purple;
      case 'roomstatus':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatMetadataValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
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
