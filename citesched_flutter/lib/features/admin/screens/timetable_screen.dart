import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  String _searchQuery = '';
  DayOfWeek? _selectedDay;
  String? _selectedSection;
  final TextEditingController _searchController = TextEditingController();

  final Color maroonColor = const Color(0xFF720045);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _generateSchedule() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch all necessary data for generation
      final subjects = await client.admin.getAllSubjects();
      final faculty = await client.admin.getAllFaculty();
      final rooms = await client.admin.getAllRooms();
      final timeslots = await client.admin.getAllTimeslots();

      final request = GenerateScheduleRequest(
        subjectIds: subjects.map((s) => s.id!).toList(),
        facultyIds: faculty.map((f) => f.id!).toList(),
        roomIds: rooms.map((r) => r.id!).toList(),
        timeslotIds: timeslots.map((t) => t.id!).toList(),
        sections: ['A', 'B', 'C'], // Default sections for now
      );

      final response = await client.admin.generateSchedule(request);

      if (mounted) Navigator.pop(context); // Close loading

      if (response.success) {
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Schedule generated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Schedule Generation Conflicts'),
              content: SizedBox(
                width: 400,
                height: 300,
                child: ListView.builder(
                  itemCount: response.conflicts?.length ?? 0,
                  itemBuilder: (context, index) {
                    final conflict = response.conflicts![index];
                    return ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: Text(conflict.message),
                      subtitle: Text(conflict.details ?? ''),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);
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
                      'Timetable',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'CONFLICT-FREE',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI-optimized schedule for CITE department',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _generateSchedule,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    'AI GENERATE',
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

            // Conflict Summary Banner (Matching Faculty pattern)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: maroonColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: maroonColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: maroonColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-POWERED SCHEDULING',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: maroonColor,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate conflict-free schedules for department rooms, respecting subject requirements, room capacities, and faculty workloads.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Filters
            // Search and Filter Row
            Row(
              children: [
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
                          color: const Color.fromRGBO(30, 41, 59, 1)
                              .withOpacity(
                                0.03,
                              ),
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
                            onChanged: (value) => setState(
                              () => _searchQuery = value.toLowerCase(),
                            ),
                            cursorColor: isDark ? Colors.white : Colors.black87,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Search by faculty or subject...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
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
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildDayFilter(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildSectionFilter(isDark),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Timetable Table
            Expanded(
              child: schedulesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (schedules) {
                  return ref
                      .watch(facultyListProvider)
                      .when(
                        data: (faculty) {
                          return ref
                              .watch(subjectsProvider)
                              .when(
                                data: (subjects) {
                                  return ref
                                      .watch(roomsProvider)
                                      .when(
                                        data: (rooms) {
                                          return ref
                                              .watch(timeslotsProvider)
                                              .when(
                                                data: (timeslots) {
                                                  final facultyMap = {
                                                    for (var f in faculty)
                                                      f.id!: f,
                                                  };
                                                  final subjectMap = {
                                                    for (var s in subjects)
                                                      s.id!: s,
                                                  };
                                                  final roomMap = {
                                                    for (var r in rooms)
                                                      r.id!: r,
                                                  };
                                                  final timeslotMap = {
                                                    for (var t in timeslots)
                                                      t.id!: t,
                                                  };

                                                  final filtered = schedules.where((
                                                    s,
                                                  ) {
                                                    final f =
                                                        facultyMap[s.facultyId];
                                                    final sub =
                                                        subjectMap[s.subjectId];
                                                    final t =
                                                        timeslotMap[s
                                                            .timeslotId];

                                                    final matchesSearch =
                                                        (f?.name
                                                                .toLowerCase()
                                                                .contains(
                                                                  _searchQuery,
                                                                ) ??
                                                            false) ||
                                                        (sub?.name
                                                                .toLowerCase()
                                                                .contains(
                                                                  _searchQuery,
                                                                ) ??
                                                            false);
                                                    final matchesDay =
                                                        _selectedDay == null ||
                                                        t?.day == _selectedDay;
                                                    final matchesSection =
                                                        _selectedSection ==
                                                            null ||
                                                        s.section ==
                                                            _selectedSection;

                                                    return matchesSearch &&
                                                        matchesDay &&
                                                        matchesSection;
                                                  }).toList();

                                                  if (filtered.isEmpty) {
                                                    return const Center(
                                                      child: Text(
                                                        'No schedule entries found',
                                                      ),
                                                    );
                                                  }

                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? const Color(
                                                              0xFF1E293B,
                                                            )
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: Border(
                                                        left: BorderSide(
                                                          color: maroonColor,
                                                          width: 4,
                                                        ),
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.08,
                                                              ),
                                                          blurRadius: 16,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        // Table Header
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 24,
                                                                vertical: 16,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: maroonColor
                                                                .withOpacity(
                                                                  0.05,
                                                                ),
                                                            borderRadius:
                                                                const BorderRadius.only(
                                                                  topLeft:
                                                                      Radius.circular(
                                                                        16,
                                                                      ),
                                                                  topRight:
                                                                      Radius.circular(
                                                                        16,
                                                                      ),
                                                                ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .calendar_month_rounded,
                                                                color:
                                                                    maroonColor,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Department Timetable',
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      maroonColor,
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      maroonColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  '${filtered.length} Entries',
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
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: SingleChildScrollView(
                                                              child: DataTable(
                                                                headingRowColor:
                                                                    WidgetStateProperty.all(
                                                                      maroonColor,
                                                                    ),
                                                                headingTextStyle: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                  letterSpacing:
                                                                      0.5,
                                                                ),
                                                                dataRowMinHeight:
                                                                    70,
                                                                dataRowMaxHeight:
                                                                    90,
                                                                columnSpacing:
                                                                    28,
                                                                horizontalMargin:
                                                                    24,
                                                                decoration:
                                                                    const BoxDecoration(
                                                                      color: Colors
                                                                          .transparent,
                                                                    ),
                                                                columns: const [
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'TIME',
                                                                    ),
                                                                  ),
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'DAY',
                                                                    ),
                                                                  ),
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'SUBJECT',
                                                                    ),
                                                                  ),
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'FACULTY',
                                                                    ),
                                                                  ),
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'ROOM',
                                                                    ),
                                                                  ),
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'SECTION',
                                                                    ),
                                                                  ),
                                                                  DataColumn(
                                                                    label: Text(
                                                                      'PROGRAM',
                                                                    ),
                                                                  ),
                                                                ],
                                                                rows: filtered.asMap().entries.map((
                                                                  entry,
                                                                ) {
                                                                  final s = entry
                                                                      .value;
                                                                  final index =
                                                                      entry.key;
                                                                  final f =
                                                                      facultyMap[s
                                                                          .facultyId];
                                                                  final sub =
                                                                      subjectMap[s
                                                                          .subjectId];
                                                                  final r =
                                                                      roomMap[s
                                                                          .roomId];
                                                                  final timeslot =
                                                                      timeslotMap[s
                                                                          .timeslotId];

                                                                  return DataRow(
                                                                    color: WidgetStateProperty.resolveWith<Color?>(
                                                                      (states) {
                                                                        if (states.contains(
                                                                          WidgetState
                                                                              .hovered,
                                                                        )) {
                                                                          return maroonColor.withOpacity(
                                                                            0.05,
                                                                          );
                                                                        }
                                                                        return index.isEven
                                                                            ? (isDark
                                                                                  ? Colors.white.withOpacity(
                                                                                      0.02,
                                                                                    )
                                                                                  : Colors.grey.withOpacity(
                                                                                      0.02,
                                                                                    ))
                                                                            : null;
                                                                      },
                                                                    ),
                                                                    cells: [
                                                                      DataCell(
                                                                        Text(
                                                                          timeslot !=
                                                                                  null
                                                                              ? '${timeslot.startTime} - ${timeslot.endTime}'
                                                                              : 'TBA',
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        Text(
                                                                          timeslot?.day.name.toUpperCase() ??
                                                                              'TBA',
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        Text(
                                                                          sub?.name ??
                                                                              'TBA',
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        Text(
                                                                          f?.name ??
                                                                              'TBA',
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        Text(
                                                                          r?.name ??
                                                                              'TBA',
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        Text(
                                                                          s.section,
                                                                        ),
                                                                      ),
                                                                      DataCell(
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                8,
                                                                            vertical:
                                                                                4,
                                                                          ),
                                                                          decoration: BoxDecoration(
                                                                            color: maroonColor.withOpacity(
                                                                              0.1,
                                                                            ),
                                                                            borderRadius: BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                            sub?.program.name.toUpperCase() ??
                                                                                '-',
                                                                            style: TextStyle(
                                                                              color: maroonColor,
                                                                              fontSize: 11,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
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
                                                loading: () => const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                error: (e, s) =>
                                                    Text('Error: $e'),
                                              );
                                        },
                                        loading: () => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        error: (e, s) => Text('Error: $e'),
                                      );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, s) => Text('Error: $e'),
                              );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Error: $e'),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DayOfWeek>(
          value: _selectedDay,
          hint: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Day',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All Days',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...DayOfWeek.values.map(
              (d) => DropdownMenuItem(
                value: d,
                child: Text(
                  d.name.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedDay = v),
        ),
      ),
    );
  }

  Widget _buildSectionFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSection,
          hint: Row(
            children: [
              Icon(Icons.group_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Section',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All Sections',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...['A', 'B', 'C'].map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(
                  'Section $s',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedSection = v),
        ),
      ),
    );
  }
}
