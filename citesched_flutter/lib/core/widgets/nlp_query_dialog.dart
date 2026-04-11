import 'dart:convert';

import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/utils/date_utils.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
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
  bool _showSuggestionsPanel = false;
  double? _dialogWidth;
  double? _dialogHeight;
  String? _selectedSessionId;

  final Color maroonColor = const Color(0xFF720045);

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    _queryController.clear();
    setState(() {
      _showSuggestionsPanel = false;
    });
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

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
      _showSuggestionsPanel = false;
      _selectedSessionId = null;
    });
  }

  void _toggleSuggestions() {
    setState(() {
      _showSuggestionsPanel = !_showSuggestionsPanel;
      _showHistory = false;
      _selectedSessionId = null;
    });
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
        'Show my teaching load this term',
        'Show my timetable for this week',
        'Do I have any schedule conflicts?',
        'What is my next class?',
      ];
    }
    return [
      'Show our section schedule',
      'Show our class timetable this week',
      'Where is my next class?',
      'Do we have any schedule conflicts?',
      'Which room is assigned for our next class?',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(nlpQueryChatProvider);
    final sessionsAsync = ref.watch(chatHistorySessionsProvider(30));
    final historyAsync = _watchSelectedHistory();
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _dialogBackground(isDark);
    final bounds = _dialogBounds(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: bounds.width,
        height: bounds.height,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            _buildDialogContent(
              auth: auth,
              isDark: isDark,
              messages: chatState.messages,
              isLoading: chatState.isLoading,
              sessionsAsync: sessionsAsync,
              historyAsync: historyAsync,
            ),
            ..._buildResizeHandles(bounds),
          ],
        ),
      ),
    );
  }

  AsyncValue<List<ChatHistory>>? _watchSelectedHistory() {
    final selectedSessionId = _selectedSessionId;
    if (selectedSessionId == null) return null;
    return ref.watch(chatHistorySessionProvider(selectedSessionId));
  }

  Color _dialogBackground(bool isDark) {
    return isDark ? const Color(0xFF1E293B) : Colors.white;
  }

  _DialogBounds _dialogBounds(BuildContext context) {
    final media = MediaQuery.of(context);
    const minWidth = 360.0;
    const minHeight = 420.0;
    final maxWidth = media.size.width * 0.95;
    final maxHeight = media.size.height * 0.9;
    final width = (_dialogWidth ?? (media.size.width * 0.75)).clamp(
      minWidth,
      maxWidth,
    );
    final height = (_dialogHeight ?? (media.size.height * 0.75)).clamp(
      minHeight,
      maxHeight,
    );
    return _DialogBounds(
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      width: width,
      height: height,
    );
  }

  Widget _buildDialogContent({
    required UserInfo? auth,
    required bool isDark,
    required List<Map<String, dynamic>> messages,
    required bool isLoading,
    required AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    required AsyncValue<List<ChatHistory>>? historyAsync,
  }) {
    return Column(
      children: [
        _buildDialogHeader(auth),
        _buildChatMessagesArea(messages, isLoading, sessionsAsync, historyAsync),
        _buildInputArea(isDark, isLoading),
      ],
    );
  }

  Widget _buildDialogHeader(UserInfo? auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [maroonColor, const Color(0xFF9d005f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth < 700
              ? _buildCompactHeader(context, auth)
              : _buildWideHeader(context, auth);
        },
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context, UserInfo? auth) {
    final actionButtons = _buildHeaderActions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _toggleHistory,
              tooltip: _historyLabel(auth),
              icon: Icon(
                _showHistory ? Icons.chat_bubble_outline : Icons.history,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildHeaderTitle()),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: actionButtons,
          ),
        ),
      ],
    );
  }

  Widget _buildWideHeader(BuildContext context, UserInfo? auth) {
    final actionButtons = _buildHeaderActions();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: _toggleHistory,
          tooltip: _historyLabel(auth),
          icon: Icon(
            _showHistory ? Icons.chat_bubble_outline : Icons.history,
            color: Colors.white,
          ),
        ),
        const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildHeaderTitle()),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...actionButtons,
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessagesArea(
    List<Map<String, dynamic>> messages,
    bool isLoading,
    AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    AsyncValue<List<ChatHistory>>? historyAsync,
  ) {
    return Expanded(
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return _TypingIndicator(maroonColor: maroonColor);
              }

              final msg = messages[index];
              return _MessageBubble(messageData: msg, maroonColor: maroonColor);
            },
          ),
          if (_showHistory)
            Align(
              alignment: Alignment.centerRight,
              child: _buildHistoryPanel(sessionsAsync, historyAsync),
            ),
          if (_showSuggestionsPanel)
            Align(
              alignment: Alignment.centerRight,
              child: _buildSuggestionsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
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
                    ? Colors.white.withValues(alpha: 0.05)
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
              onPressed: isLoading ? null : _sendQuery,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResizeHandles(_DialogBounds bounds) {
    return [
      _ResizeEdge(
        alignment: Alignment.centerLeft,
        cursor: SystemMouseCursors.resizeLeftRight,
        onDrag: (delta) {
          setState(() {
            _dialogWidth =
                (bounds.width - delta.dx).clamp(bounds.minWidth, bounds.maxWidth);
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
            _dialogWidth =
                (bounds.width + delta.dx).clamp(bounds.minWidth, bounds.maxWidth);
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
            _dialogHeight =
                (bounds.height - delta.dy).clamp(bounds.minHeight, bounds.maxHeight);
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
            _dialogHeight =
                (bounds.height + delta.dy).clamp(bounds.minHeight, bounds.maxHeight);
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
            _dialogWidth =
                (bounds.width - delta.dx).clamp(bounds.minWidth, bounds.maxWidth);
            _dialogHeight =
                (bounds.height - delta.dy).clamp(bounds.minHeight, bounds.maxHeight);
          });
        },
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.topRight,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        onDrag: (delta) {
          setState(() {
            _dialogWidth =
                (bounds.width + delta.dx).clamp(bounds.minWidth, bounds.maxWidth);
            _dialogHeight =
                (bounds.height - delta.dy).clamp(bounds.minHeight, bounds.maxHeight);
          });
        },
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.bottomLeft,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        onDrag: (delta) {
          setState(() {
            _dialogWidth =
                (bounds.width - delta.dx).clamp(bounds.minWidth, bounds.maxWidth);
            _dialogHeight =
                (bounds.height + delta.dy).clamp(bounds.minHeight, bounds.maxHeight);
          });
        },
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.bottomRight,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        onDrag: (delta) {
          setState(() {
            _dialogWidth =
                (bounds.width + delta.dx).clamp(bounds.minWidth, bounds.maxWidth);
            _dialogHeight =
                (bounds.height + delta.dy).clamp(bounds.minHeight, bounds.maxHeight);
          });
        },
        color: maroonColor,
      ),
    ];
  }

  Widget _buildHeaderTitle() {
    return Column(
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
    );
  }

  List<Widget> _buildHeaderActions() {
    return [
      TextButton.icon(
        onPressed: _toggleSuggestions,
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
          ref.read(nlpQueryChatProvider.notifier).clearChat();
          setState(() {
            _showHistory = false;
            _showSuggestionsPanel = false;
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
    ];
  }

  String _historyLabel(UserInfo? auth) {
    final scopes = auth?.scopeNames ?? const [];
    if (scopes.contains('admin')) return 'Admin History';
    if (scopes.contains('faculty')) return 'Faculty History';
    if (scopes.contains('student')) return 'Student History';
    return 'History';
  }

  Widget _buildSuggestionsPanel() {
    final suggestions = _roleSuggestions();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: maroonColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Suggested Queries',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSuggestionsPanel = false;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final text = suggestions[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  title: Text(
                    text,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  trailing: Icon(Icons.send_rounded, color: maroonColor, size: 18),
                  onTap: () {
                    _queryController.text = text;
                    _sendQuery();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(
    AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    AsyncValue<List<ChatHistory>>? historyAsync,
  ) {
    if (_selectedSessionId != null && historyAsync != null) {
      return _buildPanelContainer(
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildHistoryStatusText('Could not load history: $err'),
          data: _buildHistoryDetailsBody,
        ),
      );
    }

    return _buildPanelContainer(
      sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildHistoryStatusText('Could not load history: $err'),
        data: _buildSessionsBody,
      ),
    );
  }

  Widget _buildPanelContainer(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHistoryStatusText(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
      ),
    );
  }

  Widget _buildHistoryDetailsBody(List<ChatHistory> items) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedSessionId = null),
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
                onPressed: _deleteSelectedSession,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? _buildHistoryStatusText('No messages in this chat.')
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryMessageBubble(items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryMessageBubble(ChatHistory entry) {
    final isUser = entry.sender == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messageColor = isUser
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: isUser
              ? maroonColor
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          entry.text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: messageColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsBody(List<ChatSessionSummary> sessions) {
    if (sessions.isEmpty) return _buildHistoryStatusText('No history yet.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildSessionTile(sessions[index]),
    );
  }

  Widget _buildSessionTile(ChatSessionSummary entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
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
              onPressed: () => _deleteSession(entry.sessionId),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _openSession(entry),
      ),
    );
  }

  Future<void> _deleteSelectedSession() async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) return;
    await _deleteSession(sessionId);
    if (!mounted) return;
    setState(() => _selectedSessionId = null);
  }

  Future<void> _deleteSession(String sessionId) async {
    await ref.read(chatHistoryDeleteProvider(sessionId).future);
    ref.invalidate(chatHistorySessionsProvider);
    ref.invalidate(chatHistorySessionProvider);
    if (!mounted) return;
    if (_selectedSessionId == sessionId) {
      setState(() => _selectedSessionId = null);
    }
  }

  Future<void> _openSession(ChatSessionSummary entry) async {
    final historyItems = await ref.read(
      chatHistorySessionProvider(entry.sessionId).future,
    );
    if (!mounted) return;
    ref.read(nlpQueryChatProvider.notifier).loadSessionHistory(
          sessionId: entry.sessionId,
          sessionTitle: entry.title,
          history: historyItems,
        );
    setState(() {
      _showHistory = false;
      _showSuggestionsPanel = false;
      _selectedSessionId = entry.sessionId;
    });
    _scrollToBottom();
  }
}

class _DialogBounds {
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final double width;
  final double height;

  const _DialogBounds({
    required this.minWidth,
    required this.minHeight,
    required this.maxWidth,
    required this.maxHeight,
    required this.width,
    required this.height,
  });
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
                color: color.withValues(alpha: 0.12),
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
            backgroundColor: maroonColor.withValues(alpha: 0.1),
            radius: 18,
            child: Icon(Icons.smart_toy_rounded, color: maroonColor, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
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
            color: widget.color.withValues(alpha: 0.3 + (0.7 * _animation.value)),
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
          _buildMessageRow(context, isUser, isError, text),
          ..._buildMessageExtras(context, schedules, dataJson),
        ],
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context,
    bool isUser,
    bool isError,
    String text,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) _buildBotAvatar(),
        if (!isUser) const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bubbleColor(isUser, isError, isDark),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              border: isError ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
            ),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
                color: _bubbleTextColor(isUser, isError, isDark),
              ),
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 12),
        if (isUser) _buildUserAvatar(),
      ],
    );
  }

  List<Widget> _buildMessageExtras(
    BuildContext context,
    List? schedules,
    String? dataJson,
  ) {
    final widgets = <Widget>[];
    final hasSchedules = schedules != null && schedules.isNotEmpty;

    if (hasSchedules) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildScheduleCards(context, schedules));
      widgets.add(
        _buildTimetablePreview(
          context,
          schedules,
          messageData['showTimetable'] == true,
        ),
      );
    }

    if (dataJson != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildDataSummary(context, dataJson));
    }

    return widgets;
  }

  Widget _buildBotAvatar() {
    return CircleAvatar(
      backgroundColor: maroonColor.withValues(alpha: 0.1),
      radius: 18,
      child: Icon(Icons.smart_toy_rounded, color: maroonColor, size: 20),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      backgroundColor: maroonColor.withValues(alpha: 0.1),
      radius: 18,
      child: Icon(Icons.person_rounded, color: maroonColor, size: 20),
    );
  }

  Color _bubbleColor(bool isUser, bool isError, bool isDark) {
    if (isUser) return maroonColor;
    if (isError) return Colors.red.withValues(alpha: 0.05);
    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100]!;
  }

  Color _bubbleTextColor(bool isUser, bool isError, bool isDark) {
    if (isUser) return Colors.white;
    if (isError) return Colors.red.shade700;
    return isDark ? Colors.white : const Color(0xFF2D3748);
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
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: maroonColor.withValues(alpha: 0.1),
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
    final data = _parseSummaryData(dataJson);
    if (data == null || data['count'] == null) return const SizedBox();

    final count = data['count'] as int? ?? 0;
    final room = data['room'];
    final faculty = data['faculty'];

    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallChip(context, "Room: $room", Colors.orange),
              _buildSmallChip(context, "Faculty: $faculty", Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          if (count > 0) _buildResolveConflictButton(context),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseSummaryData(String dataJson) {
    try {
      final parsed = jsonDecode(dataJson);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }

  Widget _buildResolveConflictButton(BuildContext context) {
    return Align(
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
    );
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: maroonColor.withValues(alpha: 0.15)),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
