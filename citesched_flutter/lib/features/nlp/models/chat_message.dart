enum MessageSender { user, assistant }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String? responseType; // conflict, overload, schedule, availability
  final Map<String, dynamic>? metadata; // For structured data

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.responseType,
    this.metadata,
  });
}
