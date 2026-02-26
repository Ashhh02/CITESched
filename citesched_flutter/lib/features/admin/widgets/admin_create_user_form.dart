import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminCreateUserForm extends StatefulWidget {
  final VoidCallback onSuccess;

  /// Optional: pre-select a role when opening the dialog.
  final String? initialRole;

  const AdminCreateUserForm({
    super.key,
    required this.onSuccess,
    this.initialRole,
  });

  @override
  State<AdminCreateUserForm> createState() => _AdminCreateUserFormState();
}

class _AdminCreateUserFormState extends State<AdminCreateUserForm> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sectionController = TextEditingController();
  late String _selectedRole;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'student';
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await client.setup.createAccount(
        userName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        studentId: _selectedRole == 'student'
            ? _idController.text.trim()
            : null,
        facultyId: _selectedRole == 'faculty' || _selectedRole == 'admin'
            ? _idController.text.trim()
            : null,
        section:
            _selectedRole == 'student' &&
                _sectionController.text.trim().isNotEmpty
            ? _sectionController.text.trim()
            : null,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'User created successfully!',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2e7d32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          widget.onSuccess();
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to create user. Email might be taken or invalid data.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    final isStudent = _selectedRole == 'student';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 820),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with gradient
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
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
                              'Add New System User',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new account for the CITESched system',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // System Role
                      _buildLabel(
                        'System Role',
                        Icons.admin_panel_settings_rounded,
                        textPrimary,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgBody,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: textMuted,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'student',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 18,
                                      color: primaryPurple,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Student'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'faculty',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 18,
                                      color: primaryPurple,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Faculty Member'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_rounded,
                                      size: 18,
                                      color: primaryPurple,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('System Administrator'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Student / Faculty ID
                      _buildLabel(
                        isStudent ? 'Student ID' : 'Faculty ID',
                        Icons.badge_rounded,
                        textPrimary,
                      ),
                      TextFormField(
                        controller: _idController,
                        decoration: _buildInputDecoration(
                          isStudent ? '107690' : 'FAC-001',
                          bgBody,
                          primaryPurple,
                          textMuted,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      _buildLabel(
                        'Full Name',
                        Icons.person_outline_rounded,
                        textPrimary,
                      ),
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          'Nash Andrew',
                          bgBody,
                          primaryPurple,
                          textMuted,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // JMC Account (Email)
                      _buildLabel(
                        'JMC Account (Email)',
                        Icons.email_outlined,
                        textPrimary,
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: _buildInputDecoration(
                          'nash.cabillon@jmc.edu.ph',
                          bgBody,
                          primaryPurple,
                          textMuted,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Section — only for Student
                      if (isStudent) ...[
                        _buildLabel(
                          'Section',
                          Icons.group_rounded,
                          textPrimary,
                        ),
                        TextFormField(
                          controller: _sectionController,
                          decoration: _buildInputDecoration(
                            'e.g. BSIT-3A',
                            bgBody,
                            primaryPurple,
                            textMuted,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: textPrimary,
                          ),
                          // Optional — no validator
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Initial Password
                      _buildLabel(
                        'Initial Password',
                        Icons.lock_outline_rounded,
                        textPrimary,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _buildInputDecoration(
                          'Min 8 characters',
                          bgBody,
                          primaryPurple,
                          textMuted,
                        ),
                        obscureText: true,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 8) return 'Min 8 chars';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: textMuted,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: primaryPurple
                                    .withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create User Account',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textPrimary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    Color bgBody,
    Color primaryPurple,
    Color textMuted,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: textMuted.withOpacity(0.6),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: bgBody,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
