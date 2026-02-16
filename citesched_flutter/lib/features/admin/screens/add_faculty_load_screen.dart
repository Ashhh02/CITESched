import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/utils/app_theme.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddFacultyLoadScreen extends StatefulWidget {
  const AddFacultyLoadScreen({super.key});

  @override
  State<AddFacultyLoadScreen> createState() => _AddFacultyLoadScreenState();
}

class _AddFacultyLoadScreenState extends State<AddFacultyLoadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Data Sources
  List<Faculty> _facultyList = [];
  List<Subject> _subjectList = [];
  List<Room> _roomList = [];
  List<Timeslot> _timeslotList = [];
  bool _isLoadingData = true;

  // Form Fields
  int? _selectedFacultyId;
  int? _selectedSubjectId;
  final _sectionController = TextEditingController();
  SubjectType _loadType = SubjectType.lecture;
  final _unitsController = TextEditingController(text: '3.0');

  // Placement Strategy
  int? _selectedRoomId; // null = Auto
  int? _selectedTimeslotId; // null = Auto

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        client.admin.getAllFaculty(),
        client.admin.getAllSubjects(),
        client.admin.getAllRooms(),
        client.admin.getAllTimeslots(),
      ]);

      setState(() {
        _facultyList = futures[0] as List<Faculty>;
        _subjectList = futures[1] as List<Subject>;
        _roomList = futures[2] as List<Room>;
        _timeslotList = futures[3] as List<Timeslot>;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoadingData = false;
      });
    }
  }

  bool get _isManualOverride =>
      _selectedRoomId != null || _selectedTimeslotId != null;

  double get _calculatedHours {
    final units = double.tryParse(_unitsController.text) ?? 0.0;
    // Lab = units * 3, Lec = units * 1 (Approximate logic from HTML)
    return _loadType == SubjectType.laboratory ? units * 3 : units;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFacultyId == null || _selectedSubjectId == null) {
      setState(() => _errorMessage = 'Please select Faculty and Subject');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final schedule = Schedule(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        roomId: _selectedRoomId ?? -1, // -1 for Auto
        timeslotId: _selectedTimeslotId ?? -1, // -1 for Auto
        section: _sectionController.text.trim(),
        loadType: _loadType,
        units: double.tryParse(_unitsController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await client.admin.createSchedule(schedule);

      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputFill = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFEEF1F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assign Faculty Load',
          style: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.bottom(24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    Text(
                      'Assignment Details',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a subject from the module to assign.',
                      style: GoogleFonts.inter(color: textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Main Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Faculty & Subject
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Faculty Member',
                                  value: _selectedFacultyId,
                                  items: _facultyList
                                      .map(
                                        (f) => DropdownMenuItem(
                                          value: f.id,
                                          child: Text(f.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setState(
                                    () => _selectedFacultyId = val as int?,
                                  ),
                                  fillColor: inputFill,
                                  textColor: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Subject',
                                  value: _selectedSubjectId,
                                  items: _subjectList
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text(
                                            '[${s.code}] ${s.name}',
                                          ), // Add Year if available
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setState(() {
                                    _selectedSubjectId = val as int?;
                                    // Auto-set units if user hasn't typed? For now manual.
                                  }),
                                  fillColor: inputFill,
                                  textColor: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Row 2: Section, Category, Units, Hours
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _sectionController,
                                  label: 'Section (e.g. BSIT 3A)',
                                  fillColor: inputFill,
                                  textColor: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Category',
                                  value: _loadType,
                                  items: SubjectType.values
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(
                                            t == SubjectType.lecture
                                                ? 'Lecture'
                                                : 'Laboratory',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setState(
                                    () => _loadType = val as SubjectType,
                                  ),
                                  fillColor: inputFill,
                                  textColor: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _unitsController,
                                  label: 'Units',
                                  keyboardType: TextInputType.number,
                                  fillColor: inputFill,
                                  textColor: textPrimary,
                                  onChanged: (_) =>
                                      setState(() {}), // Refresh hours calc
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2C2C2C)
                                        : Colors.white,
                                    border: Border.all(
                                      color: AppTheme.primaryPurple.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  height: 56, // Match text field height approx
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Teaching Hours',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_calculatedHours.toStringAsFixed(1)} Hours',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryPurple,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Placement Strategy',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logic Panel
                        Expanded(
                          flex: 4,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _isManualOverride
                                  ? const Color(0xFFFFFDF5)
                                  : const Color(
                                      0xFFecfeff,
                                    ), // Light Yellow vs Light Cyan
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: _isManualOverride
                                      ? const Color(0xFFFFC107)
                                      : const Color(0xFF0DCAF0),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _isManualOverride
                                            ? const Color(0xFFFFC107)
                                            : const Color(0xFF0DCAF0),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (_isManualOverride
                                                        ? const Color(
                                                            0xFFFFC107,
                                                          )
                                                        : const Color(
                                                            0xFF0DCAF0,
                                                          ))
                                                    .withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isManualOverride
                                          ? 'Manual Override Mode'
                                          : 'Optimizer Standby',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isManualOverride
                                      ? 'Custom room/time selected. Conflict checks will apply.'
                                      : 'Room and Timetables will be assigned by AI later.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Room & Timeslot Selectors
                        Expanded(
                          flex: 8,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(
                                      label: 'Room Selection',
                                      value: _selectedRoomId,
                                      // Add Null Option manually
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text(
                                            '✨ Auto-Assign Best Room',
                                          ),
                                        ),
                                        ..._roomList.map(
                                          (r) => DropdownMenuItem(
                                            value: r.id,
                                            child: Text(r.name),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) => setState(
                                        () => _selectedRoomId = val as int?,
                                      ),
                                      fillColor: inputFill,
                                      textColor: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDropdown(
                                      label: 'Timeslot',
                                      value: _selectedTimeslotId,
                                      items: [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          child: Text(
                                            '✨ Auto-Assign Best Slot',
                                          ),
                                        ),
                                        ..._timeslotList.map(
                                          (t) => DropdownMenuItem(
                                            value: t.id,
                                            child: Text(
                                              '${t.day} | ${t.startTime}',
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) => setState(
                                        () => _selectedTimeslotId = val as int?,
                                      ),
                                      fillColor: inputFill,
                                      textColor: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Submit Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: const Icon(Icons.save),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Faculty Load'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
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
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required Color fillColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: fillColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
