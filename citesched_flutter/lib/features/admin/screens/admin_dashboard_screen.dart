import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/widgets/conflict_list_modal.dart';
import 'package:citesched_flutter/features/admin/widgets/faculty_load_chart.dart';
import 'package:citesched_flutter/features/admin/widgets/stat_card.dart';
import 'package:citesched_flutter/features/admin/widgets/user_list_modal.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return await client.admin.getDashboardStats();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors matching Django design
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final primaryPurple = isDark
        ? const Color(0xFFa21caf)
        : const Color(0xFF720045);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    // Django CSS Variables approximation
    // var(--sidebar-bg) -> #720045
    // var(--sidebar-hover) -> Linear gradient end
    // var(--card-bg) -> Colors.white (or dark equivalent)

    return Scaffold(
      backgroundColor: bgBody,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar (Restored from Django design)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28), // ~1.8rem
                  margin: const EdgeInsets.only(bottom: 40), // ~2.5rem
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryPurple,
                        const Color.fromARGB(
                          155,
                          85,
                          11,
                          74,
                        ), // Approximate hover/light var
                      ],
                    ),
                    borderRadius: BorderRadius.circular(19), // ~1.2rem
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF720045).withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    'CITESched — Faculty Loading',
                    style: GoogleFonts.poppins(
                      fontSize: 24, // clamp(1.1rem, 4vw, 1.7rem) approx
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // text-center
                    children: [
                      Text(
                        'Welcome back, ${userInfo?.userName ?? "Administrator"}',
                        style: GoogleFonts.poppins(
                          fontSize: 36, // ~2.3rem
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Overview of the CITE Department\'s current semester status',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Statistics Cards (Rows mb-5 g-4)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Scheduled Classes',
                              value: totalSchedules.toString(),
                              icon: Icons
                                  .calendar_today_rounded, // bi-calendar-check equivalent
                              borderColor: primaryPurple,
                              iconColor: primaryPurple,
                              valueColor: primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: StatCard(
                              label: 'Active Users',
                              value: totalUsers.toString(),
                              icon: Icons.people_rounded, // bi-people
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
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: StatCard(
                              label: 'Unresolved Conflicts',
                              value: totalConflicts.toString(),
                              icon: Icons
                                  .warning_amber_rounded, // bi-exclamation-triangle
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
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          StatCard(
                            label: 'Scheduled Classes',
                            value: totalSchedules.toString(),
                            icon: Icons.calendar_today_rounded,
                            borderColor: primaryPurple,
                            iconColor: primaryPurple,
                            valueColor: primaryPurple,
                          ),
                          const SizedBox(height: 16),
                          StatCard(
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
                          const SizedBox(height: 16),
                          StatCard(
                            label: 'Unresolved Conflicts',
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
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 32),

                // Chart and Conflict Panel
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildChartCard(
                              context,
                              cardBg,
                              primaryPurple, // Header uses sidebar-bg equivalent
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
              ],
            ),
          );
        },
      ),
    );
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

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(19), // 1.2rem
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge, // Needed for header rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ), // 1.2rem 1.5rem
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF720045),
                  const Color(0xFF9333ea),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Faculty Teaching Load (Hours)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
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
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 350,
              child: FacultyLoadChart(data: data),
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
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(19), // 1.2rem
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF720045),
                  const Color(0xFF9333ea),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Schedule Integrity',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                                      ? const Color(0xFFE2E8F0)
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: Text(
                      'Resolve All Conflicts',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
