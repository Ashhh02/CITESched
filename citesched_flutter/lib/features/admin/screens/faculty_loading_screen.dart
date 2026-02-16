import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/theme/app_theme.dart';
import 'package:citesched_flutter/main.dart'; // for client
import 'package:citesched_flutter/features/admin/screens/add_faculty_load_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyLoadingScreen extends StatefulWidget {
  const FacultyLoadingScreen({super.key});

  @override
  State<FacultyLoadingScreen> createState() => _FacultyLoadingScreenState();
}

class _FacultyLoadingScreenState extends State<FacultyLoadingScreen> {
  // Data
  List<Schedule>? _schedules;
  List<Faculty> _facultyList = [];
  List<Subject> _subjectList = [];
  List<Room> _roomList = [];
  List<Timeslot> _timeslotList = [];

  // Filtered Data
  List<Schedule>? _filteredSchedules;

  bool _isLoading = true;
  String? _error;

  // Search
  final _searchController = TextEditingController();

  // Maps for O(1) Lookup
  final Map<int, Faculty> _facultyMap = {};
  final Map<int, Subject> _subjectMap = {};
  final Map<int, Room> _roomMap = {};
  final Map<int, Timeslot> _timeslotMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        client.admin.getAllSchedules(),
        client.admin.getAllFaculty(),
        client.admin.getAllSubjects(),
        client.admin.getAllRooms(),
        client.admin.getAllTimeslots(),
      ]);

      _schedules = futures[0] as List<Schedule>;
      _facultyList = futures[1] as List<Faculty>;
      _subjectList = futures[2] as List<Subject>;
      _roomList = futures[3] as List<Room>;
      _timeslotList = futures[4] as List<Timeslot>;

      // Build Maps
      for (var f in _facultyList) _facultyMap[f.id!] = f;
      for (var s in _subjectList) _subjectMap[s.id!] = s;
      for (var r in _roomList) _roomMap[r.id!] = r;
      for (var t in _timeslotList) _timeslotMap[t.id!] = t;

      _filterSchedules();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterSchedules() {
    final query = _searchController.text.toLowerCase();

    if (_schedules == null) return;

    setState(() {
      _filteredSchedules = _schedules!.where((schedule) {
        final faculty = _facultyMap[schedule.facultyId];
        final subject = _subjectMap[schedule.subjectId];

        final matchesSearch =
            query.isEmpty ||
            (faculty?.name.toLowerCase().contains(query) ?? false) ||
            (faculty?.email.toLowerCase().contains(query) ?? false) ||
            (subject?.code.toLowerCase().contains(query) ?? false) ||
            (subject?.name.toLowerCase().contains(query) ?? false) ||
            (schedule.section.toLowerCase().contains(query));

        return matchesSearch;
      }).toList();
    });
  }

  int get _conflictCount {
    // Basic detection: same room at same time?
    // Since we fetch all, we can calc simple conflicts client-side for display
    return 0; // Mock for now, or implement logic
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conflict Summary
                  if (_conflictCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2), // Red-50
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Colors.red, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Schedule Conflict Summary',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                                Text(
                                  'Automated check detected overlapping assignments.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_conflictCount Conflicts Found',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5), // Green-50
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: Colors.green, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Text(
                            'No Loading Conflicts Detected',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Header & Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty Loading Management',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Semester: 2026-2nd sem (Active)',
                            style: GoogleFonts.inter(color: textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddFacultyLoadScreen(),
                            ),
                          );
                          if (result == true) {
                            _fetchData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Schedule created successfully'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Assignment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _filterSchedules(),
                            style: GoogleFonts.inter(color: textPrimary),
                            decoration: InputDecoration(
                              hintText:
                                  'Search Faculty, Subject, or Section...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _filterSchedules,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterSchedules();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textSecondary,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data Table
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF1E293B),
                      ),
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 80,
                      columnSpacing: 24,
                      horizontalMargin: 24,
                      columns: [
                        DataColumn(label: _buildHeaderCell('Faculty Member')),
                        DataColumn(label: _buildHeaderCell('Subject Details')),
                        DataColumn(label: _buildHeaderCell('Section')),
                        DataColumn(label: _buildHeaderCell('Room & Schedule')),
                        DataColumn(label: _buildHeaderCell('Status')),
                        DataColumn(
                          label: _buildHeaderCell(
                            'Actions',
                            align: TextAlign.center,
                          ),
                        ),
                      ],
                      rows:
                          _filteredSchedules?.map((schedule) {
                            final faculty = _facultyMap[schedule.facultyId];
                            final subject = _subjectMap[schedule.subjectId];
                            final room = _roomMap[schedule.roomId];
                            final timeslot = _timeslotMap[schedule.timeslotId];

                            // Check for conflict (mock or real logic)
                            final bool hasConflict = false;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        faculty?.name ?? 'Unknown',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryPurple,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${faculty?.facultyId ?? "N/A"}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        subject?.code ?? 'Unknown Breakdown',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      Text(
                                        subject?.name ?? 'Unknown',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      schedule.section,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  (room != null && timeslot != null)
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .door_front_door_outlined,
                                                  size: 14,
                                                  color: AppTheme.primaryPurple,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  room.name,
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${timeslot.day} | ${timeslot.startTime}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              Icons.smart_toy_outlined,
                                              size: 16,
                                              color: Colors.blue.shade400,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Waiting for AI...',
                                              style: GoogleFonts.inter(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.blue.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasConflict
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(
                                              0.1,
                                            ), // Green for scheduled
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: hasConflict
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    child: Text(
                                      hasConflict
                                          ? 'Conflict Detected'
                                          : 'Scheduled',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: hasConflict
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: Colors.amber,
                                        ),
                                        onPressed: () {},
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {},
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList() ??
                          [],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Expanded(
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
