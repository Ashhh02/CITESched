import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/logout_confirmation_dialog.dart';
import 'package:citesched_flutter/core/widgets/nlp_query_dialog.dart';
import 'package:citesched_flutter/core/widgets/draggable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLayout extends ConsumerWidget {
  final Widget child;
  final String title;

  const AppLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maroonColor = const Color(0xFF4f003b);

    final scaffold = Scaffold(
      body: child,
    );

    return Stack(
      children: [
        scaffold,
        DraggableFab(
          child: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NLPQueryDialog(),
              );
            },
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Ask Me!'),
            tooltip: 'Hey ask me some questions!',
          ),
        ),
      ],
    );
  }

  static void showLogoutConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmationDialog(),
    );

    if (confirm == true) {
      ref.read(authProvider.notifier).signOut();
    }
  }
}
