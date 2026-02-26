import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final facultyListProvider = FutureProvider<List<Faculty>>((ref) async {
  return await client.admin.getAllFaculty(isActive: true);
});

final archivedFacultyListProvider = FutureProvider<List<Faculty>>((ref) async {
  return await client.admin.getAllFaculty(isActive: false);
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return await client.admin.getAllSubjects(isActive: true);
});

final archivedSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return await client.admin.getAllSubjects(isActive: false);
});

final roomListProvider = FutureProvider<List<Room>>((ref) async {
  return await client.admin.getAllRooms(isActive: true);
});

final archivedRoomListProvider = FutureProvider<List<Room>>((ref) async {
  return await client.admin.getAllRooms(isActive: false);
});

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  return await client.admin.getAllStudents(isActive: true);
});

final archivedStudentsProvider = FutureProvider<List<Student>>((ref) async {
  return await client.admin.getAllStudents(isActive: false);
});

final timeslotsProvider = FutureProvider<List<Timeslot>>((ref) async {
  return await client.admin.getAllTimeslots();
});

// Sections
final sectionListProvider = FutureProvider<List<Section>>((ref) async {
  return await client.admin.getAllSections();
});

final schedulesProvider = FutureProvider<List<Schedule>>((ref) async {
  return await client.admin.getAllSchedules();
});
