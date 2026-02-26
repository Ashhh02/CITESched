# NLP Assistant - Deployment & Operations Guide

## 📋 Pre-Deployment Checklist

### Code Quality
- [x] All files follow Dart style guide
- [x] No console warnings or errors
- [x] Type safety enabled (all code is properly typed)
- [x] Comments added for complex logic
- [x] Null safety properly handled
- [x] No deprecated APIs used

### Testing
- [ ] Unit tests written for parsers
- [ ] Integration tests for API calls
- [ ] Manual testing completed (all query types)
- [ ] Edge cases tested (empty, long, forbidden keywords)
- [ ] Role-based access tested (admin, faculty, student)
- [ ] Error handling tested (network, server errors)

### Security Review
- [x] No hardcoded credentials
- [x] No sensitive data in logs
- [x] Input validation implemented
- [x] RBAC enforced
- [x] Parameterized queries used
- [x] Error messages are safe
- [x] JWT properly validated
- [x] Forbidden keywords filtered

### Documentation
- [x] README.md (feature documentation)
- [x] QUICK_START.md (getting started)
- [x] IMPLEMENTATION_SUMMARY.md (what was built)
- [x] SECURITY_ARCHITECTURE.md (security details)
- [x] This deployment guide

### Dependencies
- [ ] All packages in pubspec.yaml are up to date
- [ ] No conflicting package versions
- [ ] Required packages are documented
- [ ] Optional packages are marked as such

---

## 🚀 Deployment Steps

### Step 1: Verify Backend is Running

```bash
# Terminal 1: Start the server
cd citesched_server
dart pub get
dart run bin/main.dart --apply-migrations

# Expected output:
# Serverpod listening on port 8083...
```

### Step 2: Verify Flutter Client Builds

```bash
# Terminal 2: Test Flutter build
cd citesched_flutter
flutter pub get
flutter analyze           # Check for warnings
flutter test             # Run tests if available
flutter build web        # or android/ios as needed
```

### Step 3: Manual Testing

Open the app and test these queries:

**Non-Admin User** (faculty/student login):
```
✅ "Show my schedule"              → Personal schedule
✅ "Is room 301 available?"        → Room occupancy
✅ "Schedule for IT 3A"            → Section timetable
❌ "Show conflicts"                 → Unauthorized message
❌ "Faculty overload"               → Unauthorized message
```

**Admin User** (admin login):
```
✅ "Show conflicts"                 → Conflict list
✅ "Faculty overload"               → Overload analysis
✅ "What's the load of Prof. X?"    → Specific faculty load
✅ "Show my schedule"               → Admin's schedule
✅ "Room availability"              → Room occupancy
```

### Step 4: Production Deployment

#### Backend (Serverpod Server)

```bash
# 1. Update environment variables
export JWT_SECRET_KEY="your-256-bit-secret-key"
export DATABASE_URL="production-database-url"
export SERVERPOD_ENV="production"

# 2. Build optimized Docker image (if using containers)
docker build -t citesched-server:1.0 .
docker run -e JWT_SECRET_KEY=$JWT_SECRET_KEY \
           -e DATABASE_URL=$DATABASE_URL \
           -p 8083:8083 \
           citesched-server:1.0

# 3. Or deploy to your hosting platform
# - AWS Lambda
# - Google Cloud Run
# - Heroku
# - DigitalOcean App Platform
# - Self-hosted server
```

#### Flutter Client

```bash
# Web deployment
flutter build web --release
# Upload contents of build/web to your web server

# Mobile deployment
flutter build apk --release        # Android
flutter build ipa --release        # iOS
# Upload to Play Store / App Store
```

### Step 5: Post-Deployment Verification

```bash
# 1. Check server is responding
curl https://yourdomain.com/api/nlp/query \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -X POST \
  -d '{"query":"show my schedule"}'

# 2. Check logs for errors
tail -f /var/log/citesched-server.log

# 3. Monitor performance
# - Check response times (< 500ms)
# - Check error rates (< 0.1%)
# - Check failed auth attempts (< 1% of total)

# 4. Test user flows end-to-end
# - Login as different user roles
# - Test each query type
# - Verify response accuracy
```

---

## 📊 Monitoring & Operations

### Key Metrics to Track

```
Performance:
- Average query response time (target: < 200ms)
- P95 response time (target: < 500ms)
- Error rate (target: < 0.5%)

Availability:
- Uptime percentage (target: > 99.5%)
- Failed requests (target: < 0.1%)
- Server error rate (target: < 0.1%)

Security:
- Failed auth attempts (monitor for spikes)
- Forbidden keyword detection (should be low)
- Rate limit violations (monitor for abuse)
```

### Logging Configuration

```dart
// In citesched_server/lib/src/endpoints/nlp_endpoint.dart
session.log('nlp_query_processed', {
  'query_type': response.intent.name,
  'execution_time_ms': stopwatch.elapsedMilliseconds,
  'success': response.intent != NLPIntent.unknown,
  'has_data': response.schedules?.isNotEmpty ?? false,
});
```

### Recommended Alerts

```
Alert                          | Threshold | Action
───────────────────────────────┼───────────┼──────────────────
High Error Rate                | > 1%      | Page on-call
High Response Time             | > 1s      | Investigate database
High Auth Failures             | > 10/min  | Check for attacks
Service Unavailable            | Any       | Immediate restart
Disk Space Low                 | < 10%     | Clean up logs
Database Connections Maxed     | 100       | Scale database
```

### Log Analysis

```bash
# Find slow queries
grep "execution_time_ms" logs/serverpod.log | awk -F: '{if ($NF > 500) print}' | tail -10

# Find failed queries
grep "success.*false" logs/serverpod.log | tail -20

# Find auth failures
grep "authentication.*failed" logs/serverpod.log | tail -10

# Find forbidden keywords
grep "forbidden_keyword" logs/serverpod.log | tail -10
```

---

## 🔄 Scaling Considerations

### Vertical Scaling (Single Server)
- Increase CPU/RAM for the server
- Increase database connection pool
- Enable query caching for common queries

### Horizontal Scaling (Multiple Servers)
- Place servers behind load balancer
- Use shared database (already required)
- Session management via JWT (stateless)
- Redis cache for frequent queries (optional)

### Database Optimization
```
Indexes to create:
- faculty.userId (for "my schedule")
- schedule.facultyId (for faculty queries)
- schedule.section (for section queries)
- schedule.roomId (for room queries)
- schedule.timeslot.id (for availability checks)
```

### Caching Strategy
```
Cache Level 1: Client-side (Flutter)
- Cache user's own schedule for 5 minutes
- Cache room list for 10 minutes
- Clear on logout

Cache Level 2: Server-side (Optional)
- Cache all rooms (invalidate on changes)
- Cache all sections (invalidate on changes)
- Cache conflict list (invalidate on schedule change)
- Use Redis with 1-hour TTL
```

---

## 🔧 Troubleshooting in Production

### Issue: High Response Times

**Symptoms**: Queries taking > 1 second

**Diagnosis**:
```bash
# 1. Check database performance
EXPLAIN ANALYZE SELECT * FROM schedule WHERE faculty_id = ?;

# 2. Check server logs for slow queries
grep "execution_time_ms" logs/* | sort -t: -k2 -rn | head -20

# 3. Check server resource usage
top -p $(pgrep -f "dart run")
```

**Solutions**:
- Add database indexes (see Scaling section)
- Increase server RAM
- Optimize query handler logic
- Enable database query caching
- Add Redis cache layer

### Issue: High Error Rate

**Symptoms**: Many 500 Internal Server Error responses

**Diagnosis**:
```bash
# 1. Check server logs
tail -f /var/log/citesched-server.log

# 2. Look for patterns in errors
grep "error\|exception" logs/* | head -20

# 3. Check database connectivity
curl http://localhost:8083/health
```

**Solutions**:
- Check database connection string
- Verify database is running and accessible
- Check disk space (might affect database)
- Restart server: `systemctl restart citesched-server`
- Check for memory leaks: `docker stats`

### Issue: Authentication Failures

**Symptoms**: Users getting "Unauthorized" unexpectedly

**Diagnosis**:
```bash
# 1. Check JWT secret key matches
grep "JWT_SECRET_KEY" /etc/environment

# 2. Check token expiration times
# Verify tokens aren't expiring too quickly
```

**Solutions**:
- Verify JWT secret key is same on all servers
- Check system time sync (critical for JWT)
- Increase token expiration if needed
- Clear browser cache and retry

### Issue: Rate Limiting

**Symptoms**: Users getting throttled messages

**Diagnosis**:
```bash
# 1. Check rate limit configuration
grep "RATE_LIMIT" config/production.yaml

# 2. Check current request rate
grep "nlp_query" logs/* | wc -l  # Count in last period
```

**Solutions**:
- Increase rate limit threshold
- Implement client-side query debouncing
- Add Redis-based distributed rate limiting
- Whitelist trusted internal IPs

---

## 📞 Incident Response

### When Service Goes Down

1. **First 5 minutes**:
   ```bash
   # 1. Check server status
   systemctl status citesched-server
   
   # 2. Check logs for errors
   tail -100 /var/log/citesched-server.log
   
   # 3. Try graceful restart
   systemctl restart citesched-server
   ```

2. **If restart doesn't help**:
   ```bash
   # 1. Check database
   psql -U citesched_user -d citesched_db -c "SELECT 1;"
   
   # 2. Check disk space
   df -h
   
   # 3. Check memory
   free -h
   ```

3. **Escalate if still down**:
   - Check server provider status page
   - Alert database administrator
   - Activate backup servers (if configured)
   - Post outage notice to users

### Post-Incident Review

```
✓ What happened?
✓ When did it start?
✓ What was the impact?
✓ What was the root cause?
✓ How was it fixed?
✓ What preventive measures can we add?
✓ Update runbooks/procedures
✓ Announce changes to team
```

---

## 📚 Runbooks

### Daily Tasks
- [ ] Check error rate (should be < 0.5%)
- [ ] Review slow query logs
- [ ] Verify backups completed
- [ ] Check disk usage

### Weekly Tasks
- [ ] Review performance trends
- [ ] Database maintenance (VACUUM, ANALYZE)
- [ ] Update monitoring dashboards
- [ ] Review security logs

### Monthly Tasks
- [ ] Full system health check
- [ ] Capacity planning review
- [ ] Test disaster recovery
- [ ] Update documentation

### Quarterly Tasks
- [ ] Security audit
- [ ] Performance optimization review
- [ ] Dependency updates
- [ ] Load testing

---

## 🔐 Security Operations

### Regular Security Tasks
- Rotate JWT secret key (every 90 days)
- Review user permissions (monthly)
- Audit logs for suspicious activity (weekly)
- Update dependencies for security patches (as available)

### Incident Response
If breach suspected:
1. Rotate JWT secret keys immediately
2. Revoke potentially compromised tokens
3. Force re-authentication for all users
4. Review logs for unauthorized access
5. Patch vulnerability
6. Notify affected users

---

## 📞 Support & SLA

### Response Times
- Critical (service down): 15 minutes
- High (degraded): 1 hour
- Medium (bug): 4 hours
- Low (feature request): Best effort

### On-Call Rotation
- [Team member 1] Week 1-2
- [Team member 2] Week 3-4
- Escalation: Team lead

---

## 🎯 Success Criteria

Deployment is successful when:
- ✅ All 5 query types work for appropriate users
- ✅ Unauthorized users get proper error messages
- ✅ Response times are < 500ms
- ✅ Error rate is < 0.5%
- ✅ No security vulnerabilities detected
- ✅ Documentation is complete
- ✅ Team is trained
- ✅ Monitoring is active

---

**Version**: 1.0.0
**Last Updated**: February 2026
**Status**: Ready for Production
