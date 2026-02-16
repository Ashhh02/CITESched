import 'package:citesched_client/citesched_client.dart';

void main() async {
  // Use correct port 8083 as per development.yaml
  var client = Client('http://localhost:8083/');
  client.connectivityMonitor = null;

  try {
    print('--------------------------------------------------');
    print('Creating Requested Faculty Account: Ryan Billera');
    print('--------------------------------------------------');

    var facultySuccess = await client.setup.createAccount(
      userName: 'Ryan Billera',
      email: 'ryan.billera@jmc.edu.ph',
      password: '12345',
      role: 'admin',
      facultyId: '12345',
    );

    if (facultySuccess) {
      print('SUCCESS: Created Faculty (Ryan Billera) with ID: 12345');
    } else {
      print('WARNING: Could not create Faculty (Ryan Billera).');
      print(
        'Reason: ID 12345 or email ryan.billera@jmc.edu.ph might already be taken.',
      );
    }

    print('\n--------------------------------------------------');
    print('Creating Requested Student Account: Nash Andrew Quilario Cabillon');
    print('--------------------------------------------------');

    var studentSuccess = await client.setup.createAccount(
      userName: 'Nash Andrew Quilario Cabillon',
      email: 'nash.cabillon@jmc.edu.ph',
      password: '4shyn.zyyy',
      role: 'student',
      studentId: '107690',
    );

    if (studentSuccess) {
      print(
        'SUCCESS: Created Student (Nash Andrew Quilario Cabillon) with ID: 107690',
      );
    } else {
      print(
        'WARNING: Could not create Student (Nash Andrew Quilario Cabillon).',
      );
      print(
        'Reason: ID 107690 or email nash.cabillon@jmc.edu.ph might already be taken.',
      );
    }

    print('--------------------------------------------------');
  } catch (e) {
    print('Error: $e');
  }
}
