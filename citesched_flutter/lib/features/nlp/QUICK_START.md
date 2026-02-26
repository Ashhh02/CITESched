# NLP Assistant - Quick Start Guide

## 🚀 Getting Started (5 minutes)

### Step 1: Add FAB to Your Screen

```dart
import 'package:citesched_flutter/features/nlp/nlp.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: const Center(child: Text('Content here')),
      floatingActionButton: const NLPAssistantFAB(),  // ← Add this line
    );
  }
}
```

### Step 2: Users Click the AI Button

The FAB in bottom-right corner opens a chat dialog.

### Step 3: Users Type Queries

Supported examples:
- "Show my schedule"
- "Any conflicts?"
- "Is Room 301 available?"
- "Faculty overload"
- "Schedule for IT 3A"

### Done! 🎉

The system handles everything else:
- ✅ Sends to backend with JWT
- ✅ Parses response
- ✅ Displays formatted results

---

## 📚 Common Use Cases

### Use Case 1: Add to Admin Dashboard
```dart
// In AdminLayout or AdminDashboardScreen
Scaffold(
  floatingActionButton: const NLPAssistantFAB(),
  body: YourAdminContent(),
)
```

### Use Case 2: Custom Styling
```dart
NLPAssistantFAB(
  backgroundColor: Colors.deepPurple,
  foregroundColor: Colors.white,
)
```

### Use Case 3: Programmatically Open Chat
```dart
// Open the chat dialog programmatically
showDialog(
  context: context,
  builder: (context) => const NLPChatDialog(),
);
```

### Use Case 4: Listen to Chat State
```dart
final chatState = ref.watch(nlpChatProvider);
print('Message count: ${chatState.messages.length}');
print('Is loading: ${chatState.isLoading}');
```

### Use Case 5: Send Query Programmatically
```dart
ref.read(nlpChatProvider.notifier).sendQuery('Show conflicts');
```

### Use Case 6: Check Messages
```dart
final chatState = ref.watch(nlpChatProvider);
for (var message in chatState.messages) {
  print('${message.sender}: ${message.text}');
}
```

---

## 🔌 Adding New Query Types

Want to support a new type of query? Follow this 4-step process:

### Step 1: Update Backend Service

In `citesched_server/lib/src/services/nlp_service.dart`:

```dart
Future<NLPResponse> processQuery(...) async {
  // ... existing code ...
  
  // Add detection for new query type
  if (lowerQuery.contains('new keyword') || 
      lowerQuery.contains('another keyword')) {
    if (!isAdmin && needsAdminAccess) {
      return restrictedResponse();
    }
    return await _handleNewQueryType(session, lowerQuery);
  }
  
  // ... rest of code ...
}

// Add handler method
Future<NLPResponse> _handleNewQueryType(
  Session session,
  String query,
) async {
  try {
    // Your logic here
    final data = await SomeModel.db.find(session);
    
    return NLPResponse(
      text: "Result of your query",
      intent: NLPIntent.newType,  // Add to enum if needed
      schedules: data,  // or other response data
    );
  } catch (e) {
    print('Error: $e');
    return NLPResponse(
      text: "An error occurred",
      intent: NLPIntent.newType,
    );
  }
}
```

### Step 2: Update Query Parser (Optional)

In `lib/features/nlp/utils/nlp_query_parser.dart`:

```dart
static String? detectQueryType(String query) {
  final lowerQuery = query.toLowerCase();
  
  // ... existing checks ...
  
  // Add detection for new type
  if (containsKeywords(lowerQuery, ['keyword1', 'keyword2'])) {
    return 'new_type';
  }
  
  return null;
}
```

### Step 3: Update Message Bubble (Optional)

In `lib/features/nlp/widgets/message_bubble.dart`:

```dart
String _getResponseTypeLabel(String type) {
  switch (type.toLowerCase()) {
    // ... existing cases ...
    case 'newtype':
      return 'New Type Label';
    default:
      return type;
  }
}

IconData _getResponseTypeIcon(String type) {
  switch (type.toLowerCase()) {
    // ... existing cases ...
    case 'newtype':
      return Icons.new_icon;
    default:
      return Icons.info;
  }
}

Color _getResponseTypeColor(String type) {
  switch (type.toLowerCase()) {
    // ... existing cases ...
    case 'newtype':
      return Colors.cyan;  // Custom color
    default:
      return Colors.grey;
  }
}
```

### Step 4: Update Constants (Optional)

In `lib/features/nlp/utils/nlp_constants.dart`:

```dart
class NLPConstants {
  static const List<String> newTypeKeywords = [
    'keyword1',
    'keyword2',
    'keyword3',
  ];
  // ... rest of code ...
}
```

### Example: Adding "Teacher Stats" Query

```dart
// Step 1: Backend handler
Future<NLPResponse> _handleTeacherStatsQuery(
  Session session,
  String query,
) async {
  final teachers = await Faculty.db.find(session);
  
  var stats = {
    'total': teachers.length,
    'avgLoad': teachers.fold(0.0, (sum, f) => sum + (f.maxLoad ?? 0)) / teachers.length,
  };
  
  return NLPResponse(
    text: 'Faculty Statistics: ${stats['total']} teachers, '
          'Average max load: ${stats['avgLoad'].toStringAsFixed(1)} units',
    intent: NLPIntent.schedule,  // Use existing intent
    dataJson: jsonEncode(stats),
  );
}

// Step 2: Detection in processQuery()
if (lowerQuery.contains('teacher stats') || 
    lowerQuery.contains('faculty stats')) {
  if (!isAdmin) return restrictedResponse();
  return await _handleTeacherStatsQuery(session, lowerQuery);
}

// Step 3: Update UI (in message_bubble.dart)
Color _getResponseTypeColor(String type) {
  // ... teachers queries would show with custom color
  return Colors.blueAccent;
}

// Test it:
User: "Show teacher stats"
System: "Faculty Statistics: 45 teachers, Average max load: 18.5 units"
```

---

## 🧪 Testing Queries

### Test Environment Setup
```bash
# Make sure server is running
cd citesched_server
dart run bin/main.dart --apply-migrations

# Server runs on http://localhost:8083
# Flutter connects to this endpoint
```

### Manual Testing in Flutter

Open the chat dialog and try these:

**Basic Tests**
```
✅ "Show my schedule" → Personal schedule
✅ "Show conflicts" → Conflict list (admin only)
✅ "Is room 301 available?" → Room status
✅ "Schedule for IT 3A" → Section timetable
✅ "Who is overloaded?" → Overloaded faculty (admin)
```

**Edge Cases**
```
✅ "" (empty) → "Please enter a valid query"
✅ "a" * 501 → Rejected (too long)
✅ "delete database" → "This query is not supported"
✅ "show password" → "This query is not supported"
✅ "SELECT * FROM users" → "This query is not supported"
```

**Role-Based Tests**
```
Faculty User:
✅ "Show my schedule" → Works
❌ "Show conflicts" → "Access restricted"

Admin User:
✅ "Show my schedule" → Works  
✅ "Show conflicts" → Works
✅ "Faculty overload" → Works

Student User:
✅ "Show my schedule" → Works
❌ "Show conflicts" → "Access restricted"
```

### Automated Testing (Unit Tests)

```dart
// test/features/nlp/services/nlp_service_test.dart
import 'package:citesched_flutter/features/nlp/nlp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NLPQueryParser', () {
    test('should validate non-empty query', () {
      expect(NLPQueryParser.isValidQuery('test'), true);
      expect(NLPQueryParser.isValidQuery(''), false);
      expect(NLPQueryParser.isValidQuery('   '), false);
    });

    test('should detect query types', () {
      expect(
        NLPQueryParser.detectQueryType('show conflicts'),
        'conflict',
      );
      expect(
        NLPQueryParser.detectQueryType('my schedule'),
        'my_schedule',
      );
      expect(
        NLPQueryParser.detectQueryType('room 301'),
        'availability',
      );
    });

    test('should sanitize input', () {
      expect(
        NLPQueryParser.sanitizeQuery('  hello   world  '),
        'hello world',
      );
    });

    test('should extract section', () {
      expect(
        NLPQueryParser.extractSection('Schedule for IT 3A'),
        'IT 3A',
      );
    });
  });
}
```

Run tests:
```bash
flutter test
```

---

## 🐛 Debugging

### Enable Debug Logging

In `lib/features/nlp/services/nlp_service.dart`:

```dart
class NLPService {
  static const bool DEBUG = true;  // Set to true
  
  Future<NLPResponse> queryNLP(String text) async {
    if (DEBUG) print('Sending query: $text');
    // ...
  }
}
```

### Check Request/Response

```dart
// In browser DevTools (for web) or Android Studio (for mobile)
// Look for network requests to /api/nlp/query
// Check request headers:
//   Authorization: Bearer <jwt_token>
//   Content-Type: application/json
// Check response body structure
```

### Troubleshooting

**Problem**: Chat dialog doesn't open
```dart
// Make sure you're using ConsumerWidget/ConsumerStatefulWidget
class MyScreen extends ConsumerWidget {  // ✅ Not StatelessWidget
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: const NLPAssistantFAB(),
    );
  }
}
```

**Problem**: Queries not being sent
```dart
// Check that auth is initialized
// In main.dart:
await client.auth.initialize();

// Make sure user is logged in:
final authState = ref.watch(authProvider);
if (authState == null) {
  print('User not authenticated');
}
```

**Problem**: Getting "Unauthorized" response
```dart
// JWT token might be expired or invalid
// Try logging out and logging back in:
ref.read(authProvider.notifier).signOut();

// Check token validity in console
```

**Problem**: Backend returns wrong response
```dart
// Check NLP endpoint in server logs:
// tail -f logs/serverpod.log

// Verify query is reaching the right handler:
// Add debug prints in nlp_service.dart
print('Detected query type: $type');
print('Is admin: $isAdmin');
```

---

## 📖 Full Documentation

- [README.md](README.md) - Complete feature documentation
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - What was built
- [SECURITY_ARCHITECTURE.md](SECURITY_ARCHITECTURE.md) - Security deep dive

---

## 💡 Pro Tips

1. **Use Response Types**: The response type indicates how to interpret the data
   ```dart
   if (message.responseType == 'conflict') {
     // Render conflict-specific UI
   }
   ```

2. **Handle Metadata**: Complex responses include structured data
   ```dart
   if (message.metadata != null) {
     final count = message.metadata!['count'];
     // Use the data
   }
   ```

3. **Clear History**: Reset chat when needed
   ```dart
   ref.read(nlpChatProvider.notifier).clearChat();
   ```

4. **Customize Messages**: Edit `NLPConstants` for app-specific text

5. **Role-Aware Features**: Leverage RBAC in your UI
   ```dart
   final isAdmin = ref.watch(authProvider)?.scopeNames.contains('admin') ?? false;
   if (isAdmin) {
     // Show admin-specific UI
   }
   ```

---

## ❓ FAQ

**Q: Can I customize the FAB appearance?**
A: Yes! Use constructor parameters in `NLPAssistantFAB`

**Q: Is chat history saved?**
A: No. It's session-only for privacy. Cleared when dialog closes.

**Q: Can non-admins ask about conflicts?**
A: No. RBAC prevents it and returns a safe error message.

**Q: How do I add a new supported query?**
A: Follow the 4-step guide above in "Adding New Query Types"

**Q: What happens if server is down?**
A: User sees "An error occurred" message. Check connection and try again.

**Q: Can I use this without Riverpod?**
A: Not currently. Would require refactoring state management.

**Q: Is the chat encrypted?**
A: Transmitted over HTTPS (encrypted), stored in memory (not persistent).

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Status**: ✅ Production Ready
