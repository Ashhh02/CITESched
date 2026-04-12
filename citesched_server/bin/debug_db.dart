import 'package:citesched_server/src/generated/endpoints.dart';
import 'package:citesched_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

void main() async {
  var pod = Serverpod(
    ['--mode', 'development'],
    Protocol(),
    Endpoints(),
  );

  await pod.start();

  var session = await pod.createSession(enableLogging: false);

  try {
    var facultyList = await Faculty.db.find(session);
    print('--- FACULTY LIST ---');
    for (var f in facultyList) {
      print('ID: ${f.id}, Name: ${f.name}, maxLoad: ${f.maxLoad}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await session.close();
    await pod.shutdown();
  }
}
