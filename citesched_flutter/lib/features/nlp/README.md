# NLP Floating Assistant Module - Implementation Guide

## Overview

The NLP Floating Assistant is a secure, rule-based Natural Language Query interface for CITESched that translates user queries into predefined system actions. It is **NOT** a generative AI chatbot—it's a controlled command router that maps keywords to authorized backend services.

## 🎯 Key Characteristics

✅ **Rule-Based**: Uses keyword matching and predefined logic
✅ **Secure**: JWT authentication, RBAC, input validation
✅ **Deterministic**: Same query always produces same result
✅ **Non-Generative**: No creative/open-ended responses
✅ **Role-Aware**: Respects user permissions automatically

❌ **Not**: ChatGPT, ML-based, generative AI, SQL-capable

## 📱 Frontend Architecture (Flutter)

### Components

#### 1. **NLPAssistantFAB** - FloatingActionButton
- Location: Bottom-right corner
- Icon: AI assistant icon (`Icons.smart_toy`)
- Color: Maroon (#720045)
- Action: Opens chat dialog on tap

```dart
NLPAssistantFAB(
  backgroundColor: Color(0xFF720045),
  foregroundColor: Colors.white,
)
```

#### 2. **NLPChatDialog** - Chat Interface
- Modal dialog containing:
  - Header with title and close button
  - Scrollable message list
  - Input field with send button
  - Loading indicator
  - Error messages

#### 3. **MessageBubble** - Message Display
- User messages: Right-aligned, maroon background
- Assistant messages: Left-aligned, dark background
- Response type indicators (conflict, overload, schedule, etc.)
- Metadata display for structured data

### Data Models

**ChatMessage**
```dart
class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;  // user or assistant
  final DateTime timestamp;
  final String? responseType;  // conflict, overload, schedule, availability
  final Map<String, dynamic>? metadata;
}
```

**NLPResponseModel**
```dart
class NLPResponseModel {
  final bool success;
  final String message;
  final String? type;  // conflict, overload, schedule, availability
  final Map<String, dynamic>? data;
}
```

### Providers & State Management

**NLPChatProvider** (StateNotifier)
- Manages chat message history
- Handles loading states and errors
- Sends queries to backend service
- No database persistence (session-only)

**NLPService**
- Communicates with backend NLP endpoint
- Handles JWT authentication
- Manages API calls

### Utilities

**NLPQueryParser**
- Input sanitization
- Query type detection
- Entity extraction (room, faculty, section names)

**NLPConstants**
- Keyword definitions
- Error messages
- Help text

## 🔐 Backend Architecture (Dart Server)

### Endpoint: `POST /api/nlp/query`

**Input**:
```json
{
  "query": "show conflicts"
}
```

**Output**:
```json
{
  "success": true,
  "message": "...",
  "type": "conflict",
  "data": { ... }
}
```

### Authentication & Security

All requests require:
1. ✅ Valid JWT token in `Authorization` header
2. ✅ Authenticated user in session
3. ✅ User role verification for RBAC

### NLPService: Query Processing

The service implements a keyword-driven state machine:

```
Query → Sanitize → Check Forbidden → Detect Type → Route Handler → Response
```

#### Query Types Supported

**1. My Schedule (All authenticated users)**
- Keywords: "my schedule", "my timetable", "my classes"
- Logic: Extracts user_id from JWT, returns their schedule only
- Faculty: Own teaching schedule
- Student: Own section schedule

**2. Conflict Detection (Admin only)**
- Keywords: "conflict", "issue"
- Logic: Calls ConflictService
- Returns: Conflict count, types, recommendations

**3. Faculty Overload (Admin only)**
- Keywords: "overload", "load"
- Logic: Calculates total units per faculty
- Returns: Alert if > maxLoad, comparison with limit

**4. Room Availability (All users)**
- Keywords: "room", "available", "free"
- Logic: Parses room name, returns occupancy
- Returns: Schedule, capacity, current usage

**5. Section Schedule (All users)**
- Keywords: "schedule", "timetable"
- Logic: Extracts section (e.g., "IT 3A"), queries database
- Returns: Class list with faculty, room, time

### Security Features

#### Input Validation
```dart
// Max length: 500 characters
if (query.isEmpty || query.length > 500) {
  return unsupportedResponse();
}
```

#### Forbidden Keywords
Always rejected (prevents injection attempts):
- `drop`, `delete`, `password`, `sql`, `schema`, `database`, `truncate`, `alter`

#### RBAC (Role-Based Access Control)
```dart
final isAdmin = scopes.contains('admin');
if (!isAdmin && queryNeedsAdmin) {
  return restrictedResponse();
}
```

#### No Dynamic SQL
- ✅ Uses parameterized ORM queries (Serverpod)
- ❌ Never concatenates user input
- ❌ Never executes raw SQL

#### Error Handling
- Internal errors logged but not exposed
- Sanitized error messages to client
- No stack traces revealed

## 🔄 Data Flow Example

### Example 1: Faculty asks for their schedule
```
🔹 User: "Show my schedule"
🔹 Flutter sends: POST /api/nlp/query with JWT token
🔹 Backend:
   - Authenticates (JWT valid ✓)
   - Detects type: "my_schedule"
   - Extracts userId from JWT
   - Queries: Schedule.db.find(where: facultyId == userId)
   - Returns structured response
🔹 Flutter renders:
   - Message bubble with "Found X classes"
   - Table of schedules if available
```

### Example 2: Admin checks for conflicts
```
🔹 Admin: "Show conflicts"
🔹 Backend:
   - Authenticates (JWT valid ✓)
   - Checks scope: admin ✓
   - Calls ConflictService.getAllConflicts()
   - Returns count, breakdown by type
🔹 Flutter displays:
   - Alert badge (red) with count
   - Breakdown: "X room conflicts, Y faculty conflicts"
```

### Example 3: Query with forbidden keyword
```
🔹 User: "Show me the password database"
🔹 Backend:
   - Detects forbidden keywords: "password", "database"
   - Returns: "This query is not supported"
🔹 Flutter: Shows error message
```

## 📊 Response Types

Each response includes a `type` field for rendering:

| Type | Icon | Color | Use Case |
|------|------|-------|----------|
| `conflict` | ⚠️ | Orange | Double bookings, overlaps |
| `overload` | ❌ | Red | Faculty exceeding maxLoad |
| `schedule` | 📅 | Blue | Class lists, timetables |
| `availability` | ✅ | Green | Room free/busy status |
| `facultyload` | 👤 | Purple | Faculty workload info |
| `roomstatus` | 🏫 | Teal | Room capacity/usage |

## 🚀 Integration Steps

### 1. Add FAB to Scaffold
```dart
Scaffold(
  floatingActionButton: const NLPAssistantFAB(),
  body: YourContent(),
)
```

### 2. Or use in AdminLayout (already integrated)
The admin layout already has the FAB and NLP query dialog.

### 3. Initialize Riverpod
Ensure `ProviderScope` wraps your app:
```dart
ProviderScope(
  child: MaterialApp(...)
)
```

## 🧪 Testing Queries

### Valid Queries
```
✅ "Show my schedule"
✅ "Any conflicts?"
✅ "Is room 301 available?"
✅ "What's the load of Prof. Smith?"
✅ "Schedule for IT 3A"
✅ "Faculty overload report"
```

### Rejected Queries
```
❌ "Show database password"
❌ "Delete all schedules"
❌ "Run this SQL: SELECT *"
❌ "Give me admin access"
❌ "" (empty)
✅ Responds: "This query is not supported"
```

## 📋 Implementation Checklist

### Backend
- [x] NLPEndpoint with JWT validation
- [x] NLPService with keyword detection
- [x] RBAC enforcement
- [x] Forbidden keyword filtering
- [x] All 5 query types
- [x] Error handling (no stack traces)
- [x] Input validation (length, format)

### Frontend
- [x] NLPAssistantFAB component
- [x] NLPChatDialog with UI
- [x] MessageBubble for display
- [x] NLPChatProvider (state management)
- [x] NLPQueryParser utilities
- [x] JWT token handling
- [x] Error display
- [x] Loading indicator
- [x] Auto-scroll on messages
- [x] No persistent storage

## 🔧 Configuration

### Customize Colors
```dart
NLPAssistantFAB(
  backgroundColor: Color(0xFF720045),  // Maroon
  foregroundColor: Colors.white,
)
```

### Customize Messages
Edit `NLPConstants`:
```dart
class NLPConstants {
  static const String defaultHelpMessage = "...";
  static const String unsupportedQueryMessage = "...";
}
```

### Add New Query Type
1. Add keyword check in `NLPService.processQuery()`
2. Create `_handleXyzQuery()` method
3. Add response type matching in `MessageBubble`
4. Test with sample queries

## ⚠️ Security Reminders

**DO:**
- ✅ Always validate JWT tokens
- ✅ Check user roles before sensitive data
- ✅ Log suspicious queries
- ✅ Use parameterized queries
- ✅ Hide internal errors

**DON'T:**
- ❌ Execute raw SQL from user input
- ❌ Bypass RBAC checks
- ❌ Expose database schema
- ❌ Return stack traces to clients
- ❌ Cache sensitive data

## 📞 Support & Limitations

**What this can do:**
- Answer schedule-related questions
- Detect conflicts and overloads
- Check room availability
- Provide faculty workload info

**What this cannot do:**
- Delete, modify, or create records
- Answer arbitrary questions
- Access external APIs
- Learn or adapt over time
- Provide personalized recommendations (beyond data queries)

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Status**: Production Ready
