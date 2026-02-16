import 'package:citesched_flutter/main.dart'; // Import for client access
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_client/serverpod_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isFaculty = true; // Toggle state
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isDarkMode = false; // Add dark mode state
  String? _errorMessage;

  // Design Constants - Light Mode Theme Colors
  static const _facultyColorLight = Color(0xFF4F003B);
  static const _studentColorLight = Color(0xFF004085);

  // Dark Mode Theme Colors
  static const _facultyColorDark = Color(0xFFa21caf);
  static const _studentColorDark = Color(0xFF3b82f6);

  // Light Mode Colors
  static const _bgBodyLight = Color(0xFFEEF1F6);
  static const _bgRightLight = Color(
    0xFFF7F9FC,
  ); // Used for right side background if distinct
  static const _cardBgLight = Colors.white;
  static const _textPrimaryLight = Color.fromARGB(255, 182, 182, 182);
  static const _textMutedLight = Color(0xFF666666);
  static const _inputBorderLight = Color(0xFFDDDDDD);

  // Dark Mode Colors
  static const _bgBodyDark = Color(0xFF0F172A);
  static const _bgRightDark = Color(
    0xFF1E293B,
  ); // Used for right side background if distinct
  static const _cardBgDark = Color(0xFF1E293B);
  static const _textPrimaryDark = Color(0xFFE2E8F0);
  static const _textMutedDark = Color(0xFF94A3B8);
  static const _inputBorderDark = Color(0xFF475569);

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = _idController.text.trim();
      final password = _passwordController.text.trim();

      if (id.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter ID and password';
          _isLoading = false;
        });
        return;
      }

      // Use dynamic access to bypass static analysis issues
      final dynamicClient = client as dynamic;
      // Call the custom auth endpoint
      final result = await dynamicClient.customAuth.loginWithId(
        id: id,
        password: password,
        role: _isFaculty ? 'faculty' : 'student',
      );

      if (result.success &&
          result.userInfo != null &&
          result.keyId != null &&
          result.key != null) {
        // Register the session with Serverpod's SessionManager
        // This is CRITICAL for subsequent requests to be authenticated
        print('Login Successful. KeyID: ${result.keyId}, Key: ${result.key}');
        print('UserInfo: ${result.userInfo}');

        // Create a fake UUID from the integer keyId to satisfy AuthSuccess (v3) requirements
        // userIdentifier is not strictly used for session key validation in some configs
        var fakeUuid = UuidValue.fromString(
          "00000000-0000-0000-0000-${result.keyId.toString().padLeft(12, '0')}",
        );

        // Serverpod typically expects "keyId:key" as the token for integer-based IDs
        String formattedToken = '${result.keyId}:${result.key}';

        var authSuccess = AuthSuccess(
          authUserId: fakeUuid,
          token: formattedToken,
          scopeNames: result.userInfo!.scopeNames.toSet(),
          authStrategy: 'session',
        );
        print('Updating signed in user with AuthSuccess: $authSuccess');
        await client.auth.updateSignedInUser(authSuccess);

        // Update the auth provider (though the listener might handle it now)
        final authNotifier = ref.read(authProvider.notifier);
        authNotifier.updateUserInfo(result.userInfo);

        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
          // Navigation will happen automatically via RootScreen watching authProvider
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    // Active Theme Colors
    final activeThemeColor = _isDarkMode
        ? (_isFaculty ? _facultyColorDark : _studentColorDark)
        : (_isFaculty ? _facultyColorLight : _studentColorLight);
    final bgBody = _isDarkMode ? _bgBodyDark : _bgBodyLight;
    final cardBg = _isDarkMode ? _cardBgDark : _cardBgLight;
    final textPrimary = _isDarkMode ? _textPrimaryDark : _textPrimaryLight;
    final textMuted = _isDarkMode ? _textMutedDark : _textMutedLight;
    final inputBorder = _isDarkMode ? _inputBorderDark : _inputBorderLight;

    // For right side background, the design uses a slightly different color
    // but the split container CSS defines bg-right separately.
    final bgRight = _isDarkMode ? _bgRightDark : _bgRightLight;

    return Scaffold(
      backgroundColor: bgBody,
      body: Row(
        children: [
          // Left Side - Image (Desktop only)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/jmcbackground.jpg',
                    fit: BoxFit.cover,
                    // Simulate image-rendering: -webkit-optimize-contrast
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: _facultyColorLight);
                    },
                  ),
                  // Overlay to ensure text readability (matches the text-shadow logic mostly,
                  // but a slight gradient helps like in the previous version)
                  Container(
                    color: Colors.black.withValues(
                      alpha: 0.3,
                    ), // Slight darkening for text contrast
                  ),
                  Padding(
                    padding: const EdgeInsets.all(80.0), // match padding: 80px
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CITESched',
                          style: GoogleFonts.poppins(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: Colors.white,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                offset: const Offset(2, 2),
                                blurRadius: 15,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10), // margin-bottom: 10px
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 550,
                          ), // max-width: 550px
                          child: Text(
                            'Secure access to faculty loading, conflict detection, and student class schedules for the JMCFI CITE Department.',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Right Side - Login Form
          Expanded(
            flex: 1,
            child: Container(
              color: bgRight, // var(--bg-right)
              child: Stack(
                children: [
                  // Theme Toggle
                  Positioned(
                    top: 25,
                    right: 25,
                    child: Material(
                      color: cardBg, // var(--card-bg)
                      borderRadius: BorderRadius.circular(12),
                      elevation: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isDarkMode = !_isDarkMode;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            border: Border.all(color: inputBorder),
                            borderRadius: BorderRadius.circular(12),
                            // box-shadow: 0 4px 10px rgba(0,0,0,0.05);
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isDarkMode
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_round,
                            color: textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40), // padding: 40px
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 420,
                        ), // max-width: 420px
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo
                              Center(
                                child: Image.asset(
                                  'assets/jmclogo.png',
                                  width: 90, // max-width: 90px
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.school, size: 60),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Error Message (Alert)
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Title
                              Text(
                                _isFaculty ? 'Faculty Login' : 'Student Login',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 24, // Assumed size for h2
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Welcome back! Please enter your details.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14, // 0.9rem ~= 14.4px
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Role Switcher
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: 0.05,
                                  ), // rgba(0,0,0,0.05)
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    _buildRoleBtn(
                                      'Faculty',
                                      true,
                                      cardBg,
                                      activeThemeColor,
                                      textMuted,
                                    ),
                                    _buildRoleBtn(
                                      'Student',
                                      false,
                                      cardBg,
                                      activeThemeColor,
                                      textMuted,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ), // margin-bottom: 30px on .role-switcher
                              // Form
                              _buildLabel(
                                _isFaculty ? 'Username' : 'Student ID',
                                textPrimary,
                              ),
                              const SizedBox(height: 8),
                              _buildInput(
                                controller: _idController,
                                hintText: 'Enter ID number',
                                bgBody: bgBody,
                                cardBg: cardBg,
                                inputBorder: inputBorder,
                                activeTheme: activeThemeColor,
                                textPrimary: textPrimary,
                              ),
                              const SizedBox(height: 16), // mb-3 ~= 16px

                              _buildLabel('Password', textPrimary),
                              const SizedBox(height: 8),
                              _buildInput(
                                controller: _passwordController,
                                hintText: '••••••••',
                                isPassword: true,
                                bgBody: bgBody,
                                cardBg: cardBg,
                                inputBorder: inputBorder,
                                activeTheme: activeThemeColor,
                                textPrimary: textPrimary,
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: !_obscurePassword,
                                      onChanged: (val) {
                                        setState(() {
                                          _obscurePassword = !val!;
                                        });
                                      },
                                      activeColor: activeThemeColor,
                                      side: BorderSide(color: textMuted),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Show Password',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14, // small
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24), // mb-4

                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'SIGN IN',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 24), // mb-4
                              Text(
                                'OR SIGN IN WITH',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.8, // 0.8rem
                                  color: textMuted,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Google Button Placeholder (Visual only as per request)
                              Center(
                                child: Container(
                                  width: 340, // data-width="340"
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: inputBorder),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google Icon simulation
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.network(
                                          'https://developers.google.com/identity/images/g-logo.png',
                                          height: 20,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.g_mobiledata,
                                                    color: Colors.blue,
                                                  ),
                                        ),
                                      ),
                                      Text(
                                        'Sign in with Google',
                                        style: GoogleFonts.roboto(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBtn(
    String text,
    bool targetIsFaculty,
    Color cardBg,
    Color activeTheme,
    Color textMuted,
  ) {
    bool isActive = _isFaculty == targetIsFaculty;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isFaculty = targetIsFaculty;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isActive ? activeTheme : textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500, // fw-medium
        color: color,
        fontSize: 16,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required Color bgBody,
    required Color cardBg,
    required Color inputBorder,
    required Color activeTheme,
    required Color textPrimary,
    bool isPassword = false,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: hasFocus ? cardBg : bgBody,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFocus ? activeTheme : inputBorder,
                width: 1.5,
              ),
              boxShadow: hasFocus
                  ? [
                      // Remove focus shadow if not in design, but bootstrap has subtle one.
                      // CSS says: box-shadow: none; border-color: var(--active-theme);
                      // so we stick to border color change.
                    ]
                  : [],
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              style: GoogleFonts.poppins(color: textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  color: textPrimary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          );
        },
      ),
    );
  }
}
