import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/theme/app_theme.dart';
import 'package:citesched_flutter/features/auth/screens/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

// Global client definition
var client = Client('http://$localhost:8083/')
  ..connectivityMonitor = FlutterConnectivityMonitor()
  ..authSessionManager = FlutterAuthSessionManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await client.auth.initialize();

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
    return MaterialApp(
      title: 'CITESched',
      theme: AppTheme.darkTheme,
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
  }
}
