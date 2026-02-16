import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_create_user_form.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserListModal extends StatefulWidget {
  const UserListModal({super.key});

  @override
  State<UserListModal> createState() => _UserListModalState();
}

class _UserListModalState extends State<UserListModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Faculty> _faculty = [];
  List<Student> _students = [];
  bool _isLoading = true;

  // Filter states
  String _facultyFilter = 'all'; // 'all', 'faculty', 'admin'
  String _studentSortOrder = 'asc'; // 'asc', 'desc'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final faculty = await client.admin.getAllFaculty();
      final students = await client.admin.getAllStudents();
      if (mounted) {
        setState(() {
          _faculty = faculty;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    }
  }

  List<Faculty> get _filteredFaculty {
    // Note: We don't have role info in Faculty model, so this is a placeholder
    // In a real implementation, you'd need to fetch UserRole data
    return _faculty;
  }

  List<Student> get _sortedStudents {
    final sorted = List<Student>.from(_students);
    sorted.sort((a, b) {
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _studentSortOrder == 'asc' ? comparison : -comparison;
    });
    return sorted;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = isDark
        ? const Color(0xFFa21caf)
        : const Color(0xFF720045);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryPurple,
                    const Color(0xFFb5179e),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Management',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage system users and permissions',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AdminCreateUserForm(
                              onSuccess: () {
                                _fetchData();
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Add User',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: bgBody,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: textMuted,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Faculty & Admin'),
                    Tab(text: 'Students'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: primaryPurple,
                        strokeWidth: 3,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFacultyList(
                          primaryPurple,
                          textPrimary,
                          textMuted,
                          bgBody,
                        ),
                        _buildStudentList(
                          primaryPurple,
                          textPrimary,
                          textMuted,
                          bgBody,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyList(
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded, color: textMuted, size: 20),
              const SizedBox(width: 12),
              Text(
                'Filter by Role:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterChip('All', 'all', primaryColor, textPrimary),
              const SizedBox(width: 8),
              _buildFilterChip('Faculty', 'faculty', primaryColor, textPrimary),
              const SizedBox(width: 8),
              _buildFilterChip('Admin', 'admin', primaryColor, textPrimary),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filteredFaculty.isEmpty
              ? _buildEmptyState(
                  'No faculty members found',
                  Icons.people_outline_rounded,
                  textMuted,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 8,
                  ),
                  itemCount: _filteredFaculty.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final f = _filteredFaculty[index];
                    return _buildFacultyCard(
                      f,
                      primaryColor,
                      textPrimary,
                      textMuted,
                      bgBody,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentList(
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    return Column(
      children: [
        // Sort Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded, color: textMuted, size: 20),
              const SizedBox(width: 12),
              Text(
                'Sort by Name:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              _buildSortChip('A → Z', 'asc', primaryColor, textPrimary),
              const SizedBox(width: 8),
              _buildSortChip('Z → A', 'desc', primaryColor, textPrimary),
            ],
          ),
        ),

        // List
        Expanded(
          child: _sortedStudents.isEmpty
              ? _buildEmptyState(
                  'No students found',
                  Icons.school_outlined,
                  textMuted,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 8,
                  ),
                  itemCount: _sortedStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = _sortedStudents[index];
                    return _buildStudentCard(
                      s,
                      primaryColor,
                      textPrimary,
                      textMuted,
                      bgBody,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    Color primaryColor,
    Color textPrimary,
  ) {
    final isSelected = _facultyFilter == value;
    return InkWell(
      onTap: () => setState(() => _facultyFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : textPrimary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(
    String label,
    String value,
    Color primaryColor,
    Color textPrimary,
  ) {
    final isSelected = _studentSortOrder == value;
    return InkWell(
      onTap: () => setState(() => _studentSortOrder = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : textPrimary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyCard(
    Faculty f,
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFFb5179e)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  f.email,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              f.department,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    Student s,
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2e7d32), Color(0xFF4caf50)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.studentNumber} • ${s.email}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2e7d32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2e7d32).withOpacity(0.3),
              ),
            ),
            child: Text(
              s.course,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2e7d32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
