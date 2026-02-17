import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Providers
final schedulesProvider = FutureProvider<List<Schedule>>((ref) async {
  return await client.admin.getAllSchedules();
});

final facultyListProvider = FutureProvider<List<Faculty>>((ref) async {
  return await client.admin.getAllFaculty();
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return await client.admin.getAllSubjects();
});

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  return await client.admin.getAllRooms();
});

final timeslotsProvider = FutureProvider<List<Timeslot>>((ref) async {
  return await client.admin.getAllTimeslots();
});

class FacultyLoadingScreen extends ConsumerStatefulWidget {
  const FacultyLoadingScreen({super.key});

  @override
  ConsumerState<FacultyLoadingScreen> createState() =>
      _FacultyLoadingScreenState();
}

class _FacultyLoadingScreenState extends ConsumerState<FacultyLoadingScreen> {
  String _searchQuery = '';
  String? _selectedFaculty;
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
          ref.refresh(schedulesProvider);
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
          ref.refresh(schedulesProvider);
        },
      ),
    );
  }

  void _deleteSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this schedule assignment?',
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
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await client.admin.deleteSchedule(schedule.id!);
        ref.refresh(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment deleted successfully'),
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

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Loading',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage faculty schedule assignments and workload',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showNewAssignmentModal,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'New Assignment',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Conflict Warning Banner
            _buildConflictBanner(schedulesAsync, facultyAsync),
            const SizedBox(height: 20),

            // Search and Filter Row
            Row(
              children: [
                // Search Bar
                // Search Bar
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.transparent : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B).withOpacity(0.03),
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
                            // FIX: Cursor matches text color
                            cursorColor: isDark ? Colors.white : Colors.black87,
                            // FIX: Text color adapts to theme
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              // FIX: Remove internal background color
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText:
                                  'Search by faculty, subject, or section...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              // FIX: Remove all default borders
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
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

                // Faculty Filter
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color.fromRGBO(30, 41, 59, 1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1E293B).withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: facultyAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (facultyList) {
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFaculty,
                            hint: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: maroonColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filter by Faculty',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Faculty',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              ...facultyList.map((faculty) {
                                return DropdownMenuItem<String>(
                                  value: faculty.id.toString(),
                                  child: Text(
                                    faculty.name,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFaculty = value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Schedule Table
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
                        onPressed: () => ref.refresh(schedulesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (schedules) {
                  return facultyAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error')),
                    data: (facultyList) {
                      return subjectsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(child: Text('Error')),
                        data: (subjectList) {
                          return roomsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) =>
                                const Center(child: Text('Error')),
                            data: (roomList) {
                              return timeslotsAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, __) =>
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

                                  // Filter schedules
                                  final filteredSchedules = schedules.where((
                                    schedule,
                                  ) {
                                    // Search filter
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
                                              (subject?.name
                                                      .toLowerCase()
                                                      .contains(
                                                        _searchQuery,
                                                      ) ??
                                                  false) ||
                                              schedule.section
                                                  .toLowerCase()
                                                  .contains(
                                                    _searchQuery,
                                                  );
                                        }();

                                    // Faculty filter
                                    final matchesFaculty =
                                        _selectedFaculty == null ||
                                        schedule.facultyId.toString() ==
                                            _selectedFaculty;

                                    return matchesSearch && matchesFaculty;
                                  }).toList();

                                  if (filteredSchedules.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                      border: Border(
                                        left: BorderSide(
                                          color: maroonColor,
                                          width: 4,
                                        ),
                                      ),
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
                                        // Table Header
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: maroonColor.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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

                                        // Table Content
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SingleChildScrollView(
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
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
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
                                                    label: Text('TYPE'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('UNITS'),
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
                                                  final schedule = entry.value;
                                                  final index = entry.key;
                                                  final faculty =
                                                      facultyMap[schedule
                                                          .facultyId];
                                                  final subject =
                                                      subjectMap[schedule
                                                          .subjectId];
                                                  final room =
                                                      roomMap[schedule.roomId];
                                                  final timeslot =
                                                      timeslotMap[schedule
                                                          .timeslotId];

                                                  final isAutoAssign =
                                                      schedule.roomId == -1 ||
                                                      schedule.timeslotId == -1;

                                                  return DataRow(
                                                    color: WidgetStateProperty.resolveWith<Color?>(
                                                      (states) {
                                                        if (states.contains(
                                                          WidgetState.hovered,
                                                        )) {
                                                          return maroonColor
                                                              .withOpacity(
                                                                0.05,
                                                              );
                                                        }
                                                        return index.isEven
                                                            ? (isDark
                                                                  ? Colors.white
                                                                        .withOpacity(
                                                                          0.02,
                                                                        )
                                                                  : Colors.grey
                                                                        .withOpacity(
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
                                                                    maroonColor
                                                                        .withOpacity(
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
                                                            if (subject?.code !=
                                                                null)
                                                              Text(
                                                                subject!.code!,
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 11,
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
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: maroonColor
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            schedule.section,
                                                            style:
                                                                GoogleFonts.poppins(
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
                                                                horizontal: 12,
                                                                vertical: 7,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                _getLoadTypeColor(
                                                                  schedule
                                                                      .loadType,
                                                                ),
                                                                _getLoadTypeColor(
                                                                  schedule
                                                                      .loadType,
                                                                ).withOpacity(
                                                                  0.7,
                                                                ),
                                                              ],
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: _getLoadTypeColor(
                                                                  schedule
                                                                      .loadType,
                                                                ).withOpacity(0.3),
                                                                blurRadius: 6,
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
                                                                _getLoadTypeIcon(
                                                                  schedule
                                                                      .loadType,
                                                                ),
                                                                size: 13,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                _getLoadTypeText(
                                                                  schedule
                                                                      .loadType,
                                                                ),
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 12,
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
                                                          children: [
                                                            Icon(
                                                              Icons.school,
                                                              size: 16,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              schedule.units
                                                                      ?.toString() ??
                                                                  'N/A',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
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
                                                                        ? Colors
                                                                              .orange
                                                                        : Colors
                                                                              .black87,
                                                                    fontStyle:
                                                                        isAutoAssign
                                                                        ? FontStyle
                                                                              .italic
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
                                                                        ? Colors
                                                                              .orange
                                                                        : Colors
                                                                              .grey[700],
                                                                    fontStyle:
                                                                        isAutoAssign
                                                                        ? FontStyle
                                                                              .italic
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
                                                                horizontal: 14,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors:
                                                                  isAutoAssign
                                                                  ? [
                                                                      Colors
                                                                          .orange,
                                                                      Colors
                                                                          .orange
                                                                          .withOpacity(
                                                                            0.7,
                                                                          ),
                                                                    ]
                                                                  : [
                                                                      Colors
                                                                          .green,
                                                                      Colors
                                                                          .green
                                                                          .withOpacity(
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
                                                                        .withOpacity(
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
                                                                  fontSize: 12,
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
                                                              MainAxisSize.min,
                                                          children: [
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
                                                                    color: maroonColor
                                                                        .withOpacity(
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
                                                                    size: 18,
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
                                                                    _deleteSchedule(
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
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 18,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
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
        ),
      ),
    );
  }

  Color _getLoadTypeColor(SubjectType? type) {
    if (type == null) return Colors.grey;
    switch (type) {
      case SubjectType.lecture:
        return Colors.purple;
      case SubjectType.laboratory:
        return Colors.teal;
    }
  }

  String _getLoadTypeText(SubjectType? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case SubjectType.lecture:
        return 'Lecture';
      case SubjectType.laboratory:
        return 'Lab';
    }
  }

  IconData _getLoadTypeIcon(SubjectType? type) {
    if (type == null) return Icons.help_outline;
    switch (type) {
      case SubjectType.lecture:
        return Icons.menu_book;
      case SubjectType.laboratory:
        return Icons.science;
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
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
  ) {
    return schedulesAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (schedules) {
        // Simple conflict detection - check for duplicate timeslots
        final conflicts = <String>[];
        for (var i = 0; i < schedules.length; i++) {
          for (var j = i + 1; j < schedules.length; j++) {
            if (schedules[i].facultyId == schedules[j].facultyId &&
                schedules[i].timeslotId == schedules[j].timeslotId &&
                schedules[i].timeslotId != -1) {
              conflicts.add(
                'Faculty ${schedules[i].facultyId} has overlapping schedules',
              );
            }
          }
        }

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
                color: (hasConflicts ? Colors.red : Colors.green).withOpacity(
                  0.1,
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
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  conflict,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
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
  final _sectionController = TextEditingController();
  final _unitsController = TextEditingController();

  int? _selectedFacultyId;
  int? _selectedSubjectId;
  int? _selectedRoomId;
  int? _selectedTimeslotId;
  SubjectType? _loadType;
  bool _isAutoAssign = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _sectionController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schedule = Schedule(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        roomId: _isAutoAssign ? -1 : (_selectedRoomId ?? -1),
        timeslotId: _isAutoAssign ? -1 : (_selectedTimeslotId ?? -1),
        section: _sectionController.text.trim(),
        loadType: _loadType,
        units: double.tryParse(_unitsController.text),
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
    final roomsAsync = ref.watch(roomsProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);

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
                        error: (_, __) => const Text('Error loading faculty'),
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
                        error: (_, __) => const Text('Error loading subjects'),
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

                      // Section
                      _buildTextField(
                        controller: _sectionController,
                        label: 'Section',
                        icon: Icons.class_,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Load Type
                      _buildDropdown<SubjectType>(
                        label: 'Load Type',
                        value: _loadType,
                        items: SubjectType.values,
                        itemLabel: (type) {
                          switch (type) {
                            case SubjectType.lecture:
                              return 'Lecture';
                            case SubjectType.laboratory:
                              return 'Laboratory';
                          }
                        },
                        onChanged: (value) => setState(() => _loadType = value),
                      ),
                      const SizedBox(height: 16),

                      // Units
                      _buildTextField(
                        controller: _unitsController,
                        label: 'Units',
                        icon: Icons.numbers,
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
                          error: (_, __) => const Text('Error loading rooms'),
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
                          error: (_, __) =>
                              const Text('Error loading timeslots'),
                          data: (timeslotList) => _buildDropdown<int>(
                            label: 'Timeslot',
                            value: _selectedTimeslotId,
                            items: timeslotList.map((t) => t.id!).toList(),
                            itemLabel: (id) {
                              final t = timeslotList.firstWhere(
                                (t) => t.id == id,
                              );
                              return '${_getDayName(t.day)} ${t.startTime}-${t.endTime}';
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
      value: value,
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

  String _getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Monday';
      case DayOfWeek.tue:
        return 'Tuesday';
      case DayOfWeek.wed:
        return 'Wednesday';
      case DayOfWeek.thu:
        return 'Thursday';
      case DayOfWeek.fri:
        return 'Friday';
      case DayOfWeek.sat:
        return 'Saturday';
      case DayOfWeek.sun:
        return 'Sunday';
    }
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
  late TextEditingController _sectionController;
  late TextEditingController _unitsController;

  late int _selectedFacultyId;
  late int _selectedSubjectId;
  int? _selectedRoomId;
  int? _selectedTimeslotId;
  SubjectType? _loadType;
  bool _isAutoAssign = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sectionController = TextEditingController(text: widget.schedule.section);
    _unitsController = TextEditingController(
      text: widget.schedule.units?.toString() ?? '',
    );
    _selectedFacultyId = widget.schedule.facultyId;
    _selectedSubjectId = widget.schedule.subjectId;
    _selectedRoomId = widget.schedule.roomId == -1
        ? null
        : widget.schedule.roomId;
    _selectedTimeslotId = widget.schedule.timeslotId == -1
        ? null
        : widget.schedule.timeslotId;
    _loadType = widget.schedule.loadType;
    _isAutoAssign =
        widget.schedule.roomId == -1 || widget.schedule.timeslotId == -1;
  }

  @override
  void dispose() {
    _sectionController.dispose();
    _unitsController.dispose();
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
        roomId: _isAutoAssign ? -1 : (_selectedRoomId ?? -1),
        timeslotId: _isAutoAssign ? -1 : (_selectedTimeslotId ?? -1),
        section: _sectionController.text.trim(),
        loadType: _loadType,
        units: double.tryParse(_unitsController.text),
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
    final roomsAsync = ref.watch(roomsProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);

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
                        error: (_, __) => const Text('Error loading faculty'),
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
                        error: (_, __) => const Text('Error loading subjects'),
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

                      // Section
                      _buildTextField(
                        controller: _sectionController,
                        label: 'Section',
                        icon: Icons.class_,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Load Type
                      _buildDropdown<SubjectType>(
                        label: 'Load Type',
                        value: _loadType,
                        items: SubjectType.values,
                        itemLabel: (type) {
                          switch (type) {
                            case SubjectType.lecture:
                              return 'Lecture';
                            case SubjectType.laboratory:
                              return 'Laboratory';
                          }
                        },
                        onChanged: (value) => setState(() => _loadType = value),
                      ),
                      const SizedBox(height: 16),

                      // Units
                      _buildTextField(
                        controller: _unitsController,
                        label: 'Units',
                        icon: Icons.numbers,
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
                          error: (_, __) => const Text('Error loading rooms'),
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
                          error: (_, __) =>
                              const Text('Error loading timeslots'),
                          data: (timeslotList) => _buildDropdown<int>(
                            label: 'Timeslot',
                            value: _selectedTimeslotId,
                            items: timeslotList.map((t) => t.id!).toList(),
                            itemLabel: (id) {
                              final t = timeslotList.firstWhere(
                                (t) => t.id == id,
                              );
                              return '${_getDayName(t.day)} ${t.startTime}-${t.endTime}';
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
      value: value,
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

  String _getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Monday';
      case DayOfWeek.tue:
        return 'Tuesday';
      case DayOfWeek.wed:
        return 'Wednesday';
      case DayOfWeek.thu:
        return 'Thursday';
      case DayOfWeek.fri:
        return 'Friday';
      case DayOfWeek.sat:
        return 'Saturday';
      case DayOfWeek.sun:
        return 'Sunday';
    }
  }
}
