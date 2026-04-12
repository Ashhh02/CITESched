import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/nlp_chat_provider.dart';
import 'package:citesched_flutter/features/nlp/utils/nlp_constants.dart';
import 'package:citesched_flutter/features/nlp/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

class NLPChatDialog extends ConsumerStatefulWidget {
  const NLPChatDialog({super.key});

  @override
  ConsumerState<NLPChatDialog> createState() => _NLPChatDialogState();
}

class _NLPChatDialogState extends ConsumerState<NLPChatDialog> {
  late TextEditingController _queryController;
  late ScrollController _scrollController;
  double? _dialogWidth;
  double? _dialogHeight;
  bool _showHistory = false;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(nlpChatProvider);
    final sessionsAsync = ref.watch(chatHistorySessionsProvider(30));
    final historyAsync = _selectedSessionId == null
        ? null
        : ref.watch(chatHistorySessionProvider(_selectedSessionId!));
    final auth = ref.watch(authProvider);
    const maroonColor = Color(0xFF720045);
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width * 0.95;
    final maxHeight = media.size.height * 0.9;
    const preferredMinWidth = 360.0;
    const preferredMinHeight = 420.0;
    final minWidth = maxWidth < preferredMinWidth
        ? maxWidth
        : preferredMinWidth;
    final minHeight = maxHeight < preferredMinHeight
        ? maxHeight
        : preferredMinHeight;
    final width = (_dialogWidth ?? (media.size.width * 0.85)).clamp(
      minWidth,
      maxWidth,
    );
    final height = (_dialogHeight ?? (media.size.height * 0.7)).clamp(
      minHeight,
      maxHeight,
    );

    return Dialog(
      backgroundColor: const Color(0xFF1e1e2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e2e),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroonColor.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: maroonColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'CITESched Assistant',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showHistory = !_showHistory;
                                _selectedSessionId = null;
                              });
                            },
                            icon: Icon(
                              _showHistory ? Icons.chat_bubble : Icons.history,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              _showHistory ? 'Chat' : _historyLabel(auth),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _showSuggestions,
                            icon: const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              'Suggest',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(nlpChatProvider.notifier).clearChat();
                              setState(() {
                                _showHistory = false;
                                _selectedSessionId = null;
                              });
                            },
                            icon: const Icon(
                              Icons.add_comment,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              'New Chat',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chat Messages Area
                Expanded(
                  child: Stack(
                    children: [
                      (chatState.messages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  NLPConstants.defaultHelpMessage,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: chatState.messages.length,
                              itemBuilder: (context, index) {
                                final message = chatState.messages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: MessageBubble(
                                    message: message,
                                  ),
                                );
                              },
                            )),
                      if (_showHistory)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildHistoryPanel(
                            sessionsAsync,
                            historyAsync,
                          ),
                        ),
                    ],
                  ),
                ),

                // Loading Indicator
                if (!_showHistory && chatState.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              maroonColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing your request...',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error Message
                if (!_showHistory && chatState.error != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: ${chatState.error}',
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Input Field
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: maroonColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: maroonColor.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: maroonColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            enabled: !chatState.isLoading,
                          ),
                          enabled: !chatState.isLoading,
                          maxLines: 1,
                          onSubmitted: (_) => _sendQuery(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          color: maroonColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: chatState.isLoading ? null : _sendQuery,
                          tooltip: 'Send',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _ResizeEdge(
              alignment: Alignment.centerLeft,
              cursor: SystemMouseCursors.resizeLeftRight,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogWidth = (width - delta.dx).clamp(minWidth, maxWidth);
                });
              },
              vertical: true,
              color: maroonColor,
            ),
            _ResizeEdge(
              alignment: Alignment.centerRight,
              cursor: SystemMouseCursors.resizeLeftRight,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogWidth = (width + delta.dx).clamp(minWidth, maxWidth);
                });
              },
              vertical: true,
              color: maroonColor,
            ),
            _ResizeEdge(
              alignment: Alignment.topCenter,
              cursor: SystemMouseCursors.resizeUpDown,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogHeight = (height - delta.dy).clamp(
                    minHeight,
                    maxHeight,
                  );
                });
              },
              vertical: false,
              color: maroonColor,
            ),
            _ResizeEdge(
              alignment: Alignment.bottomCenter,
              cursor: SystemMouseCursors.resizeUpDown,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogHeight = (height + delta.dy).clamp(
                    minHeight,
                    maxHeight,
                  );
                });
              },
              vertical: false,
              color: maroonColor,
            ),
            _ResizeCorner(
              alignment: Alignment.topLeft,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogWidth = (width - delta.dx).clamp(minWidth, maxWidth);
                  _dialogHeight = (height - delta.dy).clamp(
                    minHeight,
                    maxHeight,
                  );
                });
              },
              color: maroonColor,
            ),
            _ResizeCorner(
              alignment: Alignment.topRight,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogWidth = (width + delta.dx).clamp(minWidth, maxWidth);
                  _dialogHeight = (height - delta.dy).clamp(
                    minHeight,
                    maxHeight,
                  );
                });
              },
              color: maroonColor,
            ),
            _ResizeCorner(
              alignment: Alignment.bottomLeft,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogWidth = (width - delta.dx).clamp(minWidth, maxWidth);
                  _dialogHeight = (height + delta.dy).clamp(
                    minHeight,
                    maxHeight,
                  );
                });
              },
              color: maroonColor,
            ),
            _ResizeCorner(
              alignment: Alignment.bottomRight,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              sensitivity: 1,
              onDrag: (delta) {
                setState(() {
                  _dialogWidth = (width + delta.dx).clamp(minWidth, maxWidth);
                  _dialogHeight = (height + delta.dy).clamp(
                    minHeight,
                    maxHeight,
                  );
                });
              },
              color: maroonColor,
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return;
    }

    _queryController.clear();
    ref.read(nlpChatProvider.notifier).sendQuery(query);

    // Auto-scroll to bottom after slight delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSuggestions() {
    final suggestions = _roleSuggestions();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Colors.white12),
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return ListTile(
            title: Text(
              text,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
            trailing: const Icon(Icons.send, color: Colors.white54, size: 18),
            onTap: () {
              Navigator.of(context).pop();
              _queryController.text = text;
              _sendQuery();
            },
          );
        },
      ),
    );
  }

  List<String> _roleSuggestions() {
    final scopes = ref.read(authProvider)?.scopeNames ?? const [];
    if (scopes.contains('admin')) {
      return [
        'Generate schedule',
        'Show schedule conflicts',
        'Find free room',
      ];
    }
    if (scopes.contains('faculty')) {
      return [
        'Show my schedule',
        'What is my next class?',
        'Am I free at 10 AM?',
      ];
    }
    return [
      'Show my schedule',
      'What classes do I have today?',
      'Where is my next class?',
    ];
  }

  String _historyLabel(UserInfo? auth) {
    final scopes = auth?.scopeNames ?? const [];
    if (scopes.contains('admin')) return 'Admin History';
    if (scopes.contains('faculty')) return 'Faculty History';
    if (scopes.contains('student')) return 'Student History';
    return 'History';
  }

  Widget _buildHistoryPanel(
    AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    AsyncValue<List<ChatHistory>>? historyAsync,
  ) {
    if (_selectedSessionId != null && historyAsync != null) {
      return Container(
        width: 320,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161624),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Could not load history: $err',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ),
          data: (items) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _selectedSessionId = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chat Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white70,
                        ),
                        onPressed: () async {
                          final sessionId = _selectedSessionId;
                          if (sessionId == null) return;
                          await ref.read(
                            chatHistoryDeleteProvider(sessionId).future,
                          );
                          ref.invalidate(chatHistorySessionsProvider);
                          ref.invalidate(chatHistorySessionProvider);
                          setState(() => _selectedSessionId = null);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'No messages in this chat.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final entry = items[index];
                            final isUser = entry.sender == 'user';
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(
                                  maxWidth: 240,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF720045)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isUser
                                      ? null
                                      : Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  entry.text,
                                  style: GoogleFonts.poppins(
                                    color: isUser
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161624),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Could not load history: $err',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'No history yet.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = sessions[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    entry.lastMessageText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () async {
                          await ref.read(
                            chatHistoryDeleteProvider(entry.sessionId).future,
                          );
                          ref.invalidate(chatHistorySessionsProvider);
                          ref.invalidate(chatHistorySessionProvider);
                          if (_selectedSessionId == entry.sessionId) {
                            setState(() => _selectedSessionId = null);
                          }
                        },
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(nlpChatProvider.notifier)
                        .setActiveSession(
                          entry.sessionId,
                          entry.title,
                        );
                    setState(() => _selectedSessionId = entry.sessionId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ResizeEdge extends StatelessWidget {
  final Alignment alignment;
  final MouseCursor cursor;
  final void Function(Offset delta) onDrag;
  final bool vertical;
  final Color color;
  final double sensitivity;

  const _ResizeEdge({
    required this.alignment,
    required this.cursor,
    required this.onDrag,
    required this.vertical,
    required this.color,
    required this.sensitivity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) => onDrag(details.delta * sensitivity),
            child: Container(
              width: vertical ? 12 : 80,
              height: vertical ? 80 : 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Container(
                  width: vertical ? 2 : 36,
                  height: vertical ? 36 : 2,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeCorner extends StatelessWidget {
  final Alignment alignment;
  final MouseCursor cursor;
  final void Function(Offset delta) onDrag;
  final Color color;
  final double sensitivity;

  const _ResizeCorner({
    required this.alignment,
    required this.cursor,
    required this.onDrag,
    required this.color,
    required this.sensitivity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) => onDrag(details.delta * sensitivity),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.drag_handle,
                size: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
