import 'package:citesched_client/citesched_client.dart';
import 'dart:async';

import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';

// REAR-TIME REPORT PROVIDERS
final facultyLoadReportProvider = FutureProvider<List<FacultyLoadReport>>((
  ref,
) async {
  ref.watch(schedulesProvider);
  return await client.admin.getFacultyLoadReport();
});

final roomUtilizationReportProvider =
    FutureProvider<List<RoomUtilizationReport>>((ref) async {
      ref.watch(schedulesProvider);
      return await client.admin.getRoomUtilizationReport();
    });

final conflictSummaryReportProvider = FutureProvider<List<ScheduleConflict>>((
  ref,
) async {
  ref.watch(schedulesProvider);
  return await client.admin.getAllConflicts();
});

final scheduleOverviewReportProvider = FutureProvider<ScheduleOverviewReport>((
  ref,
) async {
  ref.watch(schedulesProvider);
  return await client.admin.getScheduleOverviewReport();
});

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final maroonColor = const Color(0xFF720045);
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      ref.invalidate(schedulesProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analytical Reports',
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
                                    'Comprehensive system metrics and utilization analysis',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
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
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Analytical Reports',
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Comprehensive system metrics and utilization analysis',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AY 2025-2026',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),

            // Tab Selector
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                labelColor: maroonColor,
                unselectedLabelColor: textMuted,
                indicator: BoxDecoration(
                  color: maroonColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: maroonColor.withValues(alpha: 0.2),
                  ),
                ),
                indicatorColor: maroonColor,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                labelPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                ),
                tabs: const [
                  Tab(text: 'Faculty Load'),
                  Tab(text: 'Room Usage'),
                  Tab(text: 'Conflicts'),
                  Tab(text: 'Schedule Stats'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _FacultyLoadTab(),
                    _RoomUtilizationTab(),
                    _ConflictSummaryTab(),
                    _ScheduleOverviewTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacultyLoadTab extends ConsumerWidget {
  const _FacultyLoadTab();

  Widget _loadStatusBadge(String status) {
    final normalized = status.toLowerCase();
    Color color;
    switch (normalized) {
      case 'overload':
        color = Colors.red;
        break;
      case 'full':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(facultyLoadReportProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        const maroonColor = Color(0xFF720045);
        final textPrimary = isDark ? Colors.white : Colors.black87;
        final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
        final rowBgA = isDark ? const Color(0xFF0F172A) : Colors.white;
        final rowBgB = isDark
            ? const Color(0xFF111827)
            : const Color(0xFFF9FAFB);

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: maroonColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: maroonColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 420;
                    return Row(
                      children: [
                        Icon(
                          Icons.leaderboard_rounded,
                          color: maroonColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Faculty Teaching Load Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: maroonColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: maroonColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${data.length} Total',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              maroonColor,
                            ),
                            headingTextStyle: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                            dataTextStyle: GoogleFonts.poppins(
                              color: textPrimary,
                              fontSize: 12,
                            ),
                            dataRowMinHeight: 65,
                            dataRowMaxHeight: 85,
                            columnSpacing: 28,
                            horizontalMargin: 24,
                            decoration:
                                const BoxDecoration(color: Colors.transparent),
                            columns: const [
                              DataColumn(label: Text('FACULTY')),
                              DataColumn(label: Text('PROGRAM')),
                              DataColumn(label: Text('SUBJECTS')),
                              DataColumn(label: Text('UNITS')),
                              DataColumn(label: Text('HOURS')),
                              DataColumn(label: Text('STATUS')),
                            ],
                            rows: data.asMap().entries.map((entry) {
                              final index = entry.key;
                              final r = entry.value;
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  index.isEven ? rowBgA : rowBgB,
                                ),
                                cells: [
                                  DataCell(
                                    Text(
                                      r.facultyName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (r.program ?? 'N/A').toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      r.totalSubjects.toString(),
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      r.totalUnits.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      r.totalHours.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(_loadStatusBadge(r.loadStatus)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomUtilizationTab extends ConsumerWidget {
  const _RoomUtilizationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(roomUtilizationReportProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? Colors.white : Colors.black87;
        final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 650 ? 1 : (width < 1000 ? 2 : 3);
            final childAspectRatio = width < 650 ? 1.6 : 1.4;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final color = _utilizationColor(item.utilizationPercentage);

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: color.withOpacity(0.2), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.roomName,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.meeting_room_rounded, color: color),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Utilization',
                                style: GoogleFonts.poppins(color: textMuted),
                              ),
                              Text(
                                '${item.utilizationPercentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: item.utilizationPercentage / 100,
                              backgroundColor: color.withOpacity(0.1),
                              color: color,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.totalBookings} timeslots assigned',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _utilizationColor(double utilization) {
    if (utilization > 80) {
      return Colors.red;
    }
    if (utilization > 50) {
      return Colors.orange;
    }
    return Colors.green;
  }
}

class _ConflictSummaryTab extends ConsumerWidget {
  const _ConflictSummaryTab();

  static const _typeConfig = <String, _ReportConflictConfig>{
    'room_conflict': _ReportConflictConfig(
      label: 'ROOM CONFLICT',
      icon: Icons.meeting_room_rounded,
      color: Colors.red,
    ),
    'faculty_conflict': _ReportConflictConfig(
      label: 'FACULTY CONFLICT',
      icon: Icons.person_off_rounded,
      color: Colors.deepOrange,
    ),
    'section_conflict': _ReportConflictConfig(
      label: 'SECTION CONFLICT',
      icon: Icons.groups_rounded,
      color: Colors.purple,
    ),
    'program_mismatch': _ReportConflictConfig(
      label: 'PROGRAM MISMATCH',
      icon: Icons.compare_arrows_rounded,
      color: Colors.amber,
    ),
    'capacity_exceeded': _ReportConflictConfig(
      label: 'CAPACITY EXCEEDED',
      icon: Icons.group_add_rounded,
      color: Colors.orange,
    ),
    'max_load_exceeded': _ReportConflictConfig(
      label: 'MAX LOAD EXCEEDED',
      icon: Icons.warning_amber_rounded,
      color: Colors.brown,
    ),
    'room_inactive': _ReportConflictConfig(
      label: 'ROOM INACTIVE',
      icon: Icons.block_rounded,
      color: Colors.grey,
    ),
    'faculty_unavailable': _ReportConflictConfig(
      label: 'FACULTY UNAVAILABLE',
      icon: Icons.event_busy_rounded,
      color: Colors.indigo,
    ),
    'generation_failed': _ReportConflictConfig(
      label: 'GENERATION FAILED',
      icon: Icons.error_outline_rounded,
      color: Colors.red,
    ),
  };

  _ReportConflictConfig _cfg(String type) =>
      _typeConfig[type] ??
      const _ReportConflictConfig(
        label: 'UNKNOWN',
        icon: Icons.help_outline_rounded,
        color: Colors.grey,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(conflictSummaryReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (conflicts) {
        return SingleChildScrollView(
          child: Card(
            color: cardBg,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConflictHeader(conflicts, textPrimary),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  if (conflicts.isEmpty)
                    _buildEmptyState(textMuted)
                  else
                    _buildConflictList(conflicts, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConflictHeader(
    List<ScheduleConflict> conflicts,
    Color textPrimary,
  ) {
    final hasConflicts = conflicts.isNotEmpty;
    final statusColor = hasConflicts ? Colors.red : Colors.green;
    final summaryColor = hasConflicts ? Colors.red[700] : Colors.green;
    final statusIcon = hasConflicts
        ? Icons.warning_rounded
        : Icons.verified_rounded;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conflict Summary',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                _conflictSummaryText(conflicts.length),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: summaryColor,
                ),
              ),
            ],
          ),
        ),
        if (hasConflicts)
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _buildCountBadge(conflicts, 'CRITICAL', [
                    'room_conflict',
                    'faculty_conflict',
                    'section_conflict',
                  ], Colors.red),
                  _buildCountBadge(conflicts, 'WARNING', [
                    'max_load_exceeded',
                    'room_inactive',
                    'faculty_unavailable',
                    'program_mismatch',
                    'capacity_exceeded',
                  ], Colors.orange),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _conflictSummaryText(int conflictCount) {
    if (conflictCount == 0) {
      return 'No conflicts detected — system is clean';
    }
    final suffix = conflictCount == 1 ? '' : 's';
    return '$conflictCount conflict$suffix require attention';
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No scheduling conflicts found. The timetable is valid.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictList(
    List<ScheduleConflict> conflicts,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: conflicts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
          final conflict = conflicts[index];
          final cfg = _cfg(conflict.type);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? cfg.color.withOpacity(0.08)
                  : cfg.color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cfg.color.withOpacity(0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cfg.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cfg.icon,
                    color: cfg.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cfg.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cfg.label,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: cfg.color,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        conflict.message,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (conflict.details != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          conflict.details!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: cfg.color.withOpacity(0.7),
                ),
              ],
            ),
          );
        },
      );
  }

  Widget _buildCountBadge(
    List<ScheduleConflict> conflicts,
    String label,
    List<String> types,
    Color color,
  ) {
    final count = conflicts.where((c) => types.contains(c.type)).length;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Config for conflict type icons and colours inside the Reports screen.
class _ReportConflictConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _ReportConflictConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _ScheduleOverviewTab extends ConsumerWidget {
  const _ScheduleOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(scheduleOverviewReportProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final isMobile = ResponsiveHelper.isMobile(context);
        return SingleChildScrollView(
          child: Column(
            children: [
            if (isMobile) ...[
              _buildStatTileCard(
                context,
                'Total Schedules',
                data.totalSchedules.toString(),
                Icons.event_note_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatTileCard(
                context,
                'Active Programs',
                data.schedulesByProgram.length.toString(),
                Icons.account_tree_rounded,
                Colors.purple,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatTileCard(
                      context,
                      'Total Schedules',
                      data.totalSchedules.toString(),
                      Icons.event_note_rounded,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildStatTileCard(
                      context,
                      'Active Programs',
                      data.schedulesByProgram.length.toString(),
                      Icons.account_tree_rounded,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (isMobile) ...[
              _buildProgramBreakdown(context, data.schedulesByProgram),
              const SizedBox(height: 16),
              _buildTermBreakdown(context, data.schedulesByTerm),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildProgramBreakdown(
                      context,
                      data.schedulesByProgram,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildTermBreakdown(context, data.schedulesByTerm),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _buildSectionSubjectsBreakdown(context, ref),
          ],
          ),
        );
      },
    );
  }

  Widget _buildSectionSubjectsBreakdown(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final facultyAsync = ref.watch(facultyListProvider);
    final roomsAsync = ref.watch(roomListProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);

    final schedules = schedulesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final subjects = subjectsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final faculty = facultyAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final rooms = roomsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final timeslots = timeslotsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    if (schedules == null ||
        subjects == null ||
        faculty == null ||
        rooms == null ||
        timeslots == null) {
      final error =
          schedulesAsync.error ??
          subjectsAsync.error ??
          facultyAsync.error ??
          roomsAsync.error ??
          timeslotsAsync.error;
      if (error != null) {
        return Center(child: Text('Error loading schedule details: $error'));
      }
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    const maroonColor = Color(0xFF720045);
    final rowBgA = isDark ? const Color(0xFF0F172A) : Colors.white;
    final rowBgB = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);

    final subjectMap = {for (final subject in subjects) subject.id!: subject};
    final facultyMap = {for (final entry in faculty) entry.id!: entry};
    final roomMap = {for (final room in rooms) room.id!: room};
    final timeslotMap = {for (final slot in timeslots) slot.id!: slot};

    final Map<String, List<Schedule>> schedulesBySection = {};
    for (final schedule in schedules) {
      schedulesBySection.putIfAbsent(schedule.section, () => []).add(schedule);
    }

    final sectionNames = schedulesBySection.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: maroonColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: maroonColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, color: maroonColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Subjects per Section',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: maroonColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: maroonColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sectionNames.length} Sections',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sectionNames.length,
            itemBuilder: (context, index) {
              final section = sectionNames[index];
              final sectionSchedules = schedulesBySection[section]!
                ..sort((a, b) {
                  final subjectA = subjectMap[a.subjectId]?.code ?? '';
                  final subjectB = subjectMap[b.subjectId]?.code ?? '';
                  return subjectA.compareTo(subjectB);
                });

              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  'Section: $section',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: maroonColor,
                  ),
                ),
                subtitle: Text(
                  '${sectionSchedules.length} Subject${sectionSchedules.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(fontSize: 12, color: textMuted),
                ),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(maroonColor),
                      headingTextStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      dataTextStyle: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 12,
                      ),
                      dataRowMinHeight: 65,
                      dataRowMaxHeight: 88,
                      columnSpacing: 28,
                      horizontalMargin: 24,
                      columns: const [
                        DataColumn(label: Text('CODE')),
                        DataColumn(label: Text('DESCRIPTION')),
                        DataColumn(label: Text('FACULTY')),
                        DataColumn(label: Text('ROOM')),
                        DataColumn(label: Text('SCHEDULE')),
                      ],
                      rows: sectionSchedules.asMap().entries.map((entry) {
                        final rowIndex = entry.key;
                        final schedule = entry.value;
                        final subject = subjectMap[schedule.subjectId];
                        final assignedFaculty = facultyMap[schedule.facultyId];
                        final room = schedule.roomId != null
                            ? roomMap[schedule.roomId!]
                            : null;
                        final timeslot = schedule.timeslotId != null
                            ? timeslotMap[schedule.timeslotId!]
                            : null;

                        return DataRow(
                          color: WidgetStateProperty.all(
                            rowIndex.isEven ? rowBgA : rowBgB,
                          ),
                          cells: [
                            DataCell(Text(subject?.code ?? 'N/A')),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(subject?.name ?? 'Unknown'),
                              ),
                            ),
                            DataCell(Text(assignedFaculty?.name ?? 'TBA')),
                            DataCell(Text(room?.name ?? 'TBA')),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  _formatScheduleDisplay(
                                    timeslot,
                                    schedule.loadTypes ?? subject?.types,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatScheduleDisplay(
    Timeslot? timeslot,
    List<SubjectType>? loadTypes,
  ) {
    if (timeslot == null) return 'TBA';
    final loadLabel = _formatLoadType(loadTypes);
    return '${_formatDisplayTime(timeslot.startTime)} - ${_formatDisplayTime(timeslot.endTime)} $loadLabel';
  }

  String _formatLoadType(List<SubjectType>? loadTypes) {
    final types = loadTypes ?? const [];
    if (types.contains(SubjectType.laboratory) &&
        !types.contains(SubjectType.lecture)) {
      return 'LABORATORY';
    }
    if (types.contains(SubjectType.lecture) &&
        !types.contains(SubjectType.laboratory)) {
      return 'LECTURE';
    }
    if (types.contains(SubjectType.blended) ||
        (types.contains(SubjectType.lecture) &&
            types.contains(SubjectType.laboratory))) {
      return 'BLENDED';
    }
    return 'CLASS';
  }

  String _formatDisplayTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final minuteLabel = minute == 0
        ? ''
        : ':${minute.toString().padLeft(2, '0')}';
    return '$normalizedHour$minuteLabel$period';
  }

  Widget _buildStatTileCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: isMobile ? 26 : 32),
          ),
          SizedBox(width: isMobile ? 16 : 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramBreakdown(BuildContext context, Map<String, int> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Distribution',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ...data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${e.value} Classes',
                        style: GoogleFonts.poppins(color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.7, // Placeholder ratio
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      color: const Color(0xFF720045),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermBreakdown(BuildContext context, Map<String, int> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrollment by Term',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ...data.entries.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF720045),
                child: Icon(Icons.flash_on, color: Colors.white, size: 16),
              ),
              title: Text(
                'Term ${e.key}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              trailing: Text(
                '${e.value} Subjects',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF720045),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
