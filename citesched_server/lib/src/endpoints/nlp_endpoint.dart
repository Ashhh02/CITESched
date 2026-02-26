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
  Future<NLPResponse> query(Session session, String text) async {
    try {
      // Serverpod automatically enforces authentication
      final authInfo = await session.authenticated;

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

      // Process the query with RBAC
      final response = await _nlpService.processQuery(
        session,
        text,
        authInfo.userIdentifier,
        authInfo.scopes.map((s) => s.toString()).toList(),
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
}
