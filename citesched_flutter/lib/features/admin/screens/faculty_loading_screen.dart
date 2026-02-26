import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/utils/date_utils.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_load_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';

class FacultyLoadingScreen extends ConsumerStatefulWidget {
  const FacultyLoadingScreen({super.key});

  @override
  ConsumerState<FacultyLoadingScreen> createState() =>
      _FacultyLoadingScreenState();
}

class _FacultyLoadingScreenState extends ConsumerState<FacultyLoadingScreen> {
  String _searchQuery = '';
  String? _selectedFaculty;
  bool _showArchived = false;
  bool _showConflictDetails = false;
  final TextEditingController _searchController = TextEditingController();

  // Color scheme matching admin sidebar
  final Color maroonColor = const Color(0xFF720045);
  final Color innerMenuBg = const Color(0xFF7b004f);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNewAssignmentModal() {
    showDialog(
      context: context,
      builder: (context) => _NewAssignmentModal(
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(schedulesProvider);
        },
      ),
    );
  }

  void _showEditAssignmentModal(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => _EditAssignmentModal(
        schedule: schedule,
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(schedulesProvider);
        },
      ),
    );
    if (!mounted) return;
  }

  void _restoreSchedule(Schedule schedule) async {
    try {
      final toRestore = schedule.copyWith(isActive: true);
      await client.admin.updateSchedule(toRestore);
      ref.invalidate(schedulesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _permanentDeleteSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Permanent Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to PERMANENTLY delete this assignment? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Permanently', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await client.admin.deleteSchedule(
          schedule.id!,
        ); // Assuming it calls serverpod deleteRow if modified properly, or we create physical delete
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment permanently deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting assignment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _archiveSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive this schedule assignment?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Archive', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await client.admin.deleteSchedule(schedule.id!);
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment archived successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error archiving assignment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildToggleBtn({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    required IconData icon,
    required bool isDark,
    required Color maroonColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? maroonColor
              : (isDark ? Colors.transparent : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomListProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final allConflictsAsync = ref.watch(allConflictsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final isMobile = ResponsiveHelper.isMobile(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Standardized Maroon Gradient Banner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      maroonColor,
                      const Color(0xFF8e005b),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: maroonColor.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
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
                            Icons.assignment_ind_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faculty Loading',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 24 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage faculty schedule assignments and workload',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 12 : 16,
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
                      onPressed: _showNewAssignmentModal,
                      icon: const Icon(Icons.add_rounded, size: 24),
                      label: Text(
                        isMobile ? 'Add' : 'Assign Subject',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: maroonColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 28,
                          vertical: isMobile ? 12 : 18,
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
              const SizedBox(height: 24),

              // Conflict Warning Banner
              _buildConflictBanner(allConflictsAsync),
              const SizedBox(height: 20),

              // Search and Filter Row
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.transparent
                              : Colors.grey[300]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E293B,
                            ).withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: maroonColor,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                              cursorColor: maroonColor,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'Search by faculty, subject, or section...',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[600]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // View Toggle (Active/Archived)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.transparent : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleBtn(
                          title: 'Active',
                          isActive: !_showArchived,
                          onTap: () => setState(() => _showArchived = false),
                          icon: Icons.check_circle_outline,
                          isDark: isDark,
                          maroonColor: maroonColor,
                        ),
                        _buildToggleBtn(
                          title: 'Archived',
                          isActive: _showArchived,
                          onTap: () => setState(() => _showArchived = true),
                          icon: Icons.archive_outlined,
                          isDark: isDark,
                          maroonColor: maroonColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Faculty Filter
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.transparent
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: facultyAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => const Text('Error'),
                        data: (faculty) => DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFaculty,
                            hint: Text(
                              'Filter by Faculty',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Faculty',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              ...faculty.map(
                                (f) => DropdownMenuItem<String>(
                                  value: f.id.toString(),
                                  child: Text(
                                    f.name,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFaculty = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: maroonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: maroonColor.withOpacity(0.2),
                    ),
                  ),
                  indicatorColor: maroonColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: maroonColor,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Faculty Loading Summary'),
                    Tab(text: 'Subject Assignments'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Content Area
              Expanded(
                child: TabBarView(
                  children: [
                    _buildFacultySummaryView(
                      schedulesAsync,
                      facultyAsync,
                      subjectsAsync,
                      roomsAsync,
                      timeslotsAsync,
                      isDark,
                    ),
                    _buildSubjectAssignmentsView(
                      schedulesAsync,
                      facultyAsync,
                      subjectsAsync,
                      roomsAsync,
                      timeslotsAsync,
                      isDark,
                      maroonColor,
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

  Widget _buildSubjectAssignmentsView(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue<List<Room>> roomsAsync,
    AsyncValue<List<Timeslot>> timeslotsAsync,
    bool isDark,
    Color maroonColor,
  ) {
    return Column(
      children: [
        Expanded(
          child: schedulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading schedules',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(schedulesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (schedules) {
              return facultyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(child: Text('Error')),
                data: (facultyList) {
                  return subjectsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const Center(child: Text('Error')),
                    data: (subjectList) {
                      return roomsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) =>
                            const Center(child: Text('Error')),
                        data: (roomList) {
                          return timeslotsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) =>
                                const Center(child: Text('Error')),
                            data: (timeslotList) {
                              // Create maps for lookup
                              final facultyMap = {
                                for (var f in facultyList) f.id!: f,
                              };
                              final subjectMap = {
                                for (var s in subjectList) s.id!: s,
                              };
                              final roomMap = {
                                for (var r in roomList) r.id!: r,
                              };
                              final timeslotMap = {
                                for (var t in timeslotList) t.id!: t,
                              };

                              final filteredSchedules = schedules.where((
                                schedule,
                              ) {
                                final matchesSearch =
                                    _searchQuery.isEmpty ||
                                    () {
                                      final faculty =
                                          facultyMap[schedule.facultyId];
                                      final subject =
                                          subjectMap[schedule.subjectId];
                                      return (faculty?.name
                                                  .toLowerCase()
                                                  .contains(_searchQuery) ??
                                              false) ||
                                          (subject?.name.toLowerCase().contains(
                                                _searchQuery,
                                              ) ??
                                              false) ||
                                          schedule.section
                                              .toLowerCase()
                                              .contains(_searchQuery);
                                    }();

                                final matchesFaculty =
                                    _selectedFaculty == null ||
                                    schedule.facultyId.toString() ==
                                        _selectedFaculty;

                                final matchesArchived =
                                    schedule.isActive == !_showArchived;

                                return matchesSearch &&
                                    matchesFaculty &&
                                    matchesArchived;
                              }).toList();

                              if (filteredSchedules.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'No assignments yet'
                                            : 'No assignments found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_searchQuery.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Click "New Assignment" to get started',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
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
                                        color: maroonColor.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.assignment_rounded,
                                            color: maroonColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Schedule Assignments',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: maroonColor,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: maroonColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${filteredSchedules.length} Total',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
                                              ),
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.vertical,
                                                child: DataTable(
                                                  headingRowColor:
                                                      WidgetStateProperty.all(
                                                        maroonColor,
                                                      ),
                                                  headingTextStyle:
                                                      GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        letterSpacing: 0.5,
                                                      ),
                                                  dataRowMinHeight: 70,
                                                  dataRowMaxHeight: 90,
                                                  columnSpacing: 28,
                                                  horizontalMargin: 24,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                  columns: const [
                                                    DataColumn(
                                                      label: Text('FACULTY'),
                                                    ),
                                                    DataColumn(
                                                      label: Text('SUBJECT'),
                                                    ),
                                                    DataColumn(
                                                      label: Text('SECTION'),
                                                    ),
                                                    DataColumn(
                                                      label: Text('LOAD'),
                                                    ),
                                                    DataColumn(
                                                      label: Text('UNITS'),
                                                    ),
                                                    DataColumn(
                                                      label: Text('HOURS'),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'ROOM & SCHEDULE',
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text('STATUS'),
                                                    ),
                                                    DataColumn(
                                                      label: Text('ACTIONS'),
                                                    ),
                                                  ],
                                                  rows: filteredSchedules.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    final schedule =
                                                        entry.value;
                                                    final index = entry.key;
                                                    final faculty =
                                                        facultyMap[schedule
                                                            .facultyId];
                                                    final subject =
                                                        subjectMap[schedule
                                                            .subjectId];
                                                    final room =
                                                        roomMap[schedule
                                                            .roomId];
                                                    final timeslot =
                                                        timeslotMap[schedule
                                                            .timeslotId];

                                                    final isAutoAssign =
                                                        schedule.roomId == -1 ||
                                                        schedule.timeslotId ==
                                                            -1;

                                                    return DataRow(
                                                      color: WidgetStateProperty.resolveWith<Color?>(
                                                        (states) {
                                                          if (states.contains(
                                                            WidgetState.hovered,
                                                          )) {
                                                            return maroonColor
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                );
                                                          }
                                                          return index.isEven
                                                              ? (isDark
                                                                    ? Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.02,
                                                                          )
                                                                    : Colors
                                                                          .grey
                                                                          .withValues(
                                                                            alpha:
                                                                                0.02,
                                                                          ))
                                                              : null;
                                                        },
                                                      ),
                                                      cells: [
                                                        DataCell(
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 40,
                                                                height: 40,
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      maroonColor,
                                                                      maroonColor.withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    (faculty?.name.isNotEmpty ??
                                                                            false)
                                                                        ? faculty!
                                                                              .name[0]
                                                                              .toUpperCase()
                                                                        : '?',
                                                                    style: GoogleFonts.poppins(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    faculty?.name ??
                                                                        'Unknown',
                                                                    style: GoogleFonts.poppins(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                  if (faculty
                                                                          ?.facultyId !=
                                                                      null)
                                                                    Text(
                                                                      'ID: ${faculty!.facultyId}',
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .grey[600],
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                subject?.name ??
                                                                    'Unknown',
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              if (subject
                                                                      ?.code !=
                                                                  null)
                                                                Text(
                                                                  subject!.code,
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: maroonColor
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              schedule.section,
                                                              style: GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13,
                                                                color:
                                                                    maroonColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  _getLoadTypeColor(
                                                                    schedule
                                                                        .loadTypes,
                                                                  ).withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    _getLoadTypeColor(
                                                                      schedule
                                                                          .loadTypes,
                                                                    ).withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  _getLoadTypeIcon(
                                                                    (schedule.loadTypes !=
                                                                                null &&
                                                                            schedule.loadTypes!.isNotEmpty)
                                                                        ? schedule
                                                                              .loadTypes!
                                                                              .first
                                                                        : null,
                                                                  ),
                                                                  size: 14,
                                                                  color: _getLoadTypeColor(
                                                                    schedule
                                                                        .loadTypes,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  _getLoadTypeText(
                                                                    schedule
                                                                        .loadTypes,
                                                                  ),
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: _getLoadTypeColor(
                                                                      schedule
                                                                          .loadTypes,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            schedule.units
                                                                    ?.toString() ??
                                                                'N/A',
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            schedule.hours
                                                                    ?.toString() ??
                                                                'N/A',
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .meeting_room_rounded,
                                                                    size: 16,
                                                                    color:
                                                                        isAutoAssign
                                                                        ? Colors
                                                                              .orange
                                                                        : maroonColor,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Text(
                                                                    room?.name ??
                                                                        'Waiting for AI...',
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          isAutoAssign
                                                                          ? Colors.orange
                                                                          : Colors.black87,
                                                                      fontStyle:
                                                                          isAutoAssign
                                                                          ? FontStyle.italic
                                                                          : null,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .access_time_rounded,
                                                                    size: 16,
                                                                    color:
                                                                        isAutoAssign
                                                                        ? Colors
                                                                              .orange
                                                                        : Colors
                                                                              .grey[600],
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  Text(
                                                                    timeslot !=
                                                                            null
                                                                        ? '${_getDayAbbr(timeslot.day)} ${timeslot.startTime}-${timeslot.endTime}'
                                                                        : 'Waiting for AI...',
                                                                    style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          11,
                                                                      color:
                                                                          isAutoAssign
                                                                          ? Colors.orange
                                                                          : Colors.grey[700],
                                                                      fontStyle:
                                                                          isAutoAssign
                                                                          ? FontStyle.italic
                                                                          : null,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors:
                                                                    isAutoAssign
                                                                    ? [
                                                                        Colors
                                                                            .orange,
                                                                        Colors.orange.withValues(
                                                                          alpha:
                                                                              0.7,
                                                                        ),
                                                                      ]
                                                                    : [
                                                                        Colors
                                                                            .green,
                                                                        Colors.green.withValues(
                                                                          alpha:
                                                                              0.7,
                                                                        ),
                                                                      ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color:
                                                                      (isAutoAssign
                                                                              ? Colors.orange
                                                                              : Colors.green)
                                                                          .withValues(
                                                                            alpha:
                                                                                0.3,
                                                                          ),
                                                                  blurRadius: 8,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        2,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  isAutoAssign
                                                                      ? Icons
                                                                            .pending_actions
                                                                      : Icons
                                                                            .check_circle,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Text(
                                                                  isAutoAssign
                                                                      ? 'Pending AI'
                                                                      : 'Scheduled',
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              if (!_showArchived) ...[
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _showEditAssignmentModal(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: maroonColor.withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .edit_outlined,
                                                                        color:
                                                                            maroonColor,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _archiveSchedule(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .orange
                                                                            .withValues(
                                                                              alpha: 0.1,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons
                                                                            .archive_outlined,
                                                                        color: Colors
                                                                            .orange,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ] else ...[
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _restoreSchedule(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .green
                                                                            .withValues(
                                                                              alpha: 0.1,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons
                                                                            .restore_rounded,
                                                                        color: Colors
                                                                            .green,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _permanentDeleteSchedule(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .red
                                                                            .withValues(
                                                                              alpha: 0.1,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons
                                                                            .delete_forever_rounded,
                                                                        color: Colors
                                                                            .red,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
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
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFacultySummaryView(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue<List<Room>> roomsAsync,
    AsyncValue<List<Timeslot>> timeslotsAsync,
    bool isDark,
  ) {
    final maroonColor = const Color(0xFF4f003b);

    return schedulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (schedules) => facultyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (facultyList) {
          final subjectList = subjectsAsync.maybeWhen(
            data: (d) => d,
            orElse: () => <Subject>[],
          );
          final timeslotList = timeslotsAsync.maybeWhen(
            data: (d) => d,
            orElse: () => <Timeslot>[],
          );

          final subjectMap = {for (var s in subjectList) s.id ?? -1: s};
          final timeslotMap = {for (var t in timeslotList) t.id ?? -1: t};
          final allConflicts = ref.watch(allConflictsProvider);

          // Pre-calculate stats for each faculty to avoid work in build/rows
          final List<Map<String, dynamic>> facultyStats = facultyList
              .where((f) {
                if (_searchQuery.isEmpty) return true;
                return f.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              })
              .map((faculty) {
                final assignments = schedules
                    .where((s) => s.facultyId == faculty.id)
                    .toList();

                double totalUnits = 0;
                double totalHours = 0;
                bool hasConflicts = false;

                for (var schedule in assignments) {
                  // Units from schedule or fallback to subject
                  totalUnits +=
                      schedule.units ??
                      (subjectMap[schedule.subjectId]?.units.toDouble() ?? 0.0);

                  // Hours (prefer explicit hours field, fallback to timeslot)
                  if (schedule.hours != null) {
                    totalHours += schedule.hours!;
                  } else if (schedule.timeslotId != null) {
                    final t = timeslotMap[schedule.timeslotId];
                    if (t != null) {
                      try {
                        final startParts = t.startTime.split(':');
                        final endParts = t.endTime.split(':');
                        final startMin =
                            int.parse(startParts[0]) * 60 +
                            int.parse(startParts[1]);
                        final endMin =
                            int.parse(endParts[0]) * 60 +
                            int.parse(endParts[1]);
                        totalHours += (endMin - startMin) / 60.0;
                      } catch (e) {
                        /* ignore */
                      }
                    }
                  }

                  // Conflicts check
                  final conflictsForSchedule = allConflicts.maybeWhen(
                    data: (conflicts) => conflicts
                        .where(
                          (c) =>
                              c.facultyId == faculty.id ||
                              c.conflictingScheduleId == schedule.id ||
                              c.scheduleId == schedule.id,
                        )
                        .isNotEmpty,
                    orElse: () => false,
                  );

                  if (conflictsForSchedule) hasConflicts = true;
                }

                return {
                  'faculty': faculty,
                  'assignedSubjects': assignments.length,
                  'totalUnits': totalUnits,
                  'totalHours': totalHours,
                  'hasConflicts': hasConflicts,
                  'remainingLoad': (faculty.maxLoad ?? 0) - totalHours,
                };
              })
              .toList();

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columnSpacing: 24,
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  maroonColor.withValues(alpha: 0.05),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'FACULTY NAME',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'SUBJECTS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'UNITS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'HOURS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'REMAINING',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STATUS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                rows: facultyStats.map((stats) {
                  final f = stats['faculty'] as Faculty;
                  final hasC = stats['hasConflicts'] as bool;
                  final remLoad = stats['remainingLoad'] as double;

                  return DataRow(
                    onSelectChanged: (_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FacultyLoadDetailsScreen(
                            faculty: f,
                            initialSchedules: schedules
                                .where((s) => s.facultyId == f.id)
                                .toList(),
                          ),
                        ),
                      );
                    },
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            if (hasC)
                              const Icon(
                                Icons.warning_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                            if (hasC) const SizedBox(width: 4),
                            Text(
                              f.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          stats['assignedSubjects'].toString(),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      DataCell(
                        Text(
                          stats['totalUnits'].toString(),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${(stats['totalHours'] as double).toStringAsFixed(1)}h',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: remLoad < 0
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            remLoad.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              color: remLoad < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        hasC
                            ? const Icon(Icons.error_outline, color: Colors.red)
                            : const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLoadTypeColor(List<SubjectType>? types) {
    if (types == null || types.isEmpty) return Colors.grey;
    if (types.contains(SubjectType.lecture) &&
        types.contains(SubjectType.laboratory))
      return Colors.orange;
    if (types.contains(SubjectType.lecture)) return Colors.purple;
    if (types.contains(SubjectType.laboratory)) return Colors.teal;
    return Colors.blue;
  }

  String _getLoadTypeText(List<SubjectType>? types) {
    if (types == null || types.isEmpty) return 'N/A';
    return types.map((t) => t.name.toUpperCase()).join(' / ');
  }

  IconData _getLoadTypeIcon(SubjectType? type) {
    if (type == null) return Icons.help_outline;
    switch (type) {
      case SubjectType.lecture:
        return Icons.menu_book;
      case SubjectType.laboratory:
        return Icons.science;
      case SubjectType.blended:
        return Icons.layers_outlined;
    }
  }

  String _getDayAbbr(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Mon';
      case DayOfWeek.tue:
        return 'Tue';
      case DayOfWeek.wed:
        return 'Wed';
      case DayOfWeek.thu:
        return 'Thu';
      case DayOfWeek.fri:
        return 'Fri';
      case DayOfWeek.sat:
        return 'Sat';
      case DayOfWeek.sun:
        return 'Sun';
    }
  }

  Widget _buildConflictBanner(
    AsyncValue<List<ScheduleConflict>> conflictsAsync,
  ) {
    return conflictsAsync.when(
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
      data: (conflicts) {
        final hasConflicts = conflicts.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: hasConflicts ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: hasConflicts ? Colors.red : Colors.green,
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (hasConflicts ? Colors.red : Colors.green).withValues(
                  alpha: 0.1,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: hasConflicts
                    ? () {
                        setState(() {
                          _showConflictDetails = !_showConflictDetails;
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasConflicts
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          hasConflicts
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          color: hasConflicts ? Colors.red : Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasConflicts
                                  ? 'Schedule Conflicts Detected'
                                  : 'No Conflicts Detected',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: hasConflicts
                                    ? Colors.red[900]
                                    : Colors.green[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasConflicts
                                  ? '${conflicts.length} conflict(s) found. Click to view details.'
                                  : 'All faculty schedules are properly assigned without conflicts.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: hasConflicts
                                    ? Colors.red[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasConflicts)
                        Icon(
                          _showConflictDetails
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.red[700],
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),
              if (hasConflicts && _showConflictDetails)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Conflict Details:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...conflicts.take(5).map((conflict) {
                        final isWarning =
                            conflict.type == 'capacity_exceeded' ||
                            conflict.type == 'program_mismatch' ||
                            conflict.type == 'faculty_unavailable';
                        final color = isWarning ? Colors.orange : Colors.red;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isWarning
                                      ? Icons.info_outline
                                      : Icons.error_outline,
                                  size: 18,
                                  color: color[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              conflict.type
                                                  .toUpperCase()
                                                  .replaceAll('_', ' '),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isWarning ? 'WARNING' : 'CRITICAL',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: color[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        conflict.message,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      if (conflict.details != null &&
                                          conflict.details!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          conflict.details!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (conflicts.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... and ${conflicts.length - 5} more conflicts',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
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
    );
  }
}

// New Assignment Modal
class _NewAssignmentModal extends ConsumerStatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _NewAssignmentModal({
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  ConsumerState<_NewAssignmentModal> createState() =>
      _NewAssignmentModalState();
}

class _NewAssignmentModalState extends ConsumerState<_NewAssignmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _hoursController = TextEditingController();

  int? _selectedFacultyId;
  int? _selectedSubjectId;
  int? _selectedRoomId;
  int? _selectedTimeslotId;
  int? _selectedSectionId;
  String? _selectedSectionCode;
  final List<SubjectType> _selectedLoadTypes = [];
  bool _isAutoAssign = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _unitsController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schedule = Schedule(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        roomId: _isAutoAssign ? null : _selectedRoomId,
        timeslotId: _isAutoAssign ? null : _selectedTimeslotId,
        section: _selectedSectionCode ?? '',
        sectionId: _selectedSectionId,
        loadTypes: _selectedLoadTypes,
        units: double.tryParse(_unitsController.text),
        hours: double.tryParse(_hoursController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await client.admin.createSchedule(schedule);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomListProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final sectionsAsync = ref.watch(sectionListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.maroonColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_add,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Schedule Assignment',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Faculty Dropdown
                      facultyAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading faculty'),
                        data: (facultyList) => _buildDropdown<int>(
                          label: 'Faculty',
                          value: _selectedFacultyId,
                          items: facultyList.map((f) => f.id!).toList(),
                          itemLabel: (id) =>
                              facultyList.firstWhere((f) => f.id == id).name,
                          onChanged: (value) =>
                              setState(() => _selectedFacultyId = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subject Dropdown
                      subjectsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading subjects'),
                        data: (subjectList) => _buildDropdown<int>(
                          label: 'Subject',
                          value: _selectedSubjectId,
                          items: subjectList.map((s) => s.id!).toList(),
                          itemLabel: (id) =>
                              subjectList.firstWhere((s) => s.id == id).name,
                          onChanged: (value) =>
                              setState(() => _selectedSubjectId = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Dropdown
                      sectionsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading sections'),
                        data: (sectionList) => _buildDropdown<int>(
                          label: 'Section',
                          value: _selectedSectionId,
                          items: sectionList.map((s) => s.id!).toList(),
                          itemLabel: (id) {
                            final s = sectionList.firstWhere((s) => s.id == id);
                            return '${s.program.name.toUpperCase()} ${s.yearLevel}-${s.sectionCode}';
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedSectionId = value;
                              _selectedSectionCode = sectionList
                                  .firstWhere((s) => s.id == value)
                                  .sectionCode;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Load Type
                      // Load Types
                      Text(
                        'Subject Types',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: SubjectType.values.map((type) {
                          final isSelected = _selectedLoadTypes.contains(type);
                          return FilterChip(
                            label: Text(type.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedLoadTypes.add(type);
                                  if (_hoursController.text.isEmpty) {
                                    if (type == SubjectType.lecture) {
                                      _hoursController.text = '2';
                                    } else if (type == SubjectType.laboratory) {
                                      _hoursController.text = '3';
                                    }
                                  }
                                } else {
                                  _selectedLoadTypes.remove(type);
                                }
                              });
                            },
                            selectedColor: widget.maroonColor.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: widget.maroonColor,
                            labelStyle: GoogleFonts.poppins(
                              color: isSelected
                                  ? widget.maroonColor
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Units
                      _buildTextField(
                        controller: _unitsController,
                        label: 'Units',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Hours
                      _buildTextField(
                        controller: _hoursController,
                        label: 'Hours',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Auto-Assign Checkbox
                      CheckboxListTile(
                        value: _isAutoAssign,
                        onChanged: (value) {
                          setState(() {
                            _isAutoAssign = value ?? false;
                            if (_isAutoAssign) {
                              _selectedRoomId = null;
                              _selectedTimeslotId = null;
                            }
                          });
                        },
                        title: Text(
                          'Auto-Assign Room & Timeslot',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Let the system automatically assign room and time',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        activeColor: widget.maroonColor,
                      ),
                      const SizedBox(height: 16),

                      // Room & Timeslot (if not auto-assign)
                      if (!_isAutoAssign) ...[
                        roomsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Error loading rooms'),
                          data: (roomList) => _buildDropdown<int>(
                            label: 'Room',
                            value: _selectedRoomId,
                            items: roomList.map((r) => r.id!).toList(),
                            itemLabel: (id) =>
                                roomList.firstWhere((r) => r.id == id).name,
                            onChanged: (value) =>
                                setState(() => _selectedRoomId = value),
                          ),
                        ),
                        const SizedBox(height: 16),
                        timeslotsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Error loading timeslots'),
                          data: (timeslotList) => _buildDropdown<int>(
                            label: 'Timeslot',
                            value: _selectedTimeslotId,
                            items: timeslotList.map((t) => t.id!).toList(),
                            itemLabel: (id) {
                              final t = timeslotList.firstWhere(
                                (t) => t.id == id,
                              );
                              return CITESchedDateUtils.formatTimeslot(
                                t.day,
                                t.startTime,
                                t.endTime,
                              );
                            },
                            onChanged: (value) =>
                                setState(() => _selectedTimeslotId = value),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Create Assignment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: widget.maroonColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.black87),
    );
  }
}

// Edit Assignment Modal (similar structure to New Assignment)
class _EditAssignmentModal extends ConsumerStatefulWidget {
  final Schedule schedule;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditAssignmentModal({
    required this.schedule,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  ConsumerState<_EditAssignmentModal> createState() =>
      _EditAssignmentModalState();
}

class _EditAssignmentModalState extends ConsumerState<_EditAssignmentModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unitsController;
  late TextEditingController _hoursController;

  late int _selectedFacultyId;
  late int _selectedSubjectId;
  int? _selectedRoomId;
  int? _selectedTimeslotId;
  int? _selectedSectionId;
  String? _selectedSectionCode;
  List<SubjectType> _selectedLoadTypes = [];
  bool _isAutoAssign = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSectionId = widget.schedule.sectionId;
    _selectedSectionCode = widget.schedule.section;
    _unitsController = TextEditingController(
      text: widget.schedule.units?.toString() ?? '',
    );
    _hoursController = TextEditingController(
      text: widget.schedule.hours?.toString() ?? '',
    );
    _selectedFacultyId = widget.schedule.facultyId;
    _selectedSubjectId = widget.schedule.subjectId;
    _selectedRoomId = widget.schedule.roomId == -1
        ? null
        : widget.schedule.roomId;
    _selectedTimeslotId = widget.schedule.timeslotId == -1
        ? null
        : widget.schedule.timeslotId;
    _selectedLoadTypes = List.from(widget.schedule.loadTypes ?? []);
    _isAutoAssign =
        widget.schedule.roomId == -1 || widget.schedule.timeslotId == -1;
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedSchedule = Schedule(
        id: widget.schedule.id,
        facultyId: _selectedFacultyId,
        subjectId: _selectedSubjectId,
        roomId: _isAutoAssign ? null : _selectedRoomId,
        timeslotId: _isAutoAssign ? null : _selectedTimeslotId,
        section: _selectedSectionCode ?? '',
        sectionId: _selectedSectionId,
        loadTypes: _selectedLoadTypes,
        units: double.tryParse(_unitsController.text),
        hours: double.tryParse(_hoursController.text),
        createdAt: widget.schedule.createdAt,
        updatedAt: DateTime.now(),
      );

      await client.admin.updateSchedule(updatedSchedule);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomListProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final sectionsAsync = ref.watch(sectionListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.maroonColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Schedule Assignment',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form (same structure as New Assignment)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Faculty Dropdown
                      facultyAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading faculty'),
                        data: (facultyList) => _buildDropdown<int>(
                          label: 'Faculty',
                          value: _selectedFacultyId,
                          items: facultyList.map((f) => f.id!).toList(),
                          itemLabel: (id) =>
                              facultyList.firstWhere((f) => f.id == id).name,
                          onChanged: (value) =>
                              setState(() => _selectedFacultyId = value!),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subject Dropdown
                      subjectsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading subjects'),
                        data: (subjectList) => _buildDropdown<int>(
                          label: 'Subject',
                          value: _selectedSubjectId,
                          items: subjectList.map((s) => s.id!).toList(),
                          itemLabel: (id) =>
                              subjectList.firstWhere((s) => s.id == id).name,
                          onChanged: (value) =>
                              setState(() => _selectedSubjectId = value!),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section Dropdown
                      sectionsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading sections'),
                        data: (sectionList) => _buildDropdown<int>(
                          label: 'Section',
                          // If current ID is not in the list, Fallback to null forcing selection
                          value:
                              sectionList.any((s) => s.id == _selectedSectionId)
                              ? _selectedSectionId
                              : null,
                          items: sectionList.map((s) => s.id!).toList(),
                          itemLabel: (id) {
                            final s = sectionList.firstWhere((s) => s.id == id);
                            return '${s.program.name.toUpperCase()} ${s.yearLevel}-${s.sectionCode}';
                          },
                          onChanged: (value) {
                            setState(() {
                              _selectedSectionId = value;
                              _selectedSectionCode = sectionList
                                  .firstWhere((s) => s.id == value)
                                  .sectionCode;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Load Type
                      // Load Types
                      Text(
                        'Subject Types',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: SubjectType.values.map((type) {
                          final isSelected = _selectedLoadTypes.contains(type);
                          return FilterChip(
                            label: Text(type.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedLoadTypes.add(type);
                                } else {
                                  _selectedLoadTypes.remove(type);
                                }
                              });
                            },
                            selectedColor: widget.maroonColor.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: widget.maroonColor,
                            labelStyle: GoogleFonts.poppins(
                              color: isSelected
                                  ? widget.maroonColor
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Units
                      _buildTextField(
                        controller: _unitsController,
                        label: 'Units',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Hours
                      _buildTextField(
                        controller: _hoursController,
                        label: 'Hours',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Auto-Assign Checkbox
                      CheckboxListTile(
                        value: _isAutoAssign,
                        onChanged: (value) {
                          setState(() {
                            _isAutoAssign = value ?? false;
                            if (_isAutoAssign) {
                              _selectedRoomId = null;
                              _selectedTimeslotId = null;
                            }
                          });
                        },
                        title: Text(
                          'Auto-Assign Room & Timeslot',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Let the system automatically assign room and time',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        activeColor: widget.maroonColor,
                      ),
                      const SizedBox(height: 16),

                      // Room & Timeslot (if not auto-assign)
                      if (!_isAutoAssign) ...[
                        roomsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Error loading rooms'),
                          data: (roomList) => _buildDropdown<int>(
                            label: 'Room',
                            value: _selectedRoomId,
                            items: roomList.map((r) => r.id!).toList(),
                            itemLabel: (id) =>
                                roomList.firstWhere((r) => r.id == id).name,
                            onChanged: (value) =>
                                setState(() => _selectedRoomId = value),
                          ),
                        ),
                        const SizedBox(height: 16),
                        timeslotsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Error loading timeslots'),
                          data: (timeslotList) => _buildDropdown<int>(
                            label: 'Timeslot',
                            value: _selectedTimeslotId,
                            items: timeslotList.map((t) => t.id!).toList(),
                            itemLabel: (id) {
                              final t = timeslotList.firstWhere(
                                (t) => t.id == id,
                              );
                              return CITESchedDateUtils.formatTimeslot(
                                t.day,
                                t.startTime,
                                t.endTime,
                              );
                            },
                            onChanged: (value) =>
                                setState(() => _selectedTimeslotId = value),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: widget.maroonColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.black87),
    );
  }
}
