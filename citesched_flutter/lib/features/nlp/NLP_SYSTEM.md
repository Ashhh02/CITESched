# CITESched NLP Floating Assistant - Complete Implementation Guide

## 🎯 System Overview

The NLP Floating Assistant is a **rule-based, deterministic natural language query system** integrated with CITESched's scheduling engine. It processes user queries in real-time and returns structured data from PostgreSQL via Serverpod.

### What It Is
✅ Real-time database query interface  
✅ Role-based access control (RBAC)  
✅ Structured response rendering  
✅ Production-grade security  
✅ Zero external dependencies  

### What It Is NOT
❌ ChatGPT or generative AI  
❌ Machine learning based  
❌ Dynamic SQL executor  
❌ Generic chatbot  
❌ External API dependent  

---

## 🏗️ Architecture

### Backend Flow
```
User Input (Flutter)
  ↓
NLP Endpoint (Serverpod)
  ↓
Authentication + Authorization
  ↓
Keyword Detection
  ↓
Service Method Mapping
  ↓
PostgreSQL ORM Query
  ↓
Structured Response
  ↓
Flutter Rendering
```

### System Components

#### 1. **Backend (Dart/Serverpod)**

**Endpoint**: `lib/src/endpoints/nlp_endpoint.dart`
- Authenticates session
- Validates input (1-500 chars, no forbidden keywords)
- Delegates to NLPService
- Returns NLPResponse

**Service**: `lib/src/services/nlp_service.dart`
- Implements role-based access control
- Routes queries to specialized handlers
- Executes real-time database queries
- Returns formatted responses

**Response Model**: `lib/src/generated/nlp_response.dart`
```dart
class NLPResponse {
  String text;                    // Human-readable response
  NLPIntent intent;              // Response type (conflict, schedule, etc.)
  List<Schedule>? schedules;     // Structured data
  String? dataJson;              // Metadata as JSON
}
```

#### 2. **Frontend (Flutter)**

**Service**: `lib/features/nlp/services/nlp_service.dart`
- Calls backend endpoint
- Handles authentication

**Chat Provider**: `lib/features/nlp/providers/nlp_chat_provider.dart`
- Manages chat state with Riverpod
- Parses responses
- Adds messages to chat

**UI Components**:
- `nlp_assistant_fab.dart` - Floating Action Button
- `nlp_chat_dialog.dart` - Chat modal dialog
- `message_bubble.dart` - Message rendering
- `response_display.dart` - Structured data display

---

## 📚 Supported Query Categories

### 1. Conflict Monitoring
**User Says**: "Show conflicts", "Any room conflicts?", "List schedule conflicts"

**Backend Does**:
- Queries Schedule table for time overlaps
- Filters by role (admin sees all, faculty/student see relevant)
- Counts room and faculty conflicts

**Response Type**: `conflict`
```json
{
  "type": "conflict",
  "count": 3,
  "room": 2,
  "faculty": 1
}
```

### 2. Faculty Overload Monitoring
**User Says**: "Who is overloaded?", "Show faculty overload"

**Backend Does**:
- Aggregates units per faculty
- Compares against maxLoad
- Shows overload percentage

**Response Type**: `facultyLoad`
```json
{
  "totalUnits": 24.0,
  "maxLoad": 20,
  "isOverloaded": true
}
```

### 3. My Schedule (Role-Based)
**User Says**: "Show my schedule", "My timetable"

**Backend Does**:
- Extracts authenticated user ID
- Fetches only that user's schedule
- Includes subject, faculty, room, timeslot

**Response Type**: `schedule`
```json
{
  "schedules": [
    {
      "subject": {...},
      "faculty": {...},
      "room": {...},
      "timeslot": {...}
    }
  ]
}
```

### 4. Room Availability
**User Says**: "Is Room 301 available?", "Check room availability Monday 10AM"

**Backend Does**:
- Finds room by name
- Returns current assignments
- Shows capacity

**Response Type**: `roomStatus`
```json
{
  "id": 5,
  "capacity": 50,
  "assigned": 3
}
```

### 5. Section Schedule
**User Says**: "Show BSIT 3A schedule", "Schedule for IT 2B"

**Backend Does**:
- Parses program/year/section
- Returns timetable entries
- Groups by day/time

**Response Type**: `schedule`

---

## 🔐 Security Implementation

### Authentication
```dart
final authInfo = await session.authenticated;
if (authInfo == null) {
  return unsupportedResponse();
}
```

### Authorization (Role-Based)
```dart
final isAdmin = scopes.contains('admin');
final isFaculty = scopes.contains('faculty');
final isStudent = scopes.contains('student');

// Query logic branches by role
if (isAdmin) {
  // See all data
} else if (isFaculty) {
  // See own data + department
} else if (isStudent) {
  // See only own section
}
```

### Input Validation
```dart
// Length check
if (text.length > 500) return error;

// Forbidden keywords
static const forbiddenKeywords = [
  'drop', 'delete', 'password', 'sql', 'schema', 'database', 'truncate', 'alter'
];

// Safe string matching
if (query.contains('delete')) return error;
```

### SQL Injection Prevention
```dart
// ❌ NEVER DO THIS:
await db.execute("SELECT * FROM schedules WHERE id = $userId");

// ✅ ALWAYS USE ORM:
await Schedule.db.find(
  session,
  where: (t) => t.facultyId.equals(userId),
);
```

---

## 🎨 Frontend Implementation

### 1. Floating Action Button
```dart
FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => NLPChatDialog(),
    );
  },
  child: Icon(Icons.smart_toy),
)
```

### 2. Chat Dialog
- Dark theme with maroon accent
- Scrollable message list
- Loading indicator
- Error message display
- Input field with send button

### 3. Message Bubbles
**User**: Right-aligned, maroon background
**Assistant**: Left-aligned, dark background with border

### 4. Response Display
Renders structured data:
- **Conflict**: Red card with summary
- **Overload**: Progress bar with percentage
- **Schedule**: Table with subject, faculty, room, time
- **Room**: Capacity and current usage

---

## 📊 Real-Time Behavior

The assistant always reflects live database state:

```dart
// Every query executes fresh ORM request
final schedules = await Schedule.db.find(session, ...);

// No caching
// No pagination delays
// Live faculty loads computed from current schedules
// Conflicts detected in real-time
```

**Example: Faculty Load Update Visibility**
1. Admin creates new schedule for Dr. Smith (+3 units)
2. User asks "Who is overloaded?"
3. System queries DB → finds Dr. Smith's schedules
4. Computes total units → shows updated load
5. Response shows LIVE data (not cached)

---

## 🚀 Quick Start

### Backend Setup
```bash
cd citesched_server

# Generate Serverpod code
serverpod generate

# Run migrations
dart run bin/main.dart --apply-migrations

# Server starts on http://localhost:8085
```

### Frontend Setup
```bash
cd citesched_flutter

# Run app
flutter run -d chrome --wasm
# or
flutter run -d android
# or
flutter run -d ios
```

### Test the NLP Assistant
1. Click the floating action button (💡 icon)
2. Type "Show conflicts"
3. See real-time conflict data
4. Try other queries:
   - "Who is overloaded?"
   - "Show my schedule"
   - "Is Room 301 available?"
   - "Schedule for IT 3A"

---

## 🔍 Query Detection

The system uses **keyword matching** to route queries:

```dart
if (query.contains('conflict')) {
  return await _handleConflictQuery(...);
} else if (query.contains('overload')) {
  return await _handleOverloadQuery(...);
} else if (query.contains('my schedule')) {
  return await _handleMyScheduleQuery(...);
} else if (query.contains('room') || query.contains('available')) {
  return await _handleRoomQuery(...);
} else if (query.contains('schedule')) {
  return await _handleScheduleQuery(...);
} else {
  return _unsupportedResponse();
}
```

---

## 💾 Data Structures

### NLPResponse
```dart
NLPResponse(
  text: "Human-readable response",
  intent: NLPIntent.conflict,  // Type of response
  schedules: [...],            // Raw schedule data
  dataJson: '{"count": 5}',   // Metadata
)
```

### ChatMessage (Flutter)
```dart
ChatMessage(
  id: UUID,
  text: "Message content",
  sender: MessageSender.user | .assistant,
  timestamp: DateTime,
  responseType: "conflict" | "schedule" | etc,
  metadata: Map<String, dynamic>,
)
```

---

## 📱 UI/UX Flow

1. **User taps FAB** → Dialog opens with welcome message
2. **User types query** → Input validated, sanitized
3. **User presses send** → Loading animation starts
4. **Backend processes** → Role-based query execution
5. **Response returns** → Parsed and displayed
6. **Structured UI renders** → Icons, colors, data formatted

### Response Formatting
- **Conflicts**: Red warning cards with count
- **Overload**: Progress bars with %), danger colors
- **Schedules**: Clean table layout
- **Availability**: Status indicators

---

## ⚠️ Error Handling

### User-Friendly Errors
```dart
"Invalid query. Please enter a query between 1-500 characters."
"You must be logged in to view your schedule."
"This query is not supported by the system."
"You are not authorized to perform this action."
```

### Server-Side Logging
```dart
session.log('NLP Query Error: $e');
// Logs to Serverpod but doesn't expose to user
```

---

## 🧪 Testing

### Test Cases

**Case 1: Authenticated Faculty Conflict Check**
- UserID: faculty-123
- Query: "show conflicts"
- Expected: Faculty's conflicts only (not system-wide)

**Case 2: Admin Overload Check**
- UserID: admin-1
- Query: "who is overloaded"
- Expected: All faculty loads with overload flags

**Case 3: Student Schedule**
- UserID: student-456
- Query: "my schedule"
- Expected: Student's section schedule only

**Case 4: Unauthorized Query**
- Query: "delete all schedules"
- Expected: Unsupported response

**Case 5: Empty Query**
- Query: ""
- Expected: Validation error

---

## 📦 Dependencies

### Backend
- `serverpod`: Server framework
- `serverpod_database_mysql`: Database ORM

### Frontend
- `citesched_client`: Auto-generated Serverpod client
- `flutter_riverpod`: State management
- `google_fonts`: Typography
- `uuid`: Unique IDs

---

## 🎓 Production Checklist

- [x] Authentication required
- [x] Role-based access control
- [x] Input validation
- [x] Forbidden keyword blocking
- [x] No raw SQL execution
- [x] Real-time database queries
- [x] Structured response types
- [x] Frontend error handling
- [x] Loading indicators
- [x] Session timeout handling
- [x] User-friendly messages
- [x] No chat history persistence
- [x] Mobile responsive UI

---

## 🔗 Useful Methods

### Backend (NLPService)
- `processQuery()` - Main entry point
- `_handleConflictQuery()` - Conflict detection
- `_handleMyScheduleQuery()` - Personal schedule
- `_handleOverloadQuery()` - Faculty load analysis
- `_handleRoomQuery()` - Room status
- `_handleScheduleQuery()` - Section timetable

### Frontend (NLPService)
- `queryNLP()` - Call backend endpoint
- `isAuthenticated()` - Check auth status
- `getAuthToken()` - Get JWT token

### Frontend (NLPChatNotifier)
- `sendQuery()` - Process user input
- `clearChat()` - Reset conversation
- `_addMessage()` - Add to chat
- `_parseMetadata()` - Parse JSON

---

## 🚦 Status Indicators

### Intent Colors
- **Conflict** (Red) - ⚠️ Issues detected
- **Overload** (Orange/Red) - 📊 Load warnings
- **Schedule** (Blue) - 📅 Class information
- **RoomStatus** (Teal) - 🏫 Room details
- **Unknown** (Gray) - ❓ Unsupported

---

## 📞 Support & Troubleshooting

### Issue: "Authentication required"
- Ensure user is logged in via main auth system
- Check JWT token validity
- Verify Serverpod session is active

### Issue: "This query is not supported"
- Query doesn't match any keyword patterns
- Forbidden word detected
- Check supported categories above

### Issue: "No data found"
- User's role doesn't have access to this data
- No matching records in database
- Check role-based filtering

### Issue: Backend error
- Check server logs: `Session.log()`
- Verify database connection
- Ensure migrations applied: `dart run bin/main.dart --apply-migrations`

---

## 🎯 Future Enhancements

- [ ] Teach mode: Show matched keywords
- [ ] Filtering: Advanced time/room filters
- [ ] Scheduling: Create schedules via NLP
- [ ] Export: Download conflict reports
- [ ] Analytics: Query statistics
- [ ] Customization: User preferences

---

## 📄 License & Attribution

CITESched Academic Scheduling System  
NLP Floating Assistant Module  
Built with Flutter + Dart + Serverpod  
Production-ready implementation 2026

