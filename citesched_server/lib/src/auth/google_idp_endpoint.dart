import 'package:serverpod_auth_idp_server/providers/google.dart';
import 'package:serverpod/serverpod.dart';

/// By extending [GoogleIdpBaseEndpoint], the Google identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
class GoogleIdpEndpoint extends GoogleIdpBaseEndpoint {
  @override
  Future<AuthSuccess> login(
    Session session, {
    required String idToken,
    required String? accessToken,
  }) {
    // On web, Google popup auth can succeed while the extra access-token-backed
    // userinfo fetch remains flaky behind proxies. The ID token already carries
    // the fields we need for this app, so we intentionally authenticate with it
    // alone for a more reliable production flow.
    return super.login(
      session,
      idToken: idToken,
      accessToken: null,
    );
  }
}
