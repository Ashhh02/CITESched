import 'package:citesched_flutter/features/nlp/widgets/nlp_chat_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NLPAssistantFAB extends ConsumerWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;

  const NLPAssistantFAB({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maroonColor = backgroundColor ?? const Color(0xFF720045);
    final iconColor = foregroundColor ?? Colors.white;

    return Tooltip(
      message: 'Open AI Assistant',
      child: FloatingActionButton(
        backgroundColor: maroonColor,
        foregroundColor: iconColor,
        shape: const CircleBorder(),
        elevation: 8,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const NLPChatDialog(),
            barrierDismissible: true,
          );
        },
        child: const Icon(
          Icons.smart_toy,
          size: 28,
        ),
      ),
    );
  }
}
