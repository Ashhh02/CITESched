import 'dart:convert';

import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/theme/app_theme.dart';
import 'package:citesched_flutter/features/auth/screens/root_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

const _defaultServerUrl = 'http://localhost:8083/';
const _serverUrlDefine = String.fromEnvironment('CITESCHED_SERVER_URL');
const _googleWebClientIdDefine = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const _configAssetPath = 'assets/config.json';

late final Client client;
const _startupStorage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appConfig = await _resolveAppConfig();
  final serverUrl = appConfig.apiUrl;
  client = Client(
    serverUrl,
    connectionTimeout: const Duration(minutes: 3),
  )
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  try {
    await client.auth.initialize();
  } catch (e) {
    debugPrint('Recovering from invalid stored auth session: $e');
    try {
      await _startupStorage.deleteAll();
    } catch (_) {}
    await client.auth.initialize();
  }
  final googleWebClientId = appConfig.googleWebClientId;
  if (googleWebClientId != null && googleWebClientId.isNotEmpty) {
    await client.auth.initializeGoogleSignIn(
      clientId: googleWebClientId,
    );
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<_AppConfig> _resolveAppConfig() async {
  String? configuredApiUrl;
  String? configuredGoogleWebClientId;

  if (_serverUrlDefine.isNotEmpty) {
    configuredApiUrl = _normalizeServerUrl(_serverUrlDefine);
  }
  if (_googleWebClientIdDefine.isNotEmpty) {
    configuredGoogleWebClientId = _googleWebClientIdDefine.trim();
  }

  try {
    final rawConfig = await rootBundle.loadString(_configAssetPath);
    final decoded = jsonDecode(rawConfig);
    if (decoded is Map<String, dynamic>) {
      final apiUrl = decoded['apiUrl'];
      if (configuredApiUrl == null &&
          apiUrl is String &&
          apiUrl.trim().isNotEmpty) {
        configuredApiUrl = _normalizeServerUrl(apiUrl);
      }

      final googleWebClientId = decoded['googleWebClientId'];
      if (configuredGoogleWebClientId == null &&
          googleWebClientId is String &&
          googleWebClientId.trim().isNotEmpty) {
        configuredGoogleWebClientId = googleWebClientId.trim();
      }
    }
  } catch (_) {
    // Fall back to the local development server if the asset is missing.
  }

  return _AppConfig(
    apiUrl: configuredApiUrl ?? _normalizeServerUrl(_defaultServerUrl),
    googleWebClientId: configuredGoogleWebClientId,
  );
}

String _normalizeServerUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('/')) return trimmed;
  return '$trimmed/';
}

class _AppConfig {
  final String apiUrl;
  final String? googleWebClientId;

  const _AppConfig({
    required this.apiUrl,
    required this.googleWebClientId,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  double _adaptiveTextScale(double width) {
    if (width < 360) return 0.88;
    if (width < 600) return 0.94;
    if (width < 900) return 0.98;
    if (width < 1400) return 1.0;
    return 1.04;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'CITESched',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const RootScreen(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scale = _adaptiveTextScale(media.size.width);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
