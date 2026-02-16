import 'dart:io';
import 'package:citesched_server/server.dart';
import 'package:citesched_server/src/generated/endpoints.dart';
import 'package:citesched_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

void main(List<String> args) async {
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  final session = await pod.createSession(enableLogging: true);
  final file = File('inspection_output.txt');
  final sink = file.openWrite();

  try {
    sink.writeln('--- UserRoles ---');
    var roles = await UserRole.db.find(session);
    for (var role in roles) {
      sink.writeln('User ID: ${role.userId}, Role: ${role.role}');
    }

    sink.writeln('\n--- Faculty ---');
    var faculty = await Faculty.db.find(session);
    for (var f in faculty) {
      sink.writeln(
        'Name: ${f.name}, Email: ${f.email}, UserInfoId: ${f.userInfoId}',
      );
    }

    // Attempt to join info
    sink.writeln('\n--- Analysis ---');
    for (var f in faculty) {
      var role = roles
          .where((r) => r.userId == f.userInfoId.toString())
          .firstOrNull;
      sink.writeln(
        'Faculty ${f.name} (${f.email}) -> Role: ${role?.role ?? "NONE"}',
      );
    }
  } catch (e) {
    sink.writeln('Error: $e');
  } finally {
    await sink.flush();
    await sink.close();
    await session.close();
    await pod.shutdown();
  }
}
