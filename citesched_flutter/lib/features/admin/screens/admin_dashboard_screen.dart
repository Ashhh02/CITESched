import 'package:citesched_client/citesched_client.dart';
import 'dart:async';

import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/widgets/conflict_list_modal.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/features/admin/widgets/faculty_load_chart.dart';
import 'package:citesched_flutter/features/admin/widgets/report_modal.dart';
import 'package:citesched_flutter/features/admin/widgets/stat_card.dart';
import 'package:citesched_flutter/features/admin/widgets/user_list_modal.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return await client.admin.getDashboardStats();
});

final pendingFacultyRequestsProvider = FutureProvider<List<Faculty>>((ref) async {
  final inactiveFaculty = await client.admin.getAllFaculty(isActive: false);
  if (inactiveFaculty.isEmpty) return const <Faculty>[];

  final roleRows = await client.admin.getAllUserRoles();
  final pendingUserIds = roleRows
      .where((r) => r.role.trim().toLowerCase() == 'faculty_pending')
      .map((r) => int.tryParse(r.userId))
      .whereType<int>()
      .toSet();

  final pending = inactiveFaculty
      .where((f) => pendingUserIds.contains(f.userInfoId))
      .toList();

  pending.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return pending;
});

class _StatCardConfig {
  final String label;
  final String value;
  final IconData icon;
  final Color borderColor;
  final Color iconColor;
  final Color valueColor;
  final VoidCallback? onTap;

  const _StatCardConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.borderColor,
    required this.iconColor,
    required this.valueColor,
    this.onTap,
  });
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  Timer? _refreshTimer;

  void _showActionSnackBar({
    required String title,
    required String message,
    required Color accentColor,
    required IconData icon,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: accentColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showDebugSessionInfo() async {
    try {
      final debugInfo = await client.debug.getSessionInfo();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Debug Session Info'),
          content: SingleChildScrollView(
            child: Text(debugInfo.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Debug failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(pendingFacultyRequestsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _approvePendingFaculty(Faculty faculty) async {
    try {
      await client.admin.updateFaculty(
        faculty.copyWith(isActive: true, updatedAt: DateTime.now()),
      );
      await client.admin.assignRole(
        userId: faculty.userInfoId.toString(),
        role: 'faculty',
      );

      ref.invalidate(pendingFacultyRequestsProvider);
      ref.invalidate(dashboardStatsProvider);
      _showActionSnackBar(
        title: 'Request Approved',
        message:
            '${faculty.name} now has approved faculty access and can sign in to the faculty dashboard.',
        accentColor: const Color(0xFF15803D),
        icon: Icons.verified_rounded,
      );
    } catch (e) {
      _showErrorSnackBar('Approval failed: $e');
    }
  }

  Future<void> _declinePendingFaculty(Faculty faculty) async {
    try {
      await client.admin.assignRole(
        userId: faculty.userInfoId.toString(),
        role: 'faculty_declined',
      );
      await client.admin.updateFaculty(
        faculty.copyWith(isActive: false, updatedAt: DateTime.now()),
      );

      ref.invalidate(pendingFacultyRequestsProvider);
      _showActionSnackBar(
        title: 'Request Declined',
        message:
            '${faculty.name} has been notified to select a role again or submit a new faculty request.',
        accentColor: const Color(0xFFB91C1C),
        icon: Icons.cancel_outlined,
      );
    } catch (e) {
      _showErrorSnackBar('Decline failed: $e');
    }
  }

  void _openPendingFacultyDialog(List<Faculty> requests) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 28,
                spreadRadius: 2,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF5A0033),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Faculty Approval Requests',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: requests.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No pending faculty requests.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF475569),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: requests.map((item) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      SizedBox(
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final navigator =
                                                Navigator.of(dialogContext);
                                            await _approvePendingFaculty(item);
                                            if (dialogContext.mounted) {
                                              navigator.pop();
                                            }
                                          },
                                          icon: const Icon(Icons.check_rounded),
                                          label: const Text('Accept'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF15803D,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final navigator =
                                                Navigator.of(dialogContext);
                                            await _declinePendingFaculty(item);
                                            if (dialogContext.mounted) {
                                              navigator.pop();
                                            }
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                          label: const Text('Decline'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFB91C1C,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final pendingFacultyAsync = ref.watch(pendingFacultyRequestsProvider);

    // Colors — adapt to theme
    const primaryPurple = Color(0xFF720045);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: pageBg,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showDebugSessionInfo,
                child: const Text('Debug Session'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) {
          final totalSchedules = stats.totalSchedules;
          final totalUsers = stats.totalFaculty + stats.totalStudents;
          final totalConflicts = stats.totalConflicts;
          final recentConflicts = stats.recentConflicts;
          final facultyLoadData = stats.facultyLoad;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Standardized Maroon Gradient Banner)
                AdminHeaderContainer(
                  primaryColor: primaryPurple,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          pendingFacultyAsync.when(
                            data: (pending) {
                              final count = pending.length;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    tooltip: 'Faculty approvals',
                                    onPressed: () =>
                                        _openPendingFacultyDialog(pending),
                                    icon: const Icon(
                                      Icons.notifications_active_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          const ThemeModeToggle(compact: true),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isMobile)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'CITESched • Admin Dashboard',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back, ${userInfo?.userName ?? "Administrator"}',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CITESched • Admin Dashboard',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome back, ${userInfo?.userName ?? "Administrator"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const ReportModal(),
                              );
                            },
                            icon: const Icon(Icons.analytics_rounded, size: 24),
                            label: const Text('View Detailed Reports'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryPurple,
                              textStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                          if (!isMobile) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const UserListModal(),
                                );
                              },
                              icon: const Icon(Icons.people_rounded, size: 24),
                              label: const Text('Manage Users'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Statistics Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = isDesktop;
                    final conflictsLabel =
                        isWide ? 'Conflicts' : 'Unresolved Conflicts';
                    final cards = [
                      _StatCardConfig(
                        label: 'Scheduled Classes',
                        value: totalSchedules.toString(),
                        icon: Icons.calendar_today_rounded,
                        borderColor: primaryPurple,
                        iconColor: primaryPurple,
                        valueColor: primaryPurple,
                      ),
                      _StatCardConfig(
                        label: 'Active Users',
                        value: totalUsers.toString(),
                        icon: Icons.people_rounded,
                        borderColor: const Color(0xFF9333ea),
                        iconColor: const Color(0xFF9333ea),
                        valueColor: const Color(0xFF9333ea),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const UserListModal(),
                          );
                        },
                      ),
                      _StatCardConfig(
                        label: 'Total Subjects',
                        value: stats.totalSubjects.toString(),
                        icon: Icons.book_rounded,
                        borderColor: const Color(0xFFc026d3),
                        iconColor: const Color(0xFFc026d3),
                        valueColor: const Color(0xFFc026d3),
                      ),
                      _StatCardConfig(
                        label: 'Total Rooms',
                        value: stats.totalRooms.toString(),
                        icon: Icons.meeting_room_rounded,
                        borderColor: const Color(0xFFdb2777),
                        iconColor: const Color(0xFFdb2777),
                        valueColor: const Color(0xFFdb2777),
                      ),
                      _StatCardConfig(
                        label: conflictsLabel,
                        value: totalConflicts.toString(),
                        icon: Icons.warning_amber_rounded,
                        borderColor: const Color(0xFFb5179e),
                        iconColor: const Color(0xFFb5179e),
                        valueColor: const Color(0xFFb5179e),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ConflictListModal(
                              conflicts: recentConflicts,
                            ),
                          );
                        },
                      ),
                    ];

                    return _buildStatCards(cards, isWide);
                  },
                ),

                const SizedBox(height: 32),

                // Chart and Conflict Panel
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = isDesktop;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildChartCard(
                              context,
                              cardBg,
                              primaryPurple,
                              facultyLoadData,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildConflictCard(
                              context,
                              cardBg,
                              primaryPurple,
                              recentConflicts,
                              primaryPurple,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildChartCard(
                            context,
                            cardBg,
                            primaryPurple,
                            facultyLoadData,
                          ),
                          const SizedBox(height: 24),
                          _buildConflictCard(
                            context,
                            cardBg,
                            primaryPurple,
                            recentConflicts,
                            primaryPurple,
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 32),

                // Distribution Summaries
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = isDesktop;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDistributionPanel(
                              context,
                              'Section Distribution',
                              stats.sectionDistribution,
                              cardBg,
                              primaryPurple,
                              Icons.groups_rounded,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDistributionPanel(
                              context,
                              'Year Level Distribution',
                              stats.yearLevelDistribution,
                              cardBg,
                              const Color(0xFF9333ea),
                              Icons.layers_rounded,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildDistributionPanel(
                            context,
                            'Section Distribution',
                            stats.sectionDistribution,
                            cardBg,
                            primaryPurple,
                            Icons.groups_rounded,
                          ),
                          const SizedBox(height: 24),
                          _buildDistributionPanel(
                            context,
                            'Year Level Distribution',
                            stats.yearLevelDistribution,
                            cardBg,
                            const Color(0xFF9333ea),
                            Icons.layers_rounded,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(List<_StatCardConfig> cards, bool isWide) {
    if (isWide) {
      final rowChildren = <Widget>[];
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        rowChildren.add(
          Expanded(
            child: StatCard(
              label: card.label,
              value: card.value,
              icon: card.icon,
              borderColor: card.borderColor,
              iconColor: card.iconColor,
              valueColor: card.valueColor,
              onTap: card.onTap,
            ),
          ),
        );
        if (i < cards.length - 1) {
          rowChildren.add(const SizedBox(width: 16));
        }
      }
      return Row(children: rowChildren);
    }

    final columnChildren = <Widget>[];
    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      columnChildren.add(
        StatCard(
          label: card.label,
          value: card.value,
          icon: card.icon,
          borderColor: card.borderColor,
          iconColor: card.iconColor,
          valueColor: card.valueColor,
          onTap: card.onTap,
        ),
      );
      if (i < cards.length - 1) {
        columnChildren.add(const SizedBox(height: 16));
      }
    }
    return Column(children: columnChildren);
  }

  Widget _buildChartCard(
    BuildContext context,
    Color cardBg,
    Color headerBg,
    List<FacultyLoadData> data,
  ) {
    // Determine inner menu bg (from css: var(--inner-menu-bg))
    // Typically this is a specific color in the theme, but for now assuming headerBg/Maroon
    // based on "card-header { background: var(--inner-menu-bg); ... }"
    // If user layout uses Maroon for sidebar, likely inner-menu-bg is also maroon or slightly different.

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final borderColor =
        isDark ? Colors.white12 : Colors.black.withOpacity(0.1);
    final headerBorder =
        isDark ? Colors.white12 : Colors.black.withOpacity(0.5);
    final iconColor = isDark ? Colors.white70 : Colors.black;
    final iconMuted = isDark ? Colors.white54 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.hardEdge, // Needed for header rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                bottom: BorderSide(color: headerBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Faculty Teaching Load (Units)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: iconMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    // refresh logic
                  },
                ),
              ],
            ),
          ),
          // Chart
          Padding(
            padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 16 : 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);
                final minWidth =
                    (data.length * (isMobile ? 60.0 : 80.0)).clamp(320.0, 1200.0);
                if (!isMobile) {
                  return SizedBox(
                    height: 350,
                    width: constraints.maxWidth,
                    child: FacultyLoadChart(data: data),
                  );
                }

                final chartWidth =
                    minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: 280,
                    child: FacultyLoadChart(data: data),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictCard(
    BuildContext context,
    Color cardBg,
    Color headerBg,
    List<ScheduleConflict> conflicts,
    Color primaryColor,
  ) {
    final conflictCount = conflicts.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final borderColor =
        isDark ? Colors.white12 : Colors.black.withOpacity(0.15);
    final headerBorder =
        isDark ? Colors.white12 : Colors.black.withOpacity(1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                bottom: BorderSide(color: headerBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule Integrity',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  height: 350,
                  child: conflictCount > 0
                      ? ListView.builder(
                          itemCount: conflictCount,
                          itemBuilder: (context, index) {
                            final conflict = conflicts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFb5179e,
                                ).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: const Border(
                                  left: BorderSide(
                                    color: Color(0xFFb5179e),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Conflict Detected', // Or conflict.type
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFb5179e),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    conflict.message,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: textMuted.withOpacity(0.75),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size:
                                    80, // font-size: 3.5rem ~= 56px, increased slightly
                                color: const Color(0xFF2e7d32),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'All Clear!',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color.fromARGB(255, 168, 31, 31)
                                      : const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No scheduling conflicts found in the system.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ConflictListModal(
                          conflicts: conflicts,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Text('Resolve All Conflicts'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionPanel(
    BuildContext context,
    String title,
    List<DistributionData> data,
    Color cardBg,
    Color headerBg,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final borderColor =
        isDark ? Colors.white12 : Colors.black.withOpacity(0.15);
    final headerBorder =
        isDark ? Colors.white12 : Colors.black.withOpacity(1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                bottom: BorderSide(color: headerBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: textPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: data.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No data available',
                        style: GoogleFonts.poppins(color: textMuted),
                      ),
                    ),
                  )
                : Column(
                    children: data.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.label,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor:
                                        (item.count /
                                                data
                                                    .map((e) => e.count)
                                                    .reduce(
                                                      (a, b) => a > b ? a : b,
                                                    ))
                                            .clamp(0.0, 1.0),
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: headerBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${item.count}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: headerBg,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
// Triggering green status with new code period
