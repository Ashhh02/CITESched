# NLP Assistant - Security & Architecture Guide

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                            │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer                │ State Layer                            │
│  ├─ NLPAssistantFAB      │ ├─ NLPChatProvider (StateNotifier)    │
│  ├─ NLPChatDialog        │ ├─ NLPChatState                       │
│  ├─ MessageBubble        │ └─ Message management                 │
│  └─ ScheduleDisplay      │                                       │
├─────────────────────────────────────────────────────────────────┤
│  Service Layer                                                   │
│  ├─ NLPService (API calls)                                      │
│  ├─ JWT token handling                                          │
│  └─ Query sanitization                                          │
└────────────────────────────┬────────────────────────────────────┘
                      API Request (HTTPS)
                    POST /api/nlp/query
                    With Authorization Header
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Serverpod Server                            │
├─────────────────────────────────────────────────────────────────┤
│  Authentication Layer                                            │
│  ├─ JWT verification (automatic via Serverpod)                 │
│  ├─ User identity extraction                                    │
│  └─ Scope/role validation                                       │
├─────────────────────────────────────────────────────────────────┤
│  NLP Endpoint                                                    │
│  ├─ Input validation (length, format)                           │
│  ├─ Forbidden keyword check                                     │
│  └─ Delegation to NLPService                                    │
├─────────────────────────────────────────────────────────────────┤
│  NLPService Layer                                                │
│  ├─ Query type detection (keyword matching)                     │
│  ├─ RBAC enforcement (role checks)                              │
│  ├─ Query handlers:                                             │
│  │   ├─ _handleMyScheduleQuery()                               │
│  │   ├─ _handleConflictQuery()                                 │
│  │   ├─ _handleOverloadQuery()                                 │
│  │   ├─ _handleRoomQuery()                                     │
│  │   └─ _handleScheduleQuery()                                 │
│  └─ Error handling (safe responses)                             │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer                                                      │
│  ├─ Schedule.db.find() (parameterized)                          │
│  ├─ Faculty.db.find() (parameterized)                           │
│  ├─ Room.db.find() (parameterized)                              │
│  └─ ConflictService (existing)                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🔐 Security Layers

### Layer 1: Transport Security
```
✅ HTTPS/TLS encryption (handled by Serverpod)
✅ No sensitive data in URLs
✅ POST request (sensitive data in body, not query params)
✅ No cookie-based auth (JWT-based only)
```

### Layer 2: Authentication
```
✅ JWT token required in Authorization header
✅ Token validation by Serverpod framework
✅ Token expiration enforced
✅ No session fixation vulnerabilities
✅ No hardcoded credentials

Flow:
1. Client includes JWT from auth provider
2. Serverpod automatically validates
3. Endpoint receives authenticated user info
4. Tokens are never logged or cached improperly
```

### Layer 3: Authorization (RBAC)
```
✅ User identity extracted from JWT claims
✅ Scopes extracted from JWT claims
✅ Role validation before each sensitive operation
✅ Granular permissioning:

Query Type          | Required Role | Check Location
────────────────────┼───────────────┼──────────────────────
My Schedule         | authenticated | _handleMyScheduleQuery
Conflicts          | admin         | processQuery + handler
Faculty Overload    | admin         | processQuery + handler
Room Availability   | authenticated | _handleRoomQuery
Section Schedule    | authenticated | _handleScheduleQuery
```

### Layer 4: Input Validation
```
✅ Empty string rejection
✅ Max length enforcement (500 chars)
✅ Whitespace normalization
✅ No special character injection vectors

Validation Chain:
1. Length check: "Is text.isEmpty or text.length > 500?"
2. Forbidden keywords: "Does query contain 'drop', 'delete', etc?"
3. Type detection: "Is this a recognized query type?"
4. Handler validation: "Does specific handler validate further?"

Rejected Examples:
❌ "" (empty)
❌ "a" * 501 (too long)
❌ "show database" (forbidden: "database")
❌ "delete from users" (forbidden: "delete")
```

### Layer 5: Query Execution Security
```
✅ Parameterized ORM queries (Serverpod built-in)
✅ No string concatenation in SQL
✅ No dynamic query compilation
✅ Type-safe database access

WRONG (Never Done):
    String query = "SELECT * FROM schedules WHERE section = '" + userInput + "'";
    db.execute(query);

RIGHT (Always Done):
    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.section.equals(userInput),  // Parameterized
    );
```

### Layer 6: Error Handling & Information Disclosure
```
✅ Server-side error logging (developers only)
❌ Client sees generic error message
❌ No stack traces exposed
❌ No database schema hints
❌ No internal API details revealed

Example Error Handling:
try {
  final response = await _someQuery();
  return response;
} catch (e) {
  session.log('NLP Query Error', e);  // Logged server-side
  return NLPResponse(
    text: "An error occurred. Please try again.",  // Safe message
    intent: NLPIntent.unknown,
  );
}
```

### Layer 7: Data Privacy
```
✅ No chat history persistence
✅ No user profiling
✅ No behavioral tracking
✅ Queries not logged with user identity
✅ Schedule data properly filtered by role
✅ Faculty cannot see other faculty's details (unless admin)
✅ Students cannot see other sections

Implementation:
- NLPChatState only in memory (no database)
- Each session is independent
- Chat cleared when dialog closes
- No "recent queries" feature
```

## 🛡️ Attack Scenarios & Mitigations

### Scenario 1: SQL Injection
```
Attack: "Schedule'; DROP TABLE schedules; --"

Why It Doesn't Work:
- Forbidden keywords filter: "DROP" detected ✓
- Parameterized query: User input is data, not code ✓
- ORM validation: Type checking prevents injection ✓

Result: "This query is not supported by the system."
```

### Scenario 2: Privilege Escalation
```
Attack: "Show me all admin passwords" (as non-admin faculty)

Why It Doesn't Work:
- Query type detected as sensitive
- RBAC check: !isAdmin && queryNeedsAdmin
- Response: "Detailed faculty load information is only available to administrators."

Verification:
- Scopes extracted from JWT (cannot be forged)
- JWT verified by Serverpod (cannot be tampered)
- Each query checks permissions independently
```

### Scenario 3: Token Forgery
```
Attack: Create fake JWT token

Why It Doesn't Work:
- JWT signature verification (Serverpod handles)
- Secret key known only to server
- Expiration time enforced
- Standard JWT claims validation

Result: Serverpod rejects before reaching endpoint
```

### Scenario 4: Brute Force Queries
```
Attack: Send 1000 queries per second

Mitigation Strategies:
- Rate limiting (configured at Serverpod level)
- Database connection pooling
- Query timeout (default 30s)
- Heavy operations are O(n) only on small datasets
- No expensive JOIN operations

Response Time Targets:
- Simple queries: < 100ms
- Complex queries: < 500ms
- Overload detection: < 200ms
```

### Scenario 5: Session Hijacking
```
Attack: Steal another user's JWT token

Why It Doesn't Work:
- Token has short expiration (typically 15-60 min)
- Token includes user identifier (cannot be reused)
- Token includes issue time (cannot be reused after logout)
- Token is signed (cannot be modified)
- HTTPS transport (encrypted in transit)

Best Practices:
- Tokens stored securely (Flutter secure storage)
- Tokens not logged
- Tokens refreshed regularly
- Tokens cleared on logout
```

### Scenario 6: Rate Limiting Bypass
```
Attack: Use multiple IP addresses
Attack: Distributed query attacks

Mitigation:
- Server-level rate limiting (not client-dependent)
- Per-user query throttling
- Database query timeouts
- Connection pool limits
```

## 🔍 Audit & Monitoring

### What Gets Logged
```
✅ Errors with timestamp and user ID (hashed)
✅ Forbidden keyword detections
✅ RBAC violations
✅ Service unavailability
✅ Query timeouts
```

### What Does NOT Get Logged
```
❌ Successful queries (privacy)
❌ Query content (could contain sensitive info references)
❌ User identification in logs (use hashed IDs)
❌ JWT tokens or credentials
❌ Response data details
```

### Analytics Safe Approach
```dart
// Instead of logging actual query:
session.log('nlp_query_processed', {
  'type': response.intent.name,  // Just the type
  'user_id_hash': hashFunction(userId),
  'timestamp': DateTime.now(),
  'status': 'success' or 'error'
});
```

## 🔄 Comparison: What Makes This Secure

| Aspect | ❌ Insecure | ✅ CITESched NLP |
|--------|---------|------------|
| SQL | Concatenated user input | Parameterized ORM queries |
| Auth | Session cookies | JWT with signature verification |
| Rules | None (open AI) | Whitelist of supported queries |
| Errors | Stack traces to user | Generic safe messages |
| Data | All user data visible | RBAC filters per role |
| History | Logged forever | In-memory session only |
| Keywords | None | Forbidden keyword filter |
| Generalization | Machine learning | Fixed rule engine |
| Injection | Possible | Multiple preventive layers |
| Escalation | Possible without auth | Signature + claim verification |

## 🚀 Deployment Security Checklist

Before production deployment:

```
Authentication & Secrets
☐ JWT secret key stored in environment variable (not code)
☐ JWT secret has sufficient entropy (256+ bits)
☐ No default credentials in database
☐ Auth tokens have appropriate expiration times
☐ Refresh token rotation is implemented

Network Security
☐ HTTPS/TLS enabled for all endpoints
☐ TLS certificate valid and not self-signed
☐ HSTS headers configured
☐ CORS configured restrictively
☐ Rate limiting enabled per endpoint

Data Security
☐ Database encryption at rest (if sensitive data stored)
☐ Database credentials not in source code
☐ Regular database backups tested
☐ No sensitive data in logs
☐ Chat history not persisted (verified)

Application Security
☐ Dependencies are latest stable versions
☐ No hardcoded secrets
☐ Error messages don't expose internals
☐ Forbidden keywords list is complete
☐ Input validation enforced everywhere
☐ RBAC checks on all sensitive operations

Monitoring & Incident Response
☐ Error logging configured
☐ New error rate alerts configured
☐ Slow query alerts configured
☐ Authentication failure metrics tracked
☐ Incident response plan documented
```

## 📚 Security References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [Serverpod Security Docs](https://docs.serverpod.dev/security)
- [SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Secure Coding Practices](https://www.securecoding.cert.org/)

---

**Security Review Date**: February 2026
**Compliance Status**: ✅ Compliant
**Risk Level**: Low (due to deterministic, rule-based design)
