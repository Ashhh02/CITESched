import 'dart:convert';

import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/utils/date_utils.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/admin/screens/conflict_screen.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/nlp_query_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

class NLPQueryDialog extends ConsumerStatefulWidget {
  const NLPQueryDialog({super.key});

  @override
  ConsumerState<NLPQueryDialog> createState() => _NLPQueryDialogState();
}

class _NLPQueryDialogState extends ConsumerState<NLPQueryDialog> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showHistory = false;
  double? _dialogWidth;
  double? _dialogHeight;
  String? _selectedSessionId;

  final Color maroonColor = const Color(0xFF720045);

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    _queryController.clear();
    await ref.read(nlpQueryChatProvider.notifier).sendQuery(query);
    _scrollToBottom();
  }

  void _scrollToBottom() {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return ListTile(
            title: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            trailing: const Icon(Icons.send, size: 18),
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(nlpQueryChatProvider);
    final sessionsAsync = ref.watch(chatHistorySessionsProvider(30));
    final historyAsync = _selectedSessionId == null
        ? null
        : ref.watch(chatHistorySessionProvider(_selectedSessionId!));
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width * 0.95;
    final maxHeight = media.size.height * 0.9;
    final minWidth = 360.0;
    final minHeight = 420.0;
    final width = (_dialogWidth ?? (media.size.width * 0.75)).clamp(
      minWidth,
      maxWidth,
    );
    final height = (_dialogHeight ?? (media.size.height * 0.75)).clamp(
      minHeight,
      maxHeight,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [maroonColor, const Color(0xFF9d005f)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CITESched AI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Powered by NLP Service',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                          TextButton.icon(
                            onPressed: _showSuggestions,
                            icon: const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white,
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
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(nlpQueryChatProvider.notifier)
                                  .clearChat();
                              setState(() {
                                _showHistory = false;
                                _selectedSessionId = null;
                              });
                            },
                            icon: const Icon(
                              Icons.add_comment,
                              color: Colors.white,
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
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chat Messages
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount:
                            chatState.messages.length +
                            (chatState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                            return _TypingIndicator(
                              maroonColor: maroonColor,
                            );
                          }

                          final msg = chatState.messages[index];
                          return _MessageBubble(
                            messageData: msg,
                            maroonColor: maroonColor,
                          );
                        },
                      ),
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

                // Input Area
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          onSubmitted: (_) => _sendQuery(),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Ask about schedules, rooms, load...",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: maroonColor,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: IconButton(
                          onPressed: chatState.isLoading ? null : _sendQuery,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
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
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: maroonColor.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Could not load history: $err',
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
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
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() => _selectedSessionId = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chat Details',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
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
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
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
                                      ? maroonColor
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isUser
                                        ? Colors.white
                                        : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : Colors.black87),
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroonColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Could not load history: $err',
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'No history yet.',
                style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = sessions[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: maroonColor.withOpacity(0.12),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    entry.lastMessageText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
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
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(nlpQueryChatProvider.notifier)
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
    this.sensitivity = 10.0,
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
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Container(
                  width: vertical ? 2 : 36,
                  height: vertical ? 36 : 2,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.6),
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
    this.sensitivity = 10.0,
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.drag_handle,
                size: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color maroonColor;
  const _TypingIndicator({required this.maroonColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: maroonColor.withOpacity(0.1),
            radius: 18,
            child: Icon(Icons.smart_toy_rounded, color: maroonColor, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _Dot(delay: i * 200, color: maroonColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  final Color color;
  const _Dot({required this.delay, required this.color});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3 + (0.7 * _animation.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final Color maroonColor;

  const _MessageBubble({
    required this.messageData,
    required this.maroonColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = messageData['isUser'] as bool;
    final isError = messageData['isError'] ?? false;
    final text = messageData['text'] as String;
    final schedules = messageData['schedules'] as List?;
    final dataJson = messageData['dataJson'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                CircleAvatar(
                  backgroundColor: maroonColor.withOpacity(0.1),
                  radius: 18,
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
              if (!isUser) const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? maroonColor
                        : (isError
                              ? Colors.red.withOpacity(0.05)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[100])),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isError
                        ? Border.all(color: Colors.red.withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.4,
                      color: isUser
                          ? Colors.white
                          : (isError
                                ? Colors.red[700]
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF2D3748))),
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 12),
              if (isUser)
                CircleAvatar(
                  backgroundColor: maroonColor.withOpacity(0.1),
                  radius: 18,
                  child: Icon(
                    Icons.person_rounded,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
            ],
          ),
          if (schedules != null && schedules.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildScheduleCards(context, schedules),
          ],
          if (schedules != null && schedules.isNotEmpty)
            _buildTimetablePreview(
              context,
              schedules,
              messageData['showTimetable'] == true,
            ),
          if (dataJson != null) ...[
            const SizedBox(height: 12),
            _buildDataSummary(context, dataJson),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCards(BuildContext context, List schedules) {
    return Padding(
      padding: const EdgeInsets.only(left: 48), // Align with bot bubble
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: schedules.map((s) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: maroonColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.subject?.name ?? 'Unknown Subject',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: maroonColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.room_outlined,
                        size: 10,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.room?.name ?? 'TBA',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 10,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          s.timeslot != null
                              ? CITESchedDateUtils.formatTimeslot(
                                  s.timeslot!.day,
                                  s.timeslot!.startTime,
                                  s.timeslot!.endTime,
                                )
                              : 'TBA',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataSummary(BuildContext context, String dataJson) {
    try {
      final data = jsonDecode(dataJson);
      if (data['count'] != null) {
        // This is a conflict summary
        return Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSmallChip(
                    context,
                    "Room: ${data['room']}",
                    Colors.orange,
                  ),
                  _buildSmallChip(
                    context,
                    "Faculty: ${data['faculty']}",
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if ((data['count'] as int? ?? 0) > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminLayout(initialIndex: 6),
                        ),
                      );
                    },
                    icon: const Icon(Icons.warning_rounded, size: 16),
                    label: Text(
                      'Resolve Conflicts',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    } catch (_) {}
    return const SizedBox();
  }

  Widget _buildTimetablePreview(
    BuildContext context,
    List schedules,
    bool showTimetable,
  ) {
    if (!showTimetable) return const SizedBox();
    final scheduleInfos = schedules
        .cast<Schedule>()
        .map((s) => ScheduleInfo(schedule: s, conflicts: const []))
        .toList();
    if (scheduleInfos.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timetable Preview',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: maroonColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: maroonColor.withOpacity(0.15)),
            ),
            child: WeeklyCalendarView(
              schedules: scheduleInfos,
              maroonColor: maroonColor,
              isStudentView: true,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenCalendarScaffold(
                    title: 'Timetable',
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8F9FA),
                    child: WeeklyCalendarView(
                      schedules: scheduleInfos,
                      maroonColor: maroonColor,
                      isStudentView: true,
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded, size: 14),
              label: Text(
                'Full Screen',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: maroonColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
