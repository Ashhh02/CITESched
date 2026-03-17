import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/nlp_service.dart';

class NLPEndpoint extends Endpoint {
  final _nlpService = NLPService();

  /// Processes natural language queries from authenticated users
  ///
  /// Requires:
  /// - Valid JWT authentication (enforced by Serverpod)
  /// - Query must be 1-500 characters
  ///
  /// Security:
  /// - Input validation (length checks)
  /// - Forbidden keyword filtering
  /// - Role-based access control (RBAC)
  /// - No dynamic SQL execution
  Future<NLPResponse> query(
    Session session,
    String text, {
    String? sessionId,
    String? sessionTitle,
  }) async {
    try {
      // Serverpod automatically enforces authentication
      final authInfo = session.authenticated;

      if (authInfo == null) {
        return NLPResponse(
          text: "Authentication required. Please log in.",
          intent: NLPIntent.unknown,
        );
      }

      // Input validation
      if (text.trim().isEmpty || text.length > 500) {
        return NLPResponse(
          text: "Invalid query. Please enter a query between 1-500 characters.",
          intent: NLPIntent.unknown,
        );
      }

      final resolvedSessionId = sessionId?.trim().isNotEmpty == true
          ? sessionId!.trim()
          : _generateSessionId();
      final role = _resolveRole(authInfo.scopes);
      final resolvedSessionTitle =
          sessionTitle?.trim().isNotEmpty == true
              ? sessionTitle!.trim()
              : _defaultSessionTitle(role);

      // Log user query
      await _logChatMessage(
        session,
        authInfo,
        sender: 'user',
        text: text,
        sessionId: resolvedSessionId,
        sessionTitle: resolvedSessionTitle,
      );

      // Process the query with RBAC
      final response = await _nlpService.processQuery(
        session,
        text,
        authInfo.userIdentifier,
        authInfo.scopes.map((s) => s.name).whereType<String>().toList(),
      );

      // Log assistant response
      await _logChatMessage(
        session,
        authInfo,
        sender: 'assistant',
        text: response.text,
        intent: response.intent.name,
        metadataJson: response.dataJson,
        sessionId: resolvedSessionId,
        sessionTitle: resolvedSessionTitle,
      );

      return response;
    } catch (e) {
      // Log error but don't expose details to client
      session.log('NLP Query Error: $e');

      return NLPResponse(
        text: "An error occurred processing your request. Please try again.",
        intent: NLPIntent.unknown,
      );
    }
  }

  Future<void> _logChatMessage(
    Session session,
    AuthenticationInfo authInfo, {
    required String sender,
    required String text,
    required String sessionId,
    required String sessionTitle,
    String? intent,
    String? metadataJson,
  }) async {
    final role = _resolveRole(authInfo.scopes);
    await ChatHistory.db.insertRow(
      session,
      ChatHistory(
        userId: authInfo.userIdentifier.toString(),
        role: role,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        sender: sender,
        text: text,
        intent: intent,
        metadataJson: metadataJson,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  String _resolveRole(Set<Scope> scopes) {
    if (scopes.any((s) => s.name == 'admin')) return 'admin';
    if (scopes.any((s) => s.name == 'faculty')) return 'faculty';
    if (scopes.any((s) => s.name == 'student')) return 'student';
    return 'unknown';
  }

  String _defaultSessionTitle(String role) {
    final now = DateTime.now();
    final dateLabel =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    switch (role) {
      case 'admin':
        return 'Admin Chat $dateLabel';
      case 'faculty':
        return 'Faculty Chat $dateLabel';
      case 'student':
        return 'Student Chat $dateLabel';
      default:
        return 'Chat $dateLabel';
    }
  }

  String _generateSessionId() {
    return 'chat_${DateTime.now().microsecondsSinceEpoch}';
  }
}
