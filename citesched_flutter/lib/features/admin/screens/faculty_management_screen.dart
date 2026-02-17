import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for faculty list
final facultyListProvider = FutureProvider<List<Faculty>>((ref) async {
  return await client.admin.getAllFaculty();
});

class FacultyManagementScreen extends ConsumerStatefulWidget {
  const FacultyManagementScreen({super.key});

  @override
  ConsumerState<FacultyManagementScreen> createState() =>
      _FacultyManagementScreenState();
}

class _FacultyManagementScreenState
    extends ConsumerState<FacultyManagementScreen> {
  String _searchQuery = '';
  String? _selectedDepartment;
  final TextEditingController _searchController = TextEditingController();

  // Color scheme matching admin sidebar
  final Color maroonColor = const Color(0xFF720045);
  final Color innerMenuBg = const Color(0xFF7b004f);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddFacultyModal() {
    showDialog(
      context: context,
      builder: (context) => _AddFacultyModal(
        maroonColor: maroonColor,
        onSuccess: () {
          ref.refresh(facultyListProvider);
        },
      ),
    );
  }

  void _showEditFacultyModal(Faculty faculty) {
    showDialog(
      context: context,
      builder: (context) => _EditFacultyModal(
        faculty: faculty,
        maroonColor: maroonColor,
        onSuccess: () {
          ref.refresh(facultyListProvider);
        },
      ),
    );
  }

  void _deleteFaculty(Faculty faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${faculty.name}? This action cannot be undone.',
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
        await client.admin.deleteFaculty(faculty.id!);
        ref.refresh(facultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Faculty deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting faculty: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyListProvider);
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
                      'Faculty Management',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage faculty members and their information',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddFacultyModal,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add Faculty',
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
            const SizedBox(height: 32),

            // Search and Filter Row
            Row(
              children: [
                // Search Bar with Icon
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
                          color: const Color.fromRGBO(
                            30,
                            41,
                            59,
                            1,
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
                                  'Search faculty by name, email, or ID...',
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

                // Department Filter Dropdown
                Expanded(
                  flex: 2,
                  child: Container(
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
                    child: facultyAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (facultyList) {
                        final departments =
                            facultyList
                                .map((f) => f.department)
                                .whereType<String>()
                                .toSet()
                                .toList()
                              ..sort();

                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDepartment,
                            hint: Row(
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  color: maroonColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filter by Department',
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
                                  'All Departments',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              ...departments.map((dept) {
                                return DropdownMenuItem<String>(
                                  value: dept,
                                  child: Text(
                                    dept,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartment = value;
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

            // Faculty Table
            Expanded(
              child: facultyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading faculty',
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(facultyListProvider),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (facultyList) {
                  final filteredFaculty = facultyList.where((faculty) {
                    // Search filter
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        faculty.name.toLowerCase().contains(_searchQuery) ||
                        faculty.email.toLowerCase().contains(_searchQuery) ||
                        (faculty.facultyId?.toLowerCase().contains(
                              _searchQuery,
                            ) ??
                            false);

                    // Department filter
                    final matchesDepartment =
                        _selectedDepartment == null ||
                        faculty.department == _selectedDepartment;

                    return matchesSearch && matchesDepartment;
                  }).toList();

                  if (filteredFaculty.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No faculty members yet'
                                : 'No faculty found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Faculty" to get started',
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
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(color: maroonColor, width: 4),
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
                            color: maroonColor.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: maroonColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Faculty Members',
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
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${filteredFaculty.length} Total',
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
                              dataRowMinHeight: 65,
                              dataRowMaxHeight: 85,
                              columnSpacing: 32,
                              horizontalMargin: 24,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text('FACULTY ID'),
                                ),
                                DataColumn(
                                  label: Text('NAME'),
                                ),
                                DataColumn(
                                  label: Text('EMAIL'),
                                ),
                                DataColumn(
                                  label: Text('DEPARTMENT'),
                                ),
                                DataColumn(
                                  label: Text('STATUS'),
                                ),
                                DataColumn(
                                  label: Text('SHIFT'),
                                ),
                                DataColumn(
                                  label: Text('MAX LOAD'),
                                ),
                                DataColumn(
                                  label: Text('ACTIONS'),
                                ),
                              ],
                              rows: filteredFaculty.asMap().entries.map((
                                entry,
                              ) {
                                final faculty = entry.value;
                                final index = entry.key;

                                return DataRow(
                                  color:
                                      WidgetStateProperty.resolveWith<Color?>(
                                        (states) {
                                          if (states.contains(
                                            WidgetState.hovered,
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: maroonColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          faculty.facultyId ?? 'N/A',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: maroonColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: maroonColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                faculty.name.isNotEmpty
                                                    ? faculty.name[0]
                                                          .toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            faculty.name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            faculty.email,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        faculty.department ?? 'N/A',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _getStatusColor(
                                                faculty.employmentStatus,
                                              ),
                                              _getStatusColor(
                                                faculty.employmentStatus,
                                              ).withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getStatusColor(
                                                faculty.employmentStatus,
                                              ).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(
                                                faculty.employmentStatus,
                                              ),
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _getStatusText(
                                                faculty.employmentStatus,
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getShiftColor(
                                            faculty.shiftPreference,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: _getShiftColor(
                                              faculty.shiftPreference,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getShiftIcon(
                                                faculty.shiftPreference,
                                              ),
                                              size: 14,
                                              color: _getShiftColor(
                                                faculty.shiftPreference,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _getShiftText(
                                                faculty.shiftPreference,
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: _getShiftColor(
                                                  faculty.shiftPreference,
                                                ),
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
                                            Icons.schedule,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${faculty.maxLoad} hrs',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () =>
                                                  _showEditFacultyModal(
                                                    faculty,
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: maroonColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.edit_outlined,
                                                  color: maroonColor,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () =>
                                                  _deleteFaculty(faculty),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.fullTime:
        return Colors.green;
      case EmploymentStatus.partTime:
        return Colors.orange;
    }
  }

  String _getStatusText(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.fullTime:
        return 'Full-Time';
      case EmploymentStatus.partTime:
        return 'Part-Time';
    }
  }

  IconData _getStatusIcon(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.fullTime:
        return Icons.verified;
      case EmploymentStatus.partTime:
        return Icons.schedule;
    }
  }

  Color _getShiftColor(FacultyShiftPreference? preference) {
    if (preference == null) return Colors.grey;
    switch (preference) {
      case FacultyShiftPreference.morning:
        return Colors.orange;
      case FacultyShiftPreference.afternoon:
        return Colors.blue;
      case FacultyShiftPreference.evening:
        return Colors.indigo;
      case FacultyShiftPreference.any:
        return Colors.teal;
      case FacultyShiftPreference.custom:
        return Colors.purple;
    }
  }

  String _getShiftText(FacultyShiftPreference? preference) {
    if (preference == null) return 'Any';
    switch (preference) {
      case FacultyShiftPreference.morning:
        return 'Morning';
      case FacultyShiftPreference.afternoon:
        return 'Afternoon';
      case FacultyShiftPreference.evening:
        return 'Evening';
      case FacultyShiftPreference.any:
        return 'Any';
      case FacultyShiftPreference.custom:
        return 'Custom';
    }
  }

  IconData _getShiftIcon(FacultyShiftPreference? preference) {
    if (preference == null) return Icons.access_time;
    switch (preference) {
      case FacultyShiftPreference.morning:
        return Icons.wb_sunny;
      case FacultyShiftPreference.afternoon:
        return Icons.wb_cloudy;
      case FacultyShiftPreference.evening:
        return Icons.nightlight_round;
      case FacultyShiftPreference.any:
        return Icons.all_inclusive;
      case FacultyShiftPreference.custom:
        return Icons.tune;
    }
  }
}

// Add Faculty Modal
class _AddFacultyModal extends StatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _AddFacultyModal({
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_AddFacultyModal> createState() => _AddFacultyModalState();
}

class _AddFacultyModalState extends State<_AddFacultyModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _maxLoadController = TextEditingController(text: '21');

  EmploymentStatus _employmentStatus = EmploymentStatus.fullTime;
  FacultyShiftPreference _shiftPreference = FacultyShiftPreference.morning;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facultyIdController.dispose();
    _departmentController.dispose();
    _maxLoadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final faculty = Faculty(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        facultyId: _facultyIdController.text.trim(),
        department: _departmentController.text.trim(),
        maxLoad: int.parse(_maxLoadController.text),
        employmentStatus: _employmentStatus,
        shiftPreference: _shiftPreference,
        preferredHours: null,
        userInfoId: 0, // Placeholder, will be set by backend
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await client.admin.createFaculty(faculty);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty added successfully'),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -------------------------
            // 1. Header Section
            // -------------------------
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.maroonColor,
                    widget.maroonColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.maroonColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Faculty Member',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Fill in the details to create a new faculty profile',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------
            // 2. Main Body (Split View)
            // -------------------------
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Left Column: Context/Info ---
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(
                              icon: Icons.info_outline,
                              title: 'Faculty Information',
                              description:
                                  'Enter basic information about the faculty member including their name, email, and faculty ID.',
                            ),
                            const SizedBox(height: 24),
                            _buildInfoSection(
                              icon: Icons.work_outline,
                              title: 'Employment Details',
                              description:
                                  'Specify the employment status (Full-Time or Part-Time) and department assignment.',
                            ),
                            const SizedBox(height: 24),
                            _buildInfoSection(
                              icon: Icons.schedule,
                              title: 'Schedule Preferences',
                              description:
                                  'Set the maximum teaching load (in hours) and preferred shift times for scheduling.',
                            ),
                            const SizedBox(height: 24),
                            // Tip Box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tip: Accurate shift preferences help the AI scheduler optimize faculty assignments.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Right Column: Input Form ---
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.maroonColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person,
                              helperText:
                                  'Enter the complete name of the faculty member',
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email,
                              helperText: 'Official email for communication',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (!value!.contains('@'))
                                  return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _facultyIdController,
                              label: 'Faculty ID',
                              icon: Icons.badge,
                              helperText:
                                  'Unique identifier for the faculty member',
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _departmentController,
                              label: 'Department',
                              icon: Icons.business,
                              helperText: 'Academic department or program',
                            ),
                            const SizedBox(height: 28),
                            Divider(color: Colors.grey[300], thickness: 1),
                            const SizedBox(height: 20),
                            Text(
                              'Employment & Schedule',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.maroonColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _maxLoadController,
                              label: 'Maximum Load (hours)',
                              icon: Icons.access_time,
                              helperText: 'Maximum teaching hours per week',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (int.tryParse(value!) == null)
                                  return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown<EmploymentStatus>(
                              label: 'Employment Status',
                              value: _employmentStatus,
                              items: EmploymentStatus.values,
                              onChanged: (value) =>
                                  setState(() => _employmentStatus = value!),
                              itemLabel: (status) {
                                switch (status) {
                                  case EmploymentStatus.fullTime:
                                    return 'Full-Time';
                                  case EmploymentStatus.partTime:
                                    return 'Part-Time';
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown<FacultyShiftPreference>(
                              label: 'Shift Preference',
                              value: _shiftPreference,
                              items: FacultyShiftPreference.values,
                              onChanged: (value) =>
                                  setState(() => _shiftPreference = value!),
                              itemLabel: (pref) {
                                switch (pref) {
                                  case FacultyShiftPreference.any:
                                    return 'Any';
                                  case FacultyShiftPreference.morning:
                                    return 'Morning';
                                  case FacultyShiftPreference.afternoon:
                                    return 'Afternoon';
                                  case FacultyShiftPreference.evening:
                                    return 'Evening';
                                  case FacultyShiftPreference.custom:
                                    return 'Custom';
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------
            // 3. Footer Actions
            // -------------------------
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
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
                        : const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Add Faculty Member',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
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

  // -------------------------
  // Helper Widgets
  // -------------------------

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.maroonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: widget.maroonColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,

        // Label is grey when inactive
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
        helperStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),

        // FIXED: Label stays grey even when focused/floating
        floatingLabelStyle: GoogleFonts.poppins(
          color: Colors.grey[600], // Changed from maroon to grey
          fontWeight: FontWeight.w600,
        ),

        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.maroonColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color.fromARGB(221, 255, 255, 255),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),

        // FIXED: Label stays grey even when focused/floating
        floatingLabelStyle: GoogleFonts.poppins(
          color: Colors.grey[600], // Changed from maroon to grey
          fontWeight: FontWeight.w600,
        ),

        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.maroonColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// Edit Faculty Modal (similar to Add but with pre-filled data)
class _EditFacultyModal extends StatefulWidget {
  final Faculty faculty;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditFacultyModal({
    required this.faculty,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_EditFacultyModal> createState() => _EditFacultyModalState();
}

class _EditFacultyModalState extends State<_EditFacultyModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _facultyIdController;
  late TextEditingController _departmentController;
  late TextEditingController _maxLoadController;

  late EmploymentStatus _employmentStatus;
  late FacultyShiftPreference _shiftPreference;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.faculty.name);
    _emailController = TextEditingController(text: widget.faculty.email);
    _facultyIdController = TextEditingController(text: widget.faculty.facultyId ?? '');
    _departmentController = TextEditingController(text: widget.faculty.department ?? '');
    _maxLoadController = TextEditingController(text: widget.faculty.maxLoad.toString());
    _employmentStatus = widget.faculty.employmentStatus;
    _shiftPreference = widget.faculty.shiftPreference ?? FacultyShiftPreference.any;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facultyIdController.dispose();
    _departmentController.dispose();
    _maxLoadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedFaculty = Faculty(
        id: widget.faculty.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        facultyId: _facultyIdController.text.trim(),
        department: _departmentController.text.trim(),
        maxLoad: int.parse(_maxLoadController.text),
        employmentStatus: _employmentStatus,
        shiftPreference: _shiftPreference,
        preferredHours: widget.faculty.preferredHours,
        userInfoId: widget.faculty.userInfoId,
        createdAt: widget.faculty.createdAt,
        updatedAt: DateTime.now(),
      );

      await client.admin.updateFaculty(updatedFaculty);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1000, // Slightly wider for better breathing room
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.maroonColor, widget.maroonColor.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Faculty Member',
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Update faculty information and preferences',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                  ),
                ],
              ),
            ),

            // Form Content Area
            Expanded(
              child: Row(
                children: [
                  // Left Side: Instructions
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(right: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildInfoSection(Icons.info_outline, 'Faculty Information', 'Update basic identification details.'),
                            const SizedBox(height: 24),
                            _buildInfoSection(Icons.work_outline, 'Employment Details', 'Modify status and department.'),
                            const SizedBox(height: 24),
                            _buildInfoSection(Icons.schedule, 'Schedule Preferences', 'Adjust load and shift times.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Right Side: Form
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Basic Information', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: widget.maroonColor)),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person, helperText: 'Enter complete name'),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email,
                              helperText: 'Official email address',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v != null && !v.contains('@')) ? 'Invalid email' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _facultyIdController, label: 'Faculty ID', icon: Icons.badge, helperText: 'Unique identifier'),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _departmentController, label: 'Department', icon: Icons.business, helperText: 'Academic program'),
                            const SizedBox(height: 32),
                            Text('Employment & Schedule', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: widget.maroonColor)),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _maxLoadController,
                              label: 'Maximum Load (hours)',
                              icon: Icons.access_time,
                              helperText: 'Maximum teaching hours per week',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown<EmploymentStatus>(
                              label: 'Employment Status',
                              value: _employmentStatus,
                              items: EmploymentStatus.values,
                              onChanged: (val) => setState(() => _employmentStatus = val!),
                              itemLabel: (s) => s == EmploymentStatus.fullTime ? 'Full-Time' : 'Part-Time',
                            ),
                            const SizedBox(height: 20),
                            _buildDropdown<FacultyShiftPreference>(
                              label: 'Shift Preference',
                              value: _shiftPreference,
                              items: FacultyShiftPreference.values,
                              onChanged: (val) => setState(() => _shiftPreference = val!),
                              itemLabel: (p) => p.name.toUpperCase(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.maroonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  Widget _buildInfoSection(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: widget.maroonColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: widget.maroonColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  // YOUR CUSTOM STYLED TEXTFIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? (v) => v?.isEmpty ?? true ? 'Required' : null,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
        helperStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.maroonColor, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  // YOUR CUSTOM STYLED DROPDOWN
  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item), style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
        floatingLabelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.maroonColor, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
