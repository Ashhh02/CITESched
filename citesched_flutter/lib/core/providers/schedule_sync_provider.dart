import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global cache-buster for schedule-related data across modules.
class ScheduleSyncTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final scheduleSyncTriggerProvider =
    NotifierProvider<ScheduleSyncTriggerNotifier, int>(
      ScheduleSyncTriggerNotifier.new,
    );

void notifyScheduleDataChanged(WidgetRef ref) {
  ref.read(scheduleSyncTriggerProvider.notifier).bump();
}
