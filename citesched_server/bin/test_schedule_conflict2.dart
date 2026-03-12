import 'package:citesched_server/src/generated/protocol.dart';
import 'package:citesched_server/src/generated/endpoints.dart';
import 'package:citesched_server/src/services/conflict_service.dart';
import 'package:serverpod/serverpod.dart';

void main() async {
  var pod = Serverpod(
    ['--mode', 'development'],
    Protocol(),
    Endpoints(),
  );

  var session = await pod.createSession(enableLogging: true);

  try {
    var facultyList = await Faculty.db.find(session);
    for (var f in facultyList) {
      print('DB Faculty: ID=\${f.id}, Name=\${f.name}, maxLoad=\${f.maxLoad}');
    }

    var scheduleList = await Schedule.db.find(session);
    print('DB Schedules Count: \${scheduleList.length}');

    var schedule = Schedule(
      subjectId: 1,
      facultyId: 2,
      section: 'A',
      units: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    print('Validating dummy schedule with units=null...');
    var conflicts = await ConflictService().validateSchedule(session, schedule);
    if (conflicts.isNotEmpty) {
      for (var c in conflicts) {
        print('- \${c.message}');
      }
    } else {
      print('No conflicts!');
    }
  } catch (e) {
    print('Error in diagnostic: \$e');
  } finally {
    await session.close();
  }
}
