import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConflictScreen extends StatefulWidget {
  const ConflictScreen({super.key});

  @override
  State<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends State<ConflictScreen> {
  List<ScheduleConflict> _conflicts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConflicts();
  }

  Future<void> _fetchConflicts() async {
    setState(() => _isLoading = true);
    try {
      final conflicts = await client.admin.getAllConflicts();
      if (mounted) {
        setState(() {
          _conflicts = conflicts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading conflicts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Conflict Type Metadata ──────────────────────────────────────

  static const _typeConfig = <String, _ConflictTypeConfig>{
    'room_conflict': _ConflictTypeConfig(
      label: 'ROOM CONFLICT',
      source: 'FACULTY LOADING · TIMETABLE',
      icon: Icons.meeting_room_rounded,
      color: Colors.red,
      severity: 'CRITICAL',
    ),
    'faculty_conflict': _ConflictTypeConfig(
      label: 'FACULTY TIME CONFLICT',
      source: 'FACULTY LOADING · TIMETABLE',
      icon: Icons.person_off_rounded,
      color: Colors.deepOrange,
      severity: 'CRITICAL',
    ),
    'section_conflict': _ConflictTypeConfig(
      label: 'SECTION CONFLICT',
      source: 'FACULTY LOADING · TIMETABLE',
      icon: Icons.groups_rounded,
      color: Colors.purple,
      severity: 'CRITICAL',
    ),
    'program_mismatch': _ConflictTypeConfig(
      label: 'PROGRAM MISMATCH',
      source: 'SUBJECTS · ROOMS',
      icon: Icons.compare_arrows_rounded,
      color: Colors.amber,
      severity: 'WARNING',
    ),
    'capacity_exceeded': _ConflictTypeConfig(
      label: 'CAPACITY EXCEEDED',
      source: 'ROOMS · SUBJECTS',
      icon: Icons.group_add_rounded,
      color: Colors.orange,
      severity: 'WARNING',
    ),
    'max_load_exceeded': _ConflictTypeConfig(
      label: 'MAX LOAD EXCEEDED',
      source: 'FACULTY LOADING · FACULTY MANAGEMENT',
      icon: Icons.warning_amber_rounded,
      color: Colors.brown,
      severity: 'WARNING',
    ),
    'room_inactive': _ConflictTypeConfig(
      label: 'ROOM INACTIVE',
      source: 'ROOMS · TIMETABLE',
      icon: Icons.block_rounded,
      color: Colors.grey,
      severity: 'WARNING',
    ),
    'faculty_unavailable': _ConflictTypeConfig(
      label: 'FACULTY UNAVAILABLE',
      source: 'FACULTY MANAGEMENT · TIMETABLE',
      icon: Icons.event_busy_rounded,
      color: Colors.indigo,
      severity: 'WARNING',
    ),
    'generation_failed': _ConflictTypeConfig(
      label: 'GENERATION FAILED',
      source: 'SCHEDULE GENERATOR',
      icon: Icons.error_outline_rounded,
      color: Colors.red,
      severity: 'CRITICAL',
    ),
  };

  _ConflictTypeConfig _getConfig(String type) {
    return _typeConfig[type] ??
        const _ConflictTypeConfig(
          label: 'UNKNOWN',
          source: 'UNKNOWN MODULE',
          icon: Icons.help_outline_rounded,
          color: Colors.grey,
          severity: 'INFO',
        );
  }

  // ─── Conflict Summary Stats ──────────────────────────────────────

  Map<String, int> _getConflictCounts() {
    var counts = <String, int>{};
    for (var c in _conflicts) {
      counts[c.type] = (counts[c.type] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maroonColor = isDark
        ? const Color(0xFFa21caf)
        : const Color(0xFF720045);
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      color: bgBody,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [maroonColor, const Color(0xFFb5179e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: maroonColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Conflicts',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoading
                            ? 'Scanning all modules for conflicts...'
                            : _conflicts.isEmpty
                            ? 'No scheduling conflicts detected ✓'
                            : '${_conflicts.length} conflict${_conflicts.length == 1 ? '' : 's'} detected across modules',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Module source indicators
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _moduleSourceChip('Faculty Loading'),
                          _moduleSourceChip('Faculty Management'),
                          _moduleSourceChip('Subjects'),
                          _moduleSourceChip('Rooms'),
                          _moduleSourceChip('Timetable'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Refresh button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _fetchConflicts,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Summary Stat Chips ──
          if (!_isLoading && _conflicts.isNotEmpty) ...[
            _buildSummaryChips(maroonColor, cardBg, isDark),
            const SizedBox(height: 20),
          ],

          // ── Content ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conflicts.isEmpty
                ? _buildEmptyState()
                : _buildConflictList(isDark, cardBg),
          ),
        ],
      ),
    );
  }

  Widget _moduleSourceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildSummaryChips(Color maroonColor, Color cardBg, bool isDark) {
    final counts = _getConflictCounts();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: counts.entries.map((e) {
        final config = _getConfig(e.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: config.color.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icon, size: 16, color: config.color),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: config.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                config.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: config.color.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              size: 64,
              color: Colors.green.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Clear!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No conflicts across Faculty Loading, Rooms, Subjects, or Timetable.',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictList(bool isDark, Color cardBg) {
    return ListView.separated(
      itemCount: _conflicts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final conflict = _conflicts[index];
        final config = _getConfig(conflict.type);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: config.color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: config.color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.color, size: 22),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + source badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: config.color,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.source,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Severity badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (config.severity == 'CRITICAL'
                                        ? Colors.red
                                        : Colors.orange)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 11,
                                color: config.severity == 'CRITICAL'
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                config.severity,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: config.severity == 'CRITICAL'
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Message
                    Text(
                      conflict.message,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    // Details
                    if (conflict.details != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        conflict.details!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Internal config for conflict type display.
class _ConflictTypeConfig {
  final String label;
  final String source;
  final IconData icon;
  final Color color;
  final String severity;

  const _ConflictTypeConfig({
    required this.label,
    required this.source,
    required this.icon,
    required this.color,
    required this.severity,
  });
}
