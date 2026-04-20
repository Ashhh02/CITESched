import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showPasswordResetDialog(
  BuildContext context, {
  String? initialEmail,
  bool lockEmail = false,
  String title = 'Reset Password',
  String subtitle = 'Secure your account with a fresh password.',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PasswordResetDialog(
      initialEmail: initialEmail,
      lockEmail: lockEmail,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _PasswordResetDialog extends StatefulWidget {
  final String? initialEmail;
  final bool lockEmail;
  final String title;
  final String subtitle;

  const _PasswordResetDialog({
    required this.initialEmail,
    required this.lockEmail,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  dynamic _requestId;
  bool _isSubmitting = false;
  bool _isVerifying = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  bool get _hasRequestedReset => _requestId != null;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _requestResetErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('toomanyattempts')) {
      return 'Too many reset attempts were made. Please wait a few minutes before trying again.';
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return 'We could not reach the email service right now. Please try again shortly.';
    }
    return 'We could not start the password reset right now. Please try again later.';
  }

  String _finishResetErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('invalid')) {
      return 'The verification code is invalid. Please check the code and try again.';
    }
    if (raw.contains('expired')) {
      return 'This verification code has expired. Please request a new one.';
    }
    if (raw.contains('policyviolation')) {
      return 'The new password does not meet the password requirements.';
    }
    if (raw.contains('toomanyattempts')) {
      return 'Too many attempts were made. Please wait a few minutes before trying again.';
    }
    return 'We could not reset the password right now. Please try again later.';
  }

  Future<void> _requestReset({bool isResend = false}) async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email address first.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final requestId = await client.emailIdp.startPasswordReset(email: email);
      if (!mounted) return;
      setState(() {
        _requestId = requestId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isResend
                ? 'A new reset code was requested. If nothing arrives, check spam or the server console in local development.'
                : 'Password reset requested. If no code arrives, check spam or use Resend Code. In local development, the server may log the code.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF720045),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _requestResetErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeReset() async {
    final requestId = _requestId;
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (requestId == null) {
      setState(() {
        _errorMessage = 'Request a password reset first.';
      });
      return;
    }
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Enter the verification code from your email.';
      });
      return;
    }
    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Use at least 8 characters for your new password.';
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final finishToken = await client.emailIdp.verifyPasswordResetCode(
        passwordResetRequestId: requestId,
        verificationCode: code,
      );
      await client.emailIdp.finishPasswordReset(
        finishPasswordResetToken: finishToken,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password updated successfully. You can now sign in with the new password.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _finishResetErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bodyBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF0F172A);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.08);
    const accent = Color(0xFF720045);

    InputDecoration field({
      required String hint,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: textMuted.withValues(alpha: 0.8),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: accent, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: bodyBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF720045), width: 1.6),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF720045), Color(0xFFB5179E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasRequestedReset
                                ? 'Enter the verification code below. If you still do not receive an email, try Resend Code. In local development, the server may log the code.'
                                : 'Enter the email linked to your account and we will start the password recovery flow.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              height: 1.45,
                              color: textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Email Address',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    enabled:
                        !widget.lockEmail && !_isSubmitting && !_isVerifying,
                    keyboardType: TextInputType.emailAddress,
                    decoration: field(
                      hint: 'name@jmc.edu.ph',
                      icon: Icons.alternate_email_rounded,
                    ),
                    style: GoogleFonts.poppins(color: textPrimary),
                  ),
                  const SizedBox(height: 16),
                  if (_hasRequestedReset) ...[
                    Text(
                      'Verification Code',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      enabled: !_isVerifying,
                      decoration: field(
                        hint: 'Enter the code from your email',
                        icon: Icons.verified_user_rounded,
                      ),
                      style: GoogleFonts.poppins(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'No code yet? Check spam or request another one.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isSubmitting || _isVerifying
                              ? null
                              : () => _requestReset(isResend: true),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Resend Code',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Password',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      enabled: !_isVerifying,
                      obscureText: _obscurePassword,
                      decoration: field(
                        hint: 'At least 8 characters',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: textMuted,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(color: textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Password',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      enabled: !_isVerifying,
                      obscureText: _obscureConfirmPassword,
                      decoration: field(
                        hint: 'Re-enter your new password',
                        icon: Icons.password_rounded,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: textMuted,
                          ),
                        ),
                      ),
                      style: GoogleFonts.poppins(color: textPrimary),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSubmitting || _isVerifying
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting || _isVerifying
                              ? null
                              : _hasRequestedReset
                              ? _completeReset
                              : () => _requestReset(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: (_isSubmitting || _isVerifying)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _hasRequestedReset
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.send_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _hasRequestedReset
                                ? 'Update Password'
                                : 'Send Reset Code',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
