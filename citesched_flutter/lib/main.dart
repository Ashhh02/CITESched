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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CITESched',
      theme: AppTheme.darkTheme,
      home: const RootScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
