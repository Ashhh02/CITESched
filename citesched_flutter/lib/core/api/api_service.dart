import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final studentScheduleProvider = FutureProvider<List<Schedule>>((ref) async {
  ref.watch(scheduleSyncTriggerProvider);
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchMySchedule();
});

final studentProfileProvider = FutureProvider<Student?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchStudentProfile();
});

class ApiService {
  Future<Student?> fetchStudentProfile() async {
    try {
      return await client.student.getMyProfile();
    } catch (e) {
      return null;
    }
  }

  Future<List<Schedule>> fetchMySchedule() async {
    try {
      return await client.studentSchedule.fetchMySchedule();
    } catch (e) {
      rethrow;
    }
  }
}
