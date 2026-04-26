import 'dart:convert';

import 'package:serverpod/serverpod.dart';

class AppConfigWidget extends JsonWidget {
  final String apiUrl;
  final String? googleWebClientId;

  AppConfigWidget({
    required this.apiUrl,
    this.googleWebClientId,
  }) : super(
         object: {
           'apiUrl': apiUrl,
           if (googleWebClientId != null && googleWebClientId!.isNotEmpty)
             'googleWebClientId': googleWebClientId,
         },
       );
}

class AppConfigRoute extends WidgetRoute {
  AppConfigWidget widget;

  AppConfigRoute({
    required final ServerConfig apiConfig,
  }) : widget = AppConfigWidget(
         apiUrl: apiConfig.apiUrl.toString(),
         googleWebClientId: _resolveGoogleWebClientId(),
       );

  @override
  Future<WebWidget> build(Session session, Request request) async {
    return widget;
  }
}

extension on ServerConfig {
  Uri get apiUrl => Uri(
    scheme: publicScheme,
    host: publicHost,
    port: publicPort,
  );
}

String? _resolveGoogleWebClientId() {
  try {
    final rawSecret = Serverpod.instance.getPassword('googleClientSecret');
    if (rawSecret == null || rawSecret.trim().isEmpty) return null;

    final decoded = jsonDecode(rawSecret);
    if (decoded is! Map<String, dynamic>) return null;

    final webConfig = decoded['web'];
    if (webConfig is! Map<String, dynamic>) return null;

    final clientId = webConfig['client_id'];
    if (clientId is String && clientId.trim().isNotEmpty) {
      return clientId.trim();
    }
  } catch (_) {
    // Ignore malformed optional Google config and keep the app usable.
  }

  return null;
}
