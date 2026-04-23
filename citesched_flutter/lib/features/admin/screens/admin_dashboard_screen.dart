import 'package:citesched_client/citesched_client.dart';
import 'dart:async';
import 'dart:convert';

import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';
import 'package:citesched_flutter/features/admin/widgets/conflict_list_modal.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/features/admin/widgets/faculty_load_chart.dart';
import 'package:citesched_flutter/features/admin/widgets/report_modal.dart';
import 'package:citesched_flutter/features/admin/widgets/stat_card.dart';
import 'package:citesched_flutter/features/admin/widgets/user_list_modal.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/password_reset_dialog.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return await client.admin.getDashboardStats();
});

final pendingFacultyRequestsProvider = FutureProvider<List<Faculty>>((
  ref,
) async {
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

final recentStudentSignupsProvider = FutureProvider<List<Student>>((ref) async {
  final activeStudents = await client.admin.getAllStudents(isActive: true);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final recent = activeStudents
      .where((student) => student.createdAt.isAfter(cutoff))
      .toList();
  recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return recent;
});

const _adminDashboardTitle = 'CITESched • Admin Dashboard';
const _yearLevelDistributionTitle = 'Year Level Distribution';
const _sectionDistributionTitle = 'Section Distribution';

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

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Timer? _refreshTimer;
  final FlutterSecureStorage _notificationStorage = const FlutterSecureStorage();
  final Set<int> _readStudentNotificationIds = <int>{};
  final Set<int> _readFacultyNotificationIds = <int>{};
  final Set<String> _selectedNotificationKeys = <String>{};
  String? _notificationStorageOwnerKey;

  String _notificationStorageKey(String ownerKey) =>
      'admin_notification_reads_v1:$ownerKey';

  String _studentNotificationKey(Student student) => 'student:${student.id ?? 0}';

  String _facultyNotificationKey(Faculty faculty) => 'faculty:${faculty.id ?? 0}';

  bool _isStudentNotificationRead(Student student) {
    final id = student.id;
    return id != null && _readStudentNotificationIds.contains(id);
  }

  bool _isFacultyNotificationRead(Faculty faculty) {
    final id = faculty.id;
    return id != null && _readFacultyNotificationIds.contains(id);
  }

  Future<void> _loadNotificationStateForAdmin(String? email) async {
    final ownerKey = email?.trim().toLowerCase();
    if (!mounted || ownerKey == _notificationStorageOwnerKey) return;

    _notificationStorageOwnerKey = ownerKey;
    if (ownerKey == null || ownerKey.isEmpty) {
      if (!mounted) return;
      setState(() {
        _readStudentNotificationIds.clear();
        _readFacultyNotificationIds.clear();
        _selectedNotificationKeys.clear();
      });
      return;
    }

    try {
      final raw = await _notificationStorage.read(
        key: _notificationStorageKey(ownerKey),
      );
      final decoded = raw == null ? null : jsonDecode(raw);
      final studentItems =
          (decoded is Map<String, dynamic> ? decoded['students'] : null)
              as List<dynamic>? ??
          const <dynamic>[];
      final facultyItems =
          (decoded is Map<String, dynamic> ? decoded['faculty'] : null)
              as List<dynamic>? ??
          const <dynamic>[];

      if (!mounted || _notificationStorageOwnerKey != ownerKey) return;

      setState(() {
        _readStudentNotificationIds
          ..clear()
          ..addAll(
            studentItems
                .map((item) => item is int ? item : int.tryParse('$item'))
                .whereType<int>(),
          );
        _readFacultyNotificationIds
          ..clear()
          ..addAll(
            facultyItems
                .map((item) => item is int ? item : int.tryParse('$item'))
                .whereType<int>(),
          );
        _selectedNotificationKeys.clear();
      });
    } catch (_) {
      if (!mounted || _notificationStorageOwnerKey != ownerKey) return;
      setState(() {
        _readStudentNotificationIds.clear();
        _readFacultyNotificationIds.clear();
        _selectedNotificationKeys.clear();
      });
    }
  }

  Future<void> _persistNotificationState() async {
    final ownerKey = _notificationStorageOwnerKey;
    if (ownerKey == null || ownerKey.isEmpty) return;

    final payload = jsonEncode({
      'students': _readStudentNotificationIds.toList()..sort(),
      'faculty': _readFacultyNotificationIds.toList()..sort(),
    });

    await _notificationStorage.write(
      key: _notificationStorageKey(ownerKey),
      value: payload,
    );
  }

  void _markStudentNotificationAsRead(Student student) {
    final id = student.id;
    if (id == null || _readStudentNotificationIds.contains(id)) return;

    setState(() {
      _readStudentNotificationIds.add(id);
      _selectedNotificationKeys.remove(_studentNotificationKey(student));
    });
    unawaited(_persistNotificationState());
  }

  void _markFacultyNotificationAsRead(Faculty faculty) {
    final id = faculty.id;
    if (id == null || _readFacultyNotificationIds.contains(id)) return;

    setState(() {
      _readFacultyNotificationIds.add(id);
      _selectedNotificationKeys.remove(_facultyNotificationKey(faculty));
    });
    unawaited(_persistNotificationState());
  }

  void _pruneNotificationState({
    required List<Student> recentStudents,
    required List<Faculty> pendingFaculty,
  }) {
    final studentIds = recentStudents.map((item) => item.id).whereType<int>().toSet();
    final facultyIds = pendingFaculty.map((item) => item.id).whereType<int>().toSet();

    _readStudentNotificationIds.removeWhere((id) => !studentIds.contains(id));
    _readFacultyNotificationIds.removeWhere((id) => !facultyIds.contains(id));
    _selectedNotificationKeys.removeWhere((key) {
      if (key.startsWith('student:')) {
        return !recentStudents.any((item) => _studentNotificationKey(item) == key);
      }
      if (key.startsWith('faculty:')) {
        return !pendingFaculty.any((item) => _facultyNotificationKey(item) == key);
      }
      return true;
    });
    unawaited(_persistNotificationState());
  }

  int _unreadStudentCount(List<Student> recentStudents) =>
      recentStudents.where((item) => !_isStudentNotificationRead(item)).length;

  int _unreadFacultyCount(List<Faculty> pendingFaculty) =>
      pendingFaculty.where((item) => !_isFacultyNotificationRead(item)).length;

  void _toggleNotificationSelection(String key, bool selected) {
    setState(() {
      if (selected) {
        _selectedNotificationKeys.add(key);
      } else {
        _selectedNotificationKeys.remove(key);
      }
    });
  }

  void _markNotificationsAsRead({
    required List<Student> recentStudents,
    required List<Faculty> pendingFaculty,
    bool markAll = false,
  }) {
    setState(() {
      if (markAll) {
        _readStudentNotificationIds.addAll(
          recentStudents.map((item) => item.id).whereType<int>(),
        );
        _readFacultyNotificationIds.addAll(
          pendingFaculty.map((item) => item.id).whereType<int>(),
        );
        _selectedNotificationKeys.clear();
        return;
      }

      for (final student in recentStudents) {
        final id = student.id;
        if (id != null &&
            _selectedNotificationKeys.contains(_studentNotificationKey(student))) {
          _readStudentNotificationIds.add(id);
        }
      }

      for (final faculty in pendingFaculty) {
        final id = faculty.id;
        if (id != null &&
            _selectedNotificationKeys.contains(_facultyNotificationKey(faculty))) {
          _readFacultyNotificationIds.add(id);
        }
      }

      _selectedNotificationKeys.clear();
    });
    unawaited(_persistNotificationState());
  }

  void _markNotificationsAsUnread({
    required List<Student> recentStudents,
    required List<Faculty> pendingFaculty,
  }) {
    setState(() {
      for (final student in recentStudents) {
        final id = student.id;
        if (id != null &&
            _selectedNotificationKeys.contains(_studentNotificationKey(student))) {
          _readStudentNotificationIds.remove(id);
        }
      }

      for (final faculty in pendingFaculty) {
        final id = faculty.id;
        if (id != null &&
            _selectedNotificationKeys.contains(_facultyNotificationKey(faculty))) {
          _readFacultyNotificationIds.remove(id);
        }
      }

      _selectedNotificationKeys.clear();
    });
    unawaited(_persistNotificationState());
  }

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
    ref.listenManual<UserInfo?>(authProvider, (previous, next) {
      unawaited(_loadNotificationStateForAdmin(next?.email));
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(pendingFacultyRequestsProvider);
      ref.invalidate(recentStudentSignupsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildNotificationButton(
    AsyncValue<List<Faculty>> pendingFacultyAsync,
    AsyncValue<List<Student>> recentStudentAsync,
  ) {
    final adminEmail = ref.read(authProvider)?.email;
    unawaited(_loadNotificationStateForAdmin(adminEmail));

    final pending = pendingFacultyAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <Faculty>[],
    );
    final recentStudents = recentStudentAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <Student>[],
    );
    _pruneNotificationState(
      recentStudents: recentStudents,
      pendingFaculty: pending,
    );
    final count =
        _unreadFacultyCount(pending) + _unreadStudentCount(recentStudents);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Admin notifications',
          onPressed: () => _openAdminNotificationsInbox(
            pendingFaculty: pending,
            recentStudents: recentStudents,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
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
  }

  Widget _buildAdminHeader({
    required BuildContext context,
    required AsyncValue<List<Faculty>> pendingFacultyAsync,
    required AsyncValue<List<Student>> recentStudentAsync,
    required UserInfo? userInfo,
    required bool isMobile,
    required Color primaryPurple,
  }) {
    return AdminHeaderContainer(
      primaryColor: primaryPurple,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildNotificationButton(
                pendingFacultyAsync,
                recentStudentAsync,
              ),
              const SizedBox(width: 8),
              const ThemeModeToggle(compact: true),
            ],
          ),
          const SizedBox(height: 12),
          _buildDashboardHeader(userInfo, isMobile),
          const SizedBox(height: 32),
          _buildHeaderActions(context, primaryPurple, isMobile, userInfo),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(UserInfo? userInfo, bool isMobile) {
    if (isMobile) {
      return _buildMobileHeader(userInfo);
    }
    return _buildDesktopHeader(userInfo);
  }

  Widget _buildMobileHeader(UserInfo? userInfo) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.dashboard_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _adminDashboardTitle,
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
    );
  }

  Widget _buildDesktopHeader(UserInfo? userInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                _adminDashboardTitle,
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
    );
  }

  Widget _buildHeaderActions(
    BuildContext context,
    Color primaryPurple,
    bool isMobile,
    UserInfo? userInfo,
  ) {
    return Wrap(
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => showPasswordResetDialog(
            context,
            initialEmail: userInfo?.email,
            lockEmail: userInfo?.email?.isNotEmpty == true,
            title: 'Reset Password',
            subtitle:
                'Confirm your email, enter the code, and update your admin password.',
          ),
          icon: const Icon(Icons.lock_reset_rounded, size: 22),
          label: const Text('Reset Password'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (!isMobile)
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
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCardsSection(
    BuildContext context,
    DashboardStats stats,
    bool isDesktop,
    List<ScheduleConflict> recentConflicts,
  ) {
    final cards = [
      _StatCardConfig(
        label: 'Faculty',
        value: stats.totalFaculty.toString(),
        icon: Icons.people_rounded,
        borderColor: const Color(0xFF8b5cf6),
        iconColor: const Color(0xFF8b5cf6),
        valueColor: const Color(0xFF8b5cf6),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const UserListModal(),
          );
        },
      ),
      _StatCardConfig(
        label: 'Students',
        value: stats.totalStudents.toString(),
        icon: Icons.school_rounded,
        borderColor: const Color(0xFF06b6d4),
        iconColor: const Color(0xFF06b6d4),
        valueColor: const Color(0xFF06b6d4),
      ),
      _StatCardConfig(
        label: 'Schedules',
        value: stats.totalSchedules.toString(),
        icon: Icons.calendar_month_rounded,
        borderColor: const Color(0xFFf59e0b),
        iconColor: const Color(0xFFf59e0b),
        valueColor: const Color(0xFFf59e0b),
      ),
      _StatCardConfig(
        label: 'Conflicts',
        value: stats.totalConflicts.toString(),
        icon: Icons.warning_rounded,
        borderColor: const Color(0xFFef4444),
        iconColor: const Color(0xFFef4444),
        valueColor: const Color(0xFFef4444),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => ConflictListModal(conflicts: recentConflicts),
          );
        },
      ),
    ];

    return _buildStatCards(cards, isDesktop);
  }

  Widget _buildChartAndConflictSection(
    BuildContext context,
    Color cardBg,
    Color primaryPurple,
    List<FacultyLoadData> facultyLoadData,
    List<ScheduleConflict> recentConflicts,
    double width,
  ) {
    final chartCard = _buildChartCard(
      context,
      cardBg,
      primaryPurple,
      facultyLoadData,
    );
    final conflictCard = _buildConflictCard(
      context,
      cardBg,
      primaryPurple,
      recentConflicts,
      primaryPurple,
    );

    if (width > 1200) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: chartCard),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: conflictCard),
        ],
      );
    }

    return Column(
      children: [
        chartCard,
        const SizedBox(height: 24),
        conflictCard,
      ],
    );
  }

  Widget _buildDistributionSection(
    BuildContext context,
    Color cardBg,
    Color primaryPurple,
    List<DistributionData> yearLevelDistribution,
    List<DistributionData> sectionDistribution,
    double width,
  ) {
    final programCard = _buildDistributionPanel(
      context,
      _yearLevelDistributionTitle,
      yearLevelDistribution,
      cardBg,
      primaryPurple,
      Icons.layers_rounded,
    );
    final sectionCard = _buildDistributionPanel(
      context,
      _sectionDistributionTitle,
      sectionDistribution,
      cardBg,
      primaryPurple,
      Icons.groups_rounded,
    );

    if (width > 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: programCard),
          const SizedBox(width: 24),
          Expanded(child: sectionCard),
        ],
      );
    }

    return Column(
      children: [
        programCard,
        const SizedBox(height: 24),
        sectionCard,
      ],
    );
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

  void _openAdminNotificationsDialog({
    required List<Faculty> pendingFaculty,
    required List<Student> recentStudents,
  }) {
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
            borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5A0033), Color(0xFFB5179E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin Notifications',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNotificationSectionTitle(
                        title: 'New Student Sign-ups',
                        count: recentStudents.length,
                        icon: Icons.school_rounded,
                        color: const Color(0xFF15803D),
                      ),
                      const SizedBox(height: 12),
                      if (recentStudents.isEmpty)
                        _buildNotificationEmptyState(
                          'No recent student sign-ups in the last 7 days.',
                        )
                      else
                        ...recentStudents.map(
                          (student) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15803D).withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${student.studentNumber} • ${student.email}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildNotificationChip(
                                            label: student.course,
                                            color: const Color(0xFF15803D),
                                          ),
                                          if ((student.section ?? '').isNotEmpty)
                                            _buildNotificationChip(
                                              label: 'Section ${student.section}',
                                              color: const Color(0xFF720045),
                                            ),
                                          _buildNotificationChip(
                                            label:
                                                'Signed up ${_relativeDate(student.createdAt)}',
                                            color: const Color(0xFFF59E0B),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildNotificationSectionTitle(
                        title: 'Faculty Approval Requests',
                        count: pendingFaculty.length,
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFF720045),
                      ),
                      const SizedBox(height: 12),
                      if (pendingFaculty.isEmpty)
                        _buildNotificationEmptyState(
                          'No pending faculty requests.',
                        )
                      else
                        ...pendingFaculty.map((item) {
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
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdminNotificationsInbox({
    required List<Faculty> pendingFaculty,
    required List<Student> recentStudents,
  }) {
    _pruneNotificationState(
      recentStudents: recentStudents,
      pendingFaculty: pendingFaculty,
    );
    var selectedSection = pendingFaculty.isNotEmpty && recentStudents.isEmpty
        ? 'faculty'
        : 'students';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final unreadStudents = _unreadStudentCount(recentStudents);
          final unreadFaculty = _unreadFacultyCount(pendingFaculty);
          final hasSelection = _selectedNotificationKeys.isNotEmpty;
          final hasUnread = unreadStudents + unreadFaculty > 0;

          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5A0033), Color(0xFFB5179E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Admin Notifications',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Text(
                          hasSelection
                              ? '${_selectedNotificationKeys.length} selected'
                              : hasUnread
                                  ? '${unreadStudents + unreadFaculty} unread notifications'
                                  : 'All notifications are read',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: hasSelection
                                  ? () {
                                      _markNotificationsAsUnread(
                                        recentStudents: recentStudents,
                                        pendingFaculty: pendingFaculty,
                                      );
                                      setDialogState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
                              label: const Text('Mark as unread'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF15803D),
                                side: const BorderSide(color: Color(0xFF15803D)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: hasSelection
                                  ? () {
                                      _markNotificationsAsRead(
                                        recentStudents: recentStudents,
                                        pendingFaculty: pendingFaculty,
                                      );
                                      setDialogState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.done_rounded, size: 18),
                              label: const Text('Mark as read'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF720045),
                                side: const BorderSide(color: Color(0xFF720045)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: hasUnread
                                  ? () {
                                      _markNotificationsAsRead(
                                        recentStudents: recentStudents,
                                        pendingFaculty: pendingFaculty,
                                        markAll: true,
                                      );
                                      setDialogState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.done_all_rounded, size: 18),
                              label: const Text('Mark all as read'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF720045),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildNotificationToggleTab(
                              label: 'New Student Sign-ups',
                              unreadCount: unreadStudents,
                              isSelected: selectedSection == 'students',
                              selectedColor: const Color(0xFF15803D),
                              onTap: () {
                                selectedSection = 'students';
                                setDialogState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNotificationToggleTab(
                              label: 'Faculty Approval Requests',
                              unreadCount: unreadFaculty,
                              isSelected: selectedSection == 'faculty',
                              selectedColor: const Color(0xFF720045),
                              onTap: () {
                                selectedSection = 'faculty';
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: selectedSection == 'students'
                            ? [
                                _buildInboxSectionTitle(
                                  title: 'New Student Sign-ups',
                                  unreadCount: unreadStudents,
                                  totalCount: recentStudents.length,
                                  icon: Icons.school_rounded,
                                  color: const Color(0xFF15803D),
                                ),
                                const SizedBox(height: 12),
                                if (recentStudents.isEmpty)
                                  _buildNotificationEmptyState(
                                    'No recent student sign-ups in the last 7 days.',
                                  )
                                else
                                  ...recentStudents.map(
                                    (student) => _buildStudentNotificationCard(
                                      student: student,
                                      setDialogState: setDialogState,
                                    ),
                                  ),
                              ]
                            : [
                                _buildInboxSectionTitle(
                                  title: 'Faculty Approval Requests',
                                  unreadCount: unreadFaculty,
                                  totalCount: pendingFaculty.length,
                                  icon: Icons.verified_user_rounded,
                                  color: const Color(0xFF720045),
                                ),
                                const SizedBox(height: 12),
                                if (pendingFaculty.isEmpty)
                                  _buildNotificationEmptyState(
                                    'No pending faculty requests.',
                                  )
                                else
                                  ...pendingFaculty.map(
                                    (item) => _buildFacultyNotificationCard(
                                      item: item,
                                      dialogContext: dialogContext,
                                      setDialogState: setDialogState,
                                    ),
                                  ),
                              ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationSectionTitle({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildInboxSectionTitle({
    required String title,
    required int unreadCount,
    required int totalCount,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$unreadCount unread / $totalCount',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggleTab({
    required String label,
    required int unreadCount,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    final foreground = isSelected ? Colors.white : const Color(0xFF475569);
    final background =
        isSelected ? selectedColor : Colors.white.withValues(alpha: 0.88);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.18)
                        : selectedColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : selectedColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNotificationStatusChip({required bool isRead}) {
    if (isRead) {
      return const SizedBox.shrink();
    }

    const color = Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        isRead ? 'READ' : 'NEW',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildStudentNotificationCard({
    required Student student,
    required void Function(void Function()) setDialogState,
  }) {
    final isRead = _isStudentNotificationRead(student);
    final key = _studentNotificationKey(student);
    final isSelected = _selectedNotificationKeys.contains(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? const Color(0xFFF8FAFC).withValues(alpha: 0.72)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF15803D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            activeColor: const Color(0xFF15803D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) {
              _toggleNotificationSelection(key, value ?? false);
              setDialogState(() {});
            },
          ),
          const SizedBox(width: 4),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF15803D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF15803D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _markStudentNotificationAsRead(student);
                          setDialogState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            student.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildNotificationStatusChip(isRead: isRead),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.studentNumber} • ${student.email}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildNotificationChip(
                      label: student.course,
                      color: const Color(0xFF15803D),
                    ),
                    if ((student.section ?? '').isNotEmpty)
                      _buildNotificationChip(
                        label: 'Section ${student.section}',
                        color: const Color(0xFF720045),
                      ),
                    _buildNotificationChip(
                      label: 'Signed up ${_relativeDate(student.createdAt)}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyNotificationCard({
    required Faculty item,
    required BuildContext dialogContext,
    required void Function(void Function()) setDialogState,
  }) {
    final isRead = _isFacultyNotificationRead(item);
    final key = _facultyNotificationKey(item);
    final isSelected = _selectedNotificationKeys.contains(key);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? const Color(0xFFF8FAFC).withValues(alpha: 0.72)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF720045) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            activeColor: const Color(0xFF720045),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) {
              _toggleNotificationSelection(key, value ?? false);
              setDialogState(() {});
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _markFacultyNotificationAsRead(item);
                          setDialogState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildNotificationStatusChip(isRead: isRead),
                  ],
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
                            _markFacultyNotificationAsRead(item);
                            setDialogState(() {});
                            final navigator = Navigator.of(dialogContext);
                            await _approvePendingFaculty(item);
                            if (dialogContext.mounted) {
                              navigator.pop();
                            }
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            _markFacultyNotificationAsRead(item);
                            setDialogState(() {});
                            final navigator = Navigator.of(dialogContext);
                            await _declinePendingFaculty(item);
                            if (dialogContext.mounted) {
                              navigator.pop();
                            }
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Decline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final pendingFacultyAsync = ref.watch(pendingFacultyRequestsProvider);
    final recentStudentAsync = ref.watch(recentStudentSignupsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildDashboardState(
        context: context,
        statsAsync: statsAsync,
        pendingFacultyAsync: pendingFacultyAsync,
        recentStudentAsync: recentStudentAsync,
        userInfo: userInfo,
      ),
    );
  }

  Widget _buildDashboardState({
    required BuildContext context,
    required AsyncValue<DashboardStats> statsAsync,
    required AsyncValue<List<Faculty>> pendingFacultyAsync,
    required AsyncValue<List<Student>> recentStudentAsync,
    required UserInfo? userInfo,
  }) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppErrorDialog.message(err)),
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
      data: (stats) => _buildDashboardContent(
        context: context,
        stats: stats,
        pendingFacultyAsync: pendingFacultyAsync,
        recentStudentAsync: recentStudentAsync,
        userInfo: userInfo,
        isMobile: isMobile,
        isDesktop: isDesktop,
      ),
    );
  }

  Widget _buildDashboardContent({
    required BuildContext context,
    required DashboardStats stats,
    required AsyncValue<List<Faculty>> pendingFacultyAsync,
    required AsyncValue<List<Student>> recentStudentAsync,
    required UserInfo? userInfo,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final cardBg = Theme.of(context).cardColor;
    const primaryPurple = Color(0xFF720045);
    final recentConflicts = stats.recentConflicts;
    final facultyLoadData = stats.facultyLoad;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminHeader(
            context: context,
            pendingFacultyAsync: pendingFacultyAsync,
            recentStudentAsync: recentStudentAsync,
            userInfo: userInfo,
            isMobile: isMobile,
            primaryPurple: primaryPurple,
          ),
          const SizedBox(height: 32),
          _buildStatCardsSection(context, stats, isDesktop, recentConflicts),
          const SizedBox(height: 32),
          _buildChartAndConflictSection(
            context,
            cardBg,
            primaryPurple,
            facultyLoadData,
            recentConflicts,
            MediaQuery.of(context).size.width,
          ),
          const SizedBox(height: 32),
          _buildDistributionSection(
            context,
            cardBg,
            primaryPurple,
            stats.yearLevelDistribution,
            stats.sectionDistribution,
            MediaQuery.of(context).size.width,
          ),
        ],
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
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final borderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.1);
    final headerBorder = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.5);
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
            padding: EdgeInsets.all(
              ResponsiveHelper.isMobile(context) ? 16 : 24,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);
                final minWidth = (data.length * (isMobile ? 60.0 : 80.0)).clamp(
                  320.0,
                  1200.0,
                );
                if (!isMobile) {
                  return SizedBox(
                    height: 350,
                    width: constraints.maxWidth,
                    child: FacultyLoadChart(data: data),
                  );
                }

                final chartWidth = minWidth > constraints.maxWidth
                    ? minWidth
                    : constraints.maxWidth;
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
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final borderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.15);
    final headerBorder = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                                ).withValues(alpha: 0.05),
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
                                      color: textMuted.withValues(alpha: 0.75),
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
                              const Icon(
                                Icons.check_circle_rounded,
                                size:
                                    80, // font-size: 3.5rem ~= 56px, increased slightly
                                color: Color(0xFF2e7d32),
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
                      shadowColor: primaryColor.withValues(alpha: 0.3),
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
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final borderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.15);
    final headerBorder = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 1.0);
    final maxCount = _maxDistributionCount(data);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                                    widthFactor: (item.count / maxCount).clamp(
                                      0.0,
                                      1.0,
                                    ),
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

  int _maxDistributionCount(List<DistributionData> data) {
    var maxCount = 1;
    for (final item in data) {
      if (item.count > maxCount) {
        maxCount = item.count;
      }
    }
    return maxCount;
  }
}


