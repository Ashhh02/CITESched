import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for subject list
final subjectListProvider = FutureProvider<List<Subject>>((ref) async {
  return await client.admin.getAllSubjects();
});

class SubjectManagementScreen extends ConsumerStatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  ConsumerState<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState
    extends ConsumerState<SubjectManagementScreen> {
  String _searchQuery = '';
  int? _selectedYearLevel;
  Program? _selectedProgram;
  final TextEditingController _searchController = TextEditingController();

  final Color maroonColor = const Color(0xFF720045);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSubjectModal() {
    showDialog(
      context: context,
      builder: (context) => _AddSubjectModal(
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(subjectListProvider);
        },
      ),
    );
  }

  void _showEditSubjectModal(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => _EditSubjectModal(
        subject: subject,
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(subjectListProvider);
        },
      ),
    );
  }

  void _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Subject',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${subject.name}? This action cannot be undone.',
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
        await client.admin.deleteSubject(subject.id!);
        ref.invalidate(subjectListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting subject: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectListProvider);
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
                      'Subject Management',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage academic subjects, units, and program assignments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddSubjectModal,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add Subject',
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
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            cursorColor: isDark ? Colors.white : Colors.black87,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Search by code or title...',
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
                  child: _buildYearFilter(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildProgramFilter(isDark),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (subjects) {
                  final filtered = subjects.where((s) {
                    final matchesSearch =
                        s.code.toLowerCase().contains(_searchQuery) ||
                        s.name.toLowerCase().contains(_searchQuery);
                    final matchesYear =
                        _selectedYearLevel == null ||
                        s.yearLevel == _selectedYearLevel;
                    final matchesProgram =
                        _selectedProgram == null ||
                        s.program == _selectedProgram;
                    return matchesSearch && matchesYear && matchesProgram;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No subjects found'));
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
                                Icons.book_rounded,
                                color: maroonColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Subjects',
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
                                  '${filtered.length} Total',
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
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              columns: const [
                                DataColumn(label: Text('CODE')),
                                DataColumn(label: Text('TITLE')),
                                DataColumn(label: Text('UNITS')),
                                DataColumn(label: Text('PROGRAM')),
                                DataColumn(label: Text('YEAR/TERM')),
                                DataColumn(label: Text('TYPE')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: filtered.asMap().entries.map((entry) {
                                final subject = entry.value;
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
                                      Text(
                                        subject.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(subject.name)),
                                    DataCell(Text(subject.units.toString())),
                                    DataCell(
                                      Text(subject.program.name.toUpperCase()),
                                    ),
                                    DataCell(
                                      Text(
                                        '${subject.yearLevel ?? "-"} / ${subject.term ?? "-"}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(subject.type.name.toUpperCase()),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _showEditSubjectModal(subject),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _deleteSubject(subject),
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

  Widget _buildYearFilter(bool isDark) {
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
        child: DropdownButton<int>(
          value: _selectedYearLevel,
          hint: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Year Level',
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
                'All Years',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...List.generate(
              4,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(
                  'Year ${i + 1}',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedYearLevel = v),
        ),
      ),
    );
  }

  Widget _buildProgramFilter(bool isDark) {
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
        child: DropdownButton<Program>(
          value: _selectedProgram,
          hint: Row(
            children: [
              Icon(Icons.school_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Program',
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
                'All Programs',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...Program.values.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(
                  p.name.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedProgram = v),
        ),
      ),
    );
  }
}

class _AddSubjectModal extends StatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _AddSubjectModal({required this.maroonColor, required this.onSuccess});

  @override
  State<_AddSubjectModal> createState() => _AddSubjectModalState();
}

class _AddSubjectModalState extends State<_AddSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitsController = TextEditingController(text: '3');
  final _studentsCountController = TextEditingController(text: '40');

  int _yearLevel = 1;
  int _term = 1;
  SubjectType _type = SubjectType.lecture;
  Program _program = Program.it;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Subject'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextFormField(
                controller: _unitsController,
                decoration: const InputDecoration(labelText: 'Units'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _studentsCountController,
                decoration: const InputDecoration(labelText: 'Student Count'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<Program>(
                value: _program,
                decoration: const InputDecoration(labelText: 'Program'),
                items: Program.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _program = v!),
              ),
              DropdownButtonFormField<int>(
                value: _yearLevel,
                decoration: const InputDecoration(labelText: 'Year Level'),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Year ${i + 1}'),
                  ),
                ),
                onChanged: (v) => setState(() => _yearLevel = v!),
              ),
              DropdownButtonFormField<int>(
                value: _term,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: [1, 2]
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('Semester $i'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _term = v!),
              ),
              DropdownButtonFormField<SubjectType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: SubjectType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: widget.maroonColor),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final subject = Subject(
        code: _codeController.text,
        name: _nameController.text,
        units: int.parse(_unitsController.text),
        studentsCount: int.parse(_studentsCountController.text),
        yearLevel: _yearLevel,
        term: _term,
        type: _type,
        program: _program,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await client.admin.createSubject(subject);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _EditSubjectModal extends StatefulWidget {
  final Subject subject;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditSubjectModal({
    required this.subject,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_EditSubjectModal> createState() => _EditSubjectModalState();
}

class _EditSubjectModalState extends State<_EditSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _unitsController;
  late TextEditingController _studentsCountController;

  late int _yearLevel;
  late int _term;
  late SubjectType _type;
  late Program _program;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.subject.code);
    _nameController = TextEditingController(text: widget.subject.name);
    _unitsController = TextEditingController(
      text: widget.subject.units.toString(),
    );
    _studentsCountController = TextEditingController(
      text: widget.subject.studentsCount.toString(),
    );
    _yearLevel = widget.subject.yearLevel ?? 1;
    _term = widget.subject.term ?? 1;
    _type = widget.subject.type;
    _program = widget.subject.program;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Subject'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextFormField(
                controller: _unitsController,
                decoration: const InputDecoration(labelText: 'Units'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _studentsCountController,
                decoration: const InputDecoration(labelText: 'Student Count'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<Program>(
                value: _program,
                decoration: const InputDecoration(labelText: 'Program'),
                items: Program.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _program = v!),
              ),
              DropdownButtonFormField<int>(
                value: _yearLevel,
                decoration: const InputDecoration(labelText: 'Year Level'),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Year ${i + 1}'),
                  ),
                ),
                onChanged: (v) => setState(() => _yearLevel = v!),
              ),
              DropdownButtonFormField<int>(
                value: _term,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: [1, 2]
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('Semester $i'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _term = v!),
              ),
              DropdownButtonFormField<SubjectType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: SubjectType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: widget.maroonColor),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = widget.subject.copyWith(
        code: _codeController.text,
        name: _nameController.text,
        units: int.parse(_unitsController.text),
        studentsCount: int.parse(_studentsCountController.text),
        yearLevel: _yearLevel,
        term: _term,
        type: _type,
        program: _program,
        updatedAt: DateTime.now(),
      );
      await client.admin.updateSubject(updated);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
