import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/theme/app_theme.dart';
import 'package:citesched_flutter/main.dart'; // For client access
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyManagementScreen extends StatefulWidget {
  const FacultyManagementScreen({super.key});

  @override
  State<FacultyManagementScreen> createState() =>
      _FacultyManagementScreenState();
}

class _FacultyManagementScreenState extends State<FacultyManagementScreen> {
  List<Faculty>? _facultyList;
  List<Faculty>? _filteredFacultyList;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _selectedProgram = ''; // '' means All

  // Mock conflict count for now, real implementation would fetch from server
  int _conflictCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchFaculty();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFaculty() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final faculty = await client.admin.getAllFaculty();
      if (mounted) {
        setState(() {
          _facultyList = faculty;
          _filterFaculty(); // Apply initial filters
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load faculty: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterFaculty() {
    if (_facultyList == null) return;

    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFacultyList = _facultyList!.where((f) {
        final matchesSearch =
            f.name.toLowerCase().contains(query) ||
            f.email.toLowerCase().contains(query) ||
            f.facultyId.toLowerCase().contains(query);
        final matchesProgram =
            _selectedProgram.isEmpty ||
            (f.department == 'CITE' &&
                _selectedProgram == 'BSIT'); // Simplify logic for now
        // In reality, program might be stored in department or other field?
        // The Django template had "Program" column.
        // Faculty model has 'department'. Let's assume department stores program for now or add logic.
        // Wait, Faculty model default is 'CITE'.

        return matchesSearch && matchesProgram;
      }).toList();
    });
  }

  void _showAddFacultyDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddFacultyDialog(),
    ).then((val) {
      if (val == true) {
        _fetchFaculty(); // Refresh list on success
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = const Color(0xFF720045);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conflict Summary Card (Conditional)
            if (_conflictCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFeff6ff,
                  ), // Light blueish/redish background? Django template used danger opacity
                  // Django: bg-danger bg-opacity-10
                  // Let's use Red opacity
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFef4444).withOpacity(0.1),
                      const Color(0xFFef4444).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFef4444), width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFef4444),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Conflict Summary',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFFef4444),
                            ),
                          ),
                          Text(
                            'Automated check detected one or more overlapping assignments.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFFef4444).withOpacity(0.8),
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
                        color: const Color(0xFFef4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_conflictCount Conflicts Found',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Members',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Manage program instructors and teaching preferences.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddFacultyDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Faculty'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _filterFaculty(),
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search Name, ID, or Email...',
                        hintStyle: TextStyle(color: textMuted),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textMuted,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9), // Light gray
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Program Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedProgram,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: textMuted,
                          ),
                          dropdownColor: cardBg,
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 14,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text('All Programs'),
                            ),
                            DropdownMenuItem(
                              value: 'BSIT',
                              child: Text('BSIT'),
                            ),
                            DropdownMenuItem(
                              value: 'BSEMC',
                              child: Text('BSEMC'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedProgram = val ?? '';
                              _filterFaculty();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Buttons
                  ElevatedButton(
                    onPressed: _filterFaculty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedProgram = '';
                        _filterFaculty();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textMuted,
                      side: BorderSide(color: textMuted.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Faculty Table
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16), // Rounded-4
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  : _filteredFacultyList?.isEmpty ?? true
                  ? Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 48,
                            color: textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No faculty records found.',
                            style: GoogleFonts.poppins(
                              color: textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF1E293B),
                        ), // Dark header
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 80,
                        columnSpacing: 24,
                        horizontalMargin: 24,
                        columns: [
                          DataColumn(label: _buildHeaderCell('ID')),
                          DataColumn(label: _buildHeaderCell('Name')),
                          DataColumn(label: _buildHeaderCell('Program')),
                          DataColumn(label: _buildHeaderCell('Email')),
                          DataColumn(label: _buildHeaderCell('Weekly Limit')),
                          DataColumn(
                            label: _buildHeaderCell(
                              'Actions',
                              align: TextAlign.center,
                            ),
                          ),
                        ],
                        rows: _filteredFacultyList!.map((faculty) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  faculty.facultyId,
                                  style: GoogleFonts.poppins(
                                    color: const Color(
                                      0xFF0ea5e9,
                                    ), // Primary blue-ish like Django
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      faculty.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildShiftBadge(faculty),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (faculty.department == 'BSIT' ||
                                            faculty.department == 'CITE')
                                        ? const Color(
                                            0xFF0ea5e9,
                                          ).withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    faculty
                                        .department, // Assuming department holds Program for now
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (faculty.department == 'BSIT' ||
                                              faculty.department == 'CITE')
                                          ? const Color(0xFF0ea5e9)
                                          : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  faculty.email,
                                  style: GoogleFonts.poppins(color: textMuted),
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${faculty.maxLoad} Units',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 5,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          2.5,
                                        ),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: (faculty.maxLoad / 40)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: primaryPurple,
                                            borderRadius: BorderRadius.circular(
                                              2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      color: Colors.amber[700],
                                      tooltip: 'Edit',
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                      color: Colors.red[700],
                                      tooltip: 'Delete',
                                      onPressed: () {},
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
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Expanded(
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildShiftBadge(Faculty faculty) {
    // If custom, show green clock icon and "Custom Hours"
    // Does Faculty have shiftPreference? Yes, added in update.
    // Assuming backend updated. If not, fallback.

    // We can check if we have the shiftPreference field generated.
    try {
      if (faculty.shiftPreference == FacultyShiftPreference.custom) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off, size: 12, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Custom Hours',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      } else {
        // Show shift name
        String label = 'Any Shift';
        if (faculty.shiftPreference == FacultyShiftPreference.morning)
          label = 'Morning Shift';
        if (faculty.shiftPreference == FacultyShiftPreference.afternoon)
          label = 'Afternoon Shift';
        if (faculty.shiftPreference == FacultyShiftPreference.evening)
          label = 'Evening Shift';

        return Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey,
          ),
        );
      }
    } catch (_) {
      // Fallback if field not available yet (e.g. client not regenerated fully)
      return const SizedBox.shrink();
    }
  }
}

class AddFacultyDialog extends StatefulWidget {
  const AddFacultyDialog({super.key});

  @override
  State<AddFacultyDialog> createState() => _AddFacultyDialogState();
}

class _AddFacultyDialogState extends State<AddFacultyDialog> {
  final _formKey = GlobalKey<FormState>();

  // Account Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _departmentController = TextEditingController(
    text: 'CITE',
  ); // Default to CITE/BSIT

  // Scheduling Constraints
  final _maxLoadController = TextEditingController(text: '18');
  EmploymentStatus _employmentStatus = EmploymentStatus.fullTime;
  FacultyShiftPreference _shiftPreference = FacultyShiftPreference.any;
  final _customHoursController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facultyIdController.dispose();
    _departmentController.dispose();
    _maxLoadController.dispose();
    _customHoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create User Account (creates Faculty with defaults)
      final success = await client.setup.createAccount(
        userName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: 'ChangeMe123!', // Default password
        role: 'faculty',
        facultyId: _facultyIdController.text.trim(),
      );

      if (!success) {
        throw Exception(
          'Failed to create account. Email or ID might already exist.',
        );
      }

      // 2. Fetch the newly created faculty to update details
      // We have to find it by email since we don't have the ID returned
      final allFaculty = await client.admin.getAllFaculty();
      final createdFaculty = allFaculty.firstWhere(
        (f) => f.email == _emailController.text.trim(),
        orElse: () =>
            throw Exception('Account created but faculty record not found.'),
      );

      // 3. Update with additional details
      createdFaculty.maxLoad = int.parse(_maxLoadController.text.trim());
      createdFaculty.employmentStatus = _employmentStatus;
      createdFaculty.shiftPreference = _shiftPreference;
      createdFaculty.preferredHours =
          _shiftPreference == FacultyShiftPreference.custom
          ? _customHoursController.text.trim()
          : null;
      // department is already default CITE, but if we had dropdown we'd update it here

      await client.admin.updateFaculty(createdFaculty);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFill = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF333333);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(32),
        width: 900, // Wider for 2 columns
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Faculty',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new instructor profile. Default password will be "ChangeMe123!".',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Account Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neonGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                          fillColor: inputFill,
                          textColor: textPrimary,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address (JMC Account)',
                          validator: (v) =>
                              v?.contains('@') != true ? 'Invalid email' : null,
                          fillColor: inputFill,
                          textColor: textPrimary,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _facultyIdController,
                                label: 'Faculty ID',
                                validator: (v) =>
                                    v?.isEmpty == true ? 'Required' : null,
                                fillColor: inputFill,
                                textColor: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _departmentController,
                                label: 'Department',
                                readOnly: true,
                                fillColor: inputFill,
                                textColor: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 48), // Spacer between columns
                  // Right Column: Scheduling Constraints
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduling Constraints',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Colors.purpleAccent, // Differentiate slightly
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _maxLoadController,
                                label: 'Max Weekly Load (Units)',
                                keyboardType: TextInputType.number,
                                validator: (v) => int.tryParse(v ?? '') == null
                                    ? 'Invalid'
                                    : null,
                                fillColor: inputFill,
                                textColor: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<EmploymentStatus>(
                                value: _employmentStatus,
                                dropdownColor: const Color(0xFF2C2C2C),
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: inputFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: EmploymentStatus.values.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status == EmploymentStatus.fullTime
                                          ? 'Full-Time'
                                          : 'Part-Time',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _employmentStatus = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<FacultyShiftPreference>(
                          value: _shiftPreference,
                          dropdownColor: const Color(0xFF2C2C2C),
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Shift Preference',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: FacultyShiftPreference.values.map((pref) {
                            String label = 'Any Shift';
                            if (pref == FacultyShiftPreference.morning)
                              label = 'Morning (7AM - 12PM)';
                            if (pref == FacultyShiftPreference.afternoon)
                              label = 'Afternoon (12PM - 6PM)';
                            if (pref == FacultyShiftPreference.evening)
                              label = 'Evening (6PM - 9PM)';
                            if (pref == FacultyShiftPreference.custom)
                              label = 'Custom Hours...';

                            return DropdownMenuItem(
                              value: pref,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _shiftPreference = val);
                          },
                        ),

                        // Custom Hours Input (Visible if Custom selected)
                        if (_shiftPreference ==
                            FacultyShiftPreference.custom) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _customHoursController,
                            label: 'Specify Custom Hours (e.g., "MWF 8-12")',
                            validator: (v) => v?.isEmpty == true
                                ? 'Required for custom shift'
                                : null,
                            fillColor: inputFill,
                            textColor: textPrimary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Faculty Profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color fillColor,
    required Color textColor,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.neonGreen, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
