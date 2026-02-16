import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class DebugEndpoint extends Endpoint {
  @override
  bool get requireLogin => false; // Allow public access to debug why auth fails

  Future<String> getSessionInfo(Session session) async {
    var authInfo = await session.authenticated;
    var userId = authInfo?.userIdentifier;
    var scopes = authInfo?.scopes.map((s) => s.name).toList();

    String? userRoleEntry;
    if (userId != null) {
      var userRole = await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userId.toString()),
      );
      userRoleEntry = userRole?.toString();
    }

    var info = {
      'authenticatedUserId': userId,
      'scopes': scopes,
      'userRoleTableEntry': userRoleEntry,
      'sessionDetails':
          'Session is ${authInfo == null ? "NOT" : ""} authenticated',
    };

    return SerializationManager.encode(info);
  }
}
