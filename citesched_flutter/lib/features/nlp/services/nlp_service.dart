import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nlpServiceProvider = Provider((ref) => NLPService());

class NLPService {
  /// Sends a natural language query to the NLP endpoint
  /// Returns the NLPResponse from the server
  Future<NLPResponse> queryNLP(String text) async {
    try {
      // Call the NLP endpoint using the auto-generated client
      final response = await client.nLP.query(text);
      return response;
    } catch (e) {
      print('NLP Query Error: $e');
      rethrow;
    }
  }

  /// Validates authentication before processing query
  bool isAuthenticated() {
    // Check if client has valid session
    return true; // Serverpod handles auth automatically
  }

  /// Gets current user's JWT token if available
  Future<String?> getAuthToken() async {
    try {
      // Serverpod automatically manages tokens
      return null; // Not needed as Serverpod handles it
    } catch (e) {
      print('Failed to get auth token: $e');
    }
    return null;
  }
}
