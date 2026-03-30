import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/theme/app_theme.dart';
import 'package:citesched_flutter/features/auth/screens/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

// Global client definition
var client = Client('http://$localhost:8083/')
  ..connectivityMonitor = FlutterConnectivityMonitor()
  ..authSessionManager = FlutterAuthSessionManager();

const _googleWebClientId =
    '787281029476-efu9h96a0libvk8o0ubhsluh7u09fnen.apps.googleusercontent.com';
const _startupStorage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await client.auth.initialize();
  } catch (e) {
    debugPrint('Recovering from invalid stored auth session: $e');
    try {
      await _startupStorage.deleteAll();
    } catch (_) {}
    try {
      await client.auth.signOutDevice();
    } catch (_) {}
    await client.auth.initialize();
  }
  await client.auth.initializeGoogleSignIn(
    clientId: _googleWebClientId,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
