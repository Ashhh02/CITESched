import 'package:citesched_client/citesched_client.dart';
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

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

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
                onPressed: () async {
                  try {
                    final debugInfo = await client.debug.getSessionInfo();
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Debug Session Info'),
                        content: SingleChildScrollView(
                          child: Text(debugInfo.toString()),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Debug failed: $e')),
                    );
                  }
                },
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
                        children: const [
                          ThemeModeToggle(compact: true),
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
                            const SizedBox(width: 28),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CITESched • Admin Dashboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome back, ${userInfo?.userName ?? "Administrator"}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            const SizedBox(width: 16),
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
