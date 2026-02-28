import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allConflictsProvider = FutureProvider<List<ScheduleConflict>>((
  ref,
) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.admin.getAllConflicts();
});

extension ConflictListExtension on List<ScheduleConflict> {
  bool hasConflictForFaculty(int facultyId) {
    return any((c) => c.facultyId == facultyId);
  }

  bool hasConflictForRoom(int roomId) {
    return any((c) => c.roomId == roomId);
  }

  bool hasConflictForSubject(int subjectId) {
    return any((c) => c.subjectId == subjectId);
  }
}
