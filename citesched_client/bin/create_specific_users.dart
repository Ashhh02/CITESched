import 'package:citesched_client/citesched_client.dart';

void main() async {
  // Use correct port 8083 as per development.yaml
  var client = Client('http://localhost:8083/');
  client.connectivityMonitor = null;

  try {
    print('--------------------------------------------------');
    print('Creating Requested Faculty Account: Admin Test Account');
    print('--------------------------------------------------');

    var facultySuccess = await client.setup.createAccount(
      userName: 'Admin Test Account',
      email: 'admin.test@jmc.edu.ph',
      password: '12345',
      role: 'admin',
      facultyId: '12345',
    );

    if (facultySuccess) {
      print('SUCCESS: Created Faculty (Admin Test Account) with ID: 12345');
    } else {
      print('WARNING: Could not create Faculty (Admin Test Account).');
      print(
        'Reason: ID 12345 or email admin.test@jmc.edu.ph might already be taken.',
      );
    }

    print('\n--------------------------------------------------');
    print('Creating Requested Student Account: Student Test Account');
    print('--------------------------------------------------');

    var studentSuccess = await client.setup.createAccount(
      userName: 'Student Test Account',
      email: 'student.test@jmc.edu.ph',
      password: '12345',
      role: 'student',
      studentId: '99999',
    );

    if (studentSuccess) {
      print(
        'SUCCESS: Created Student (Student Test Account) with ID: 99999',
      );
    } else {
      print(
        'WARNING: Could not create Student (Student Test Account).',
      );
      print(
        'Reason: ID 99999 or email student.test@jmc.edu.ph might already be taken.',
      );
    }

    print('--------------------------------------------------');
  } catch (e) {
    print('Error: $e');
  }
}
