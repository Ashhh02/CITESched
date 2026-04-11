import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';

class ConflictScreen extends StatefulWidget {
  final String? filterType;

  const ConflictScreen({super.key, this.filterType});

  @override
  State<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends State<ConflictScreen> {
  static const String _sourceFacultyLoadingTimetable =
      'FACULTY LOADING · TIMETABLE';
  List<ScheduleConflict> _conflicts = [];
  bool _isLoading = true;
  final Set<String> _resolvingConflictKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchConflicts();
  }

  Future<void> _fetchConflicts() async {
    setState(() => _isLoading = true);
    try {
      final conflicts = await client.admin.getAllConflicts();
      if (!context.mounted) return;
      setState(() {
        _conflicts = conflicts;
        _isLoading = false;
      });
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      AppErrorDialog.show(context, e);
    }
  }

  // ─── Conflict Type Metadata ──────────────────────────────────────

  static const _typeConfig = <String, _ConflictTypeConfig>{
    'room_conflict': _ConflictTypeConfig(
      label: 'ROOM CONFLICT',
      source: _sourceFacultyLoadingTimetable,
      icon: Icons.meeting_room_rounded,
      color: Colors.red,
      severity: 'CRITICAL',
    ),
    'faculty_conflict': _ConflictTypeConfig(
      label: 'FACULTY TIME CONFLICT',
      source: _sourceFacultyLoadingTimetable,
      icon: Icons.person_off_rounded,
      color: Colors.deepOrange,
      severity: 'CRITICAL',
    ),
    'section_conflict': _ConflictTypeConfig(
      label: 'SECTION CONFLICT',
      source: _sourceFacultyLoadingTimetable,
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
    for (var c in _filteredConflicts()) {
      counts[c.type] = (counts[c.type] ?? 0) + 1;
    }
    return counts;
  }

  List<ScheduleConflict> _filteredConflicts() {
    if (widget.filterType == null) return _conflicts;
    return _conflicts
        .where((c) => c.type == widget.filterType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maroonColor = const Color(0xFF720045);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Standardized Maroon Gradient Banner)
            AdminHeaderContainer(
              primaryColor: maroonColor,
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: maroonColor.withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
              child: isMobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System Conflicts',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isLoading
                                      ? 'Scanning all modules for conflicts...'
                                      : _conflicts.isEmpty
                                      ? 'No scheduling conflicts detected'
                                      : '${_conflicts.length} conflict${_conflicts.length == 1 ? '' : 's'} detected across modules',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _fetchConflicts,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF720045),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(
                            _isLoading ? 'Scanning...' : 'Refresh',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.4,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: maroonColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Conflicts',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLoading
                                    ? 'Scanning all modules for conflicts...'
                                    : _conflicts.isEmpty
                                    ? 'No scheduling conflicts detected'
                                    : '${_conflicts.length} conflict${_conflicts.length == 1 ? '' : 's'} detected across modules',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchConflicts,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF720045),
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 22),
                        label: Text(
                          _isLoading ? 'Scanning...' : 'Refresh',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: maroonColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
              ),

            const SizedBox(height: 32),

            // Summary Stat Chips
            if (!_isLoading && _filteredConflicts().isNotEmpty) ...[
              _buildSummaryChips(maroonColor, cardBg, isDark),
              const SizedBox(height: 24),
            ],

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredConflicts().isEmpty
                  ? _buildEmptyState(textMuted)
                  : _buildConflictList(
                      isDark,
                      cardBg,
                      maroonColor,
                      textPrimary,
                      textMuted,
                    ),
            ),
          ],
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
            color: config.color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.color.withValues(alpha: 0.3)),
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
                  color: config.color.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              size: 64,
              color: Colors.green.withValues(alpha: 0.7),
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
            style: GoogleFonts.poppins(fontSize: 15, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictList(
    bool isDark,
    Color cardBg,
    Color maroonColor,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: maroonColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: maroonColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: maroonColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conflict Records',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: maroonColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: maroonColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_filteredConflicts().length} items',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredConflicts().length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conflict = _filteredConflicts()[index];
                final config = _getConfig(conflict.type);
                final conflictKey = _conflictKey(conflict, index);
                final isResolving = _resolvingConflictKeys.contains(conflictKey);
                final severityColor =
                    config.severity == 'CRITICAL' ? Colors.red : Colors.orange;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: config.color.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: config.color.withValues(alpha: 0.05),
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
                          color: config.color.withValues(alpha: 0.1),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: config.color.withValues(alpha: 0.1),
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
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    config.source,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severityColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 11,
                                        color: severityColor,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        config.severity,
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: severityColor,
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
                                color: textPrimary,
                              ),
                            ),
                            // Details
                            if (conflict.details != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                conflict.details!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: isResolving
                                    ? null
                                    : () => _resolveConflict(
                                          conflict,
                                          conflictKey: conflictKey,
                                        ),
                                icon: isResolving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.auto_fix_high,
                                        size: 16,
                                      ),
                                label: Text(
                                  isResolving ? 'Checking...' : 'Suggest Fix',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: config.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _conflictKey(ScheduleConflict conflict, int index) {
    return [
      '$index',
      conflict.type,
      '${conflict.scheduleId ?? -1}',
      '${conflict.conflictingScheduleId ?? -1}',
      '${conflict.facultyId ?? -1}',
      '${conflict.roomId ?? -1}',
      '${conflict.subjectId ?? -1}',
    ].join('|');
  }

  Future<void> _resolveConflict(
    ScheduleConflict conflict, {
    required String conflictKey,
  }) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (conflict.type == 'max_load_exceeded' && conflict.facultyId != null) {
      final shouldContinue = await _showMaxLoadConfirmationDialog();
      if (!context.mounted || shouldContinue != true) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => AdminLayout(
            initialIndex: 1,
            initialFacultyIdToEdit: conflict.facultyId,
          ),
        ),
      );
      return;
    }

    setState(() => _resolvingConflictKeys.add(conflictKey));
    try {
      final suggestion = await _buildResolutionSuggestion(conflict);
      if (!context.mounted) return;

      if (suggestion == null) {
        await _showManualResolutionDialog(conflict);
        return;
      }

      final shouldApply = await _showSuggestionDialog(suggestion);
      if (!context.mounted || shouldApply != true) return;

      await client.admin.updateSchedule(suggestion.updatedSchedule);
      await _fetchConflicts();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(suggestion.successMessage)),
      );
    } catch (e) {
      if (!context.mounted) return;
      AppErrorDialog.show(context, e);
    } finally {
      if (context.mounted) {
        setState(() => _resolvingConflictKeys.remove(conflictKey));
      }
    }
  }

  Future<_ResolutionSuggestion?> _buildResolutionSuggestion(
    ScheduleConflict conflict,
  ) async {
    final scheduleId = conflict.scheduleId;
    if (scheduleId == null) return null;

    switch (conflict.type) {
      case 'room_conflict':
      case 'room_inactive':
      case 'capacity_exceeded':
      case 'program_mismatch':
      case 'room_type_mismatch':
        return await _suggestRoomOrTimeslotResolution(conflict);
      case 'faculty_conflict':
      case 'section_conflict':
      case 'faculty_unavailable':
      case 'lab_start_time':
      case 'insufficient_block':
        return await _suggestTimeslotResolution(conflict);
      default:
        return null;
    }
  }

  Future<_ResolutionSuggestion?> _suggestRoomOrTimeslotResolution(
    ScheduleConflict conflict,
  ) async {
    final schedule = await _loadSchedule(conflict.scheduleId);
    if (schedule == null || schedule.timeslotId == null) return null;

    final rooms = await client.admin.getAllRooms(isActive: true);
    final timeslots = await client.admin.getAllTimeslots();

    final currentTimeslot = _findTimeslot(timeslots, schedule.timeslotId);
    if (currentTimeslot == null) return null;
    final currentRoom = rooms.where((r) => r.id == schedule.roomId).firstOrNull;

    final preferredRooms = rooms.where((r) => r.id != schedule.roomId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final room in preferredRooms) {
      final candidate = schedule.copyWith(
        roomId: room.id,
        room: room,
        updatedAt: DateTime.now(),
      );
      if (await _isValidCandidate(candidate)) {
        return _ResolutionSuggestion(
          title: 'Suggested Room Change',
          summary:
              'Move this class to ${room.name} while keeping the same day and time.',
          currentSlotLabel: _buildSlotLabel(
            timeslot: currentTimeslot,
            room: currentRoom,
          ),
          proposedSlotLabel: _buildSlotLabel(timeslot: currentTimeslot, room: room),
          updatedSchedule: candidate,
          successMessage: 'Conflict resolved by moving the class to ${room.name}.',
        );
      }
    }

    return await _findTimeslotBasedSuggestion(
      conflict: conflict,
      schedule: schedule,
      timeslots: timeslots,
      rooms: rooms,
      title: 'Suggested Reschedule',
    );
  }

  Future<_ResolutionSuggestion?> _suggestTimeslotResolution(
    ScheduleConflict conflict,
  ) async {
    final schedule = await _loadSchedule(conflict.scheduleId);
    if (schedule == null || schedule.timeslotId == null) return null;

    final timeslots = await client.admin.getAllTimeslots();
    final rooms = await client.admin.getAllRooms(isActive: true);

    return await _findTimeslotBasedSuggestion(
      conflict: conflict,
      schedule: schedule,
      timeslots: timeslots,
      rooms: rooms,
      title: 'Suggested Time Change',
    );
  }

  Future<_ResolutionSuggestion?> _findTimeslotBasedSuggestion({
    required ScheduleConflict conflict,
    required Schedule schedule,
    required List<Timeslot> timeslots,
    required List<Room> rooms,
    required String title,
  }) async {
    final currentTimeslot = _findTimeslot(timeslots, schedule.timeslotId);
    if (currentTimeslot == null) return null;

    final durationMinutes = _timeslotDurationMinutes(currentTimeslot);
    final candidateTimeslots = timeslots
        .where((t) => t.id != currentTimeslot.id)
        .where((t) => _timeslotDurationMinutes(t) == durationMinutes)
        .where((t) => !_overlapsLunch(t))
        .toList()
      ..sort((a, b) => _compareTimeslotCloseness(currentTimeslot, a, b));

    final roomOptions = <Room?>[
      rooms.where((r) => r.id == schedule.roomId).firstOrNull,
      ...rooms.where((r) => r.id != schedule.roomId),
    ].whereType<Room>().toList();

    for (final timeslot in candidateTimeslots) {
      for (final room in roomOptions) {
        final candidate = schedule.copyWith(
          timeslotId: timeslot.id,
          timeslot: timeslot,
          roomId: room.id,
          room: room,
          updatedAt: DateTime.now(),
        );
        if (await _isValidCandidate(candidate)) {
          final roomChanged = room.id != schedule.roomId;
          final summary = roomChanged
              ? 'Move this class to ${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)} in ${room.name}.'
              : 'Move this class to ${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)} and keep the same room.';
          return _ResolutionSuggestion(
            title: title,
            summary: summary,
            currentSlotLabel: _buildSlotLabel(
              timeslot: currentTimeslot,
              room: roomOptions
                  .where((r) => r.id == schedule.roomId)
                  .firstOrNull,
            ),
            proposedSlotLabel: _buildSlotLabel(timeslot: timeslot, room: room),
            updatedSchedule: candidate,
            successMessage:
                'Conflict resolved by rescheduling to ${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)}.',
          );
        }
      }
    }

    return null;
  }

  Future<Schedule?> _loadSchedule(int? scheduleId) async {
    if (scheduleId == null) return null;
    final schedules = await client.admin.getAllSchedules(isActive: true);
    try {
      return schedules.firstWhere((s) => s.id == scheduleId);
    } catch (_) {
      return null;
    }
  }

  Timeslot? _findTimeslot(List<Timeslot> timeslots, int? timeslotId) {
    if (timeslotId == null) return null;
    try {
      return timeslots.firstWhere((t) => t.id == timeslotId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isValidCandidate(Schedule candidate) async {
    final conflicts = await client.admin.validateSchedule(candidate);
    return conflicts.isEmpty;
  }

  int _timeslotDurationMinutes(Timeslot timeslot) {
    return _parseMinutes(timeslot.endTime) - _parseMinutes(timeslot.startTime);
  }

  int _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  bool _overlapsLunch(Timeslot timeslot) {
    final start = _parseMinutes(timeslot.startTime);
    final end = _parseMinutes(timeslot.endTime);
    return start < (13 * 60) && end > (12 * 60);
  }

  int _compareTimeslotCloseness(
    Timeslot current,
    Timeslot a,
    Timeslot b,
  ) {
    final aDay = (a.day.index - current.day.index).abs();
    final bDay = (b.day.index - current.day.index).abs();
    if (aDay != bDay) return aDay.compareTo(bDay);

    final aStart = (_parseMinutes(a.startTime) - _parseMinutes(current.startTime))
        .abs();
    final bStart = (_parseMinutes(b.startTime) - _parseMinutes(current.startTime))
        .abs();
    return aStart.compareTo(bStart);
  }

  String _formatTimeslot(Timeslot timeslot) {
    return '${timeslot.startTime} - ${timeslot.endTime}';
  }

  String _buildSlotLabel({
    required Timeslot timeslot,
    required Room? room,
  }) {
    final roomLabel = room?.name ?? 'No room';
    return '${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)} • $roomLabel';
  }

  Future<bool?> _showSuggestionDialog(
    _ResolutionSuggestion suggestion,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          suggestion.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.summary, style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Text(
              'Current',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.currentSlotLabel,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Proposed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.proposedSlotLabel,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Continue and apply this automatic fix?',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Continue', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showMaxLoadConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Continue to Edit Max Load?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This conflict needs a manual update to the faculty max load. Continue to open the specific faculty edit form and update the Max Loads field?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Continue', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualResolutionDialog(ScheduleConflict conflict) async {
    final index = _manualResolutionIndex(conflict.type);
    final rootNavigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Manual Resolution Needed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'No safe automatic suggestion is available for this specific conflict yet. Would you like to open the related module and resolve it manually?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          if (index != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                rootNavigator.push(
                  MaterialPageRoute(
                    builder: (_) => AdminLayout(initialIndex: index),
                  ),
                );
              },
              child: Text('Open Module', style: GoogleFonts.poppins()),
            ),
        ],
      ),
    );
  }

  int? _manualResolutionIndex(String type) {
    switch (type) {
      case 'room_conflict':
      case 'faculty_conflict':
      case 'section_conflict':
      case 'generation_failed':
      case 'lab_start_time':
      case 'insufficient_block':
        return 5;
      case 'capacity_exceeded':
      case 'room_inactive':
      case 'room_type_mismatch':
        return 4;
      case 'program_mismatch':
        return 3;
      case 'max_load_exceeded':
      case 'faculty_unavailable':
        return 2;
      default:
        return null;
    }
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

class _ResolutionSuggestion {
  final String title;
  final String summary;
  final String currentSlotLabel;
  final String proposedSlotLabel;
  final Schedule updatedSchedule;
  final String successMessage;

  const _ResolutionSuggestion({
    required this.title,
    required this.summary,
    required this.currentSlotLabel,
    required this.proposedSlotLabel,
    required this.updatedSchedule,
    required this.successMessage,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
