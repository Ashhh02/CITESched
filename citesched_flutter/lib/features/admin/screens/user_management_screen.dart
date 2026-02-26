import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:citesched_flutter/core/providers/admin_providers.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  bool _isShowingArchived = false;
  final _searchController = TextEditingController();

  final Color maroonColor = const Color(0xFF720045);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = _isShowingArchived
        ? ref.watch(archivedStudentsProvider)
        : ref.watch(studentsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Section ──────────────────────────────────────────────
            // Header (Standardized Maroon Gradient Banner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [maroonColor, const Color(0xFF8e005b)],
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
                          Icons.manage_accounts_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage student accounts and section assignments',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
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
                    onPressed: _showAddStudentModal,
                    icon: const Icon(Icons.person_add_rounded, size: 24),
                    label: Text(
                      'Add Student',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: maroonColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
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

            const SizedBox(height: 32),

            // ── View Toggle and Search Area ───────────────────────────────
            Row(
              children: [
                _buildViewToggle(
                  Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search students by name, ID, or course...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Students Table ────────────────────────────────────────────
            studentsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
              data: (students) {
                final filtered = students.where((s) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      s.studentNumber.toLowerCase().contains(q) ||
                      s.course.toLowerCase().contains(q) ||
                      (s.section?.toLowerCase().contains(q) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(60),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          maroonColor.withValues(alpha: 0.06),
                        ),
                        headingTextStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: maroonColor,
                          fontSize: 12,
                        ),
                        columnSpacing: 32,
                        columns: const [
                          DataColumn(label: Text('STUDENT NO.')),
                          DataColumn(label: Text('NAME')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('COURSE')),
                          DataColumn(label: Text('YEAR')),
                          DataColumn(label: Text('SECTION')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filtered.map((student) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  student.studentNumber,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  student.name,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  student.email,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  student.course,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${student.yearLevel}',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        student.section != null &&
                                            student.section!.isNotEmpty
                                        ? maroonColor.withValues(alpha: 0.08)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    student.section?.isNotEmpty == true
                                        ? student.section!
                                        : '—',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          student.section != null &&
                                              student.section!.isNotEmpty
                                          ? maroonColor
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_isShowingArchived) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                        ),
                                        color: maroonColor,
                                        tooltip: 'Edit Student',
                                        onPressed: () =>
                                            _showEditStudentModal(student),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.archive_outlined,
                                          size: 18,
                                        ),
                                        color: Colors.orange,
                                        tooltip: 'Archive Student',
                                        onPressed: () =>
                                            _archiveStudent(student),
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.restore_rounded,
                                          size: 18,
                                        ),
                                        color: Colors.green,
                                        tooltip: 'Restore Student',
                                        onPressed: () =>
                                            _restoreStudent(student),
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
          ],
        ),
      ),
    );
  }

  void _showAddStudentModal() {
    showDialog(
      context: context,
      builder: (context) => _StudentModal(
        maroonColor: maroonColor,
        onSuccess: () => ref.invalidate(studentsProvider),
      ),
    );
  }

  void _showEditStudentModal(Student student) {
    showDialog(
      context: context,
      builder: (context) => _StudentModal(
        maroonColor: maroonColor,
        student: student,
        onSuccess: () => ref.invalidate(studentsProvider),
      ),
    );
  }

  void _archiveStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Student',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive "${student.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Archive',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && student.id != null) {
      try {
        final archivedStudent = student.copyWith(isActive: false);
        await client.admin.updateStudent(archivedStudent);
        ref.invalidate(studentsProvider);
        ref.invalidate(archivedStudentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student archived'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _restoreStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Student',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to restore "${student.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              'Restore',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && student.id != null) {
      try {
        final restoredStudent = student.copyWith(isActive: true);
        await client.admin.updateStudent(restoredStudent);
        ref.invalidate(studentsProvider);
        ref.invalidate(archivedStudentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student restored'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Active', false, isDark),
          _buildToggleOption('Archived', true, isDark),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isArchived, bool isDark) {
    final isSelected = _isShowingArchived == isArchived;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isShowingArchived = isArchived;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? maroonColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

// ─── Add/Edit Student Modal ─────────────────────────────────────────────────
class _StudentModal extends StatefulWidget {
  final Color maroonColor;
  final Student? student;
  final VoidCallback onSuccess;

  const _StudentModal({
    required this.maroonColor,
    this.student,
    required this.onSuccess,
  });

  bool get isEdit => student != null;

  @override
  State<_StudentModal> createState() => _StudentModalState();
}

class _StudentModalState extends State<_StudentModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _studentNumberController;
  late TextEditingController _courseController;
  late TextEditingController _yearLevelController;
  late TextEditingController _sectionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _emailController = TextEditingController(text: widget.student?.email ?? '');
    _studentNumberController = TextEditingController(
      text: widget.student?.studentNumber ?? '',
    );
    _courseController = TextEditingController(
      text: widget.student?.course ?? '',
    );
    _yearLevelController = TextEditingController(
      text: widget.student?.yearLevel.toString() ?? '',
    );
    _sectionController = TextEditingController(
      text: widget.student?.section ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentNumberController.dispose();
    _courseController.dispose();
    _yearLevelController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final student = Student(
        id: widget.student?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        studentNumber: _studentNumberController.text.trim(),
        course: _courseController.text.trim(),
        yearLevel: int.tryParse(_yearLevelController.text) ?? 1,
        section: _sectionController.text.trim().isEmpty
            ? null
            : _sectionController.text.trim(),
        userInfoId: widget.student?.userInfoId ?? 0,
        isActive: widget.student?.isActive ?? true,
        createdAt: widget.student?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.isEdit) {
        await client.admin.updateStudent(student);
      } else {
        await client.admin.createStudent(student);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Student updated successfully'
                  : 'Student added successfully',
            ),
            backgroundColor: Colors.green,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBody = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F0F5);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.maroonColor, const Color(0xFFb5179e)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isEdit
                        ? Icons.edit_rounded
                        : Icons.person_add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isEdit ? 'Edit Student' : 'Add New Student',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        controller: _nameController,
                        hint: 'Juan Dela Cruz',
                        bgBody: bgBody,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        hint: 'student@jmc.edu.ph',
                        bgBody: bgBody,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (!v!.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Student Number',
                        icon: Icons.badge_rounded,
                        controller: _studentNumberController,
                        hint: 'STU-001',
                        bgBody: bgBody,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Course / Program',
                        icon: Icons.school_outlined,
                        controller: _courseController,
                        hint: 'e.g. BSIT, BSCS, BSIS',
                        bgBody: bgBody,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Year Level',
                        icon: Icons.format_list_numbered_rounded,
                        controller: _yearLevelController,
                        hint: '1',
                        bgBody: bgBody,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (int.tryParse(v!) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        label: 'Section',
                        icon: Icons.group_outlined,
                        controller: _sectionController,
                        hint: 'e.g. BSIT-3A, BSCS-2B',
                        bgBody: bgBody,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue[400],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Section connects the student to their class schedule and assigned faculty.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.blue[600],
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

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey),
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
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isEdit ? 'Update Student' : 'Add Student',
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

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required Color bgBody,
    required Color textPrimary,
    required Color textMuted,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: textMuted),
            filled: true,
            fillColor: bgBody,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.maroonColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
