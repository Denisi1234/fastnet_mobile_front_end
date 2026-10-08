import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';

/// Mobile equivalent of web `/security`: shows the account email and
/// sends a password-reset email through the real backend endpoint
/// (`POST /forgot-password`) — same flow the web uses.
class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF007FAD);

  bool _sending = false;

  Future<void> _sendResetEmail() async {
    final email = (UserSession.userEmail ?? '').trim();
    if (email.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _sending = true);
    try {
      final res = await ApiService.forgotPassword(email);
      if (!mounted) return;
      _toast(res != null
          ? 'Password reset email sent to $email.'
          : 'Could not send the reset email. Please try again.');
    } catch (_) {
      if (mounted) {
        _toast('Could not send the reset email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'Account security',
          style: TextStyle(
              color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: !UserSession.isLoggedIn
          ? _loginGate()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Signed in as ${UserSession.userEmail ?? ''}',
                  style:
                      const TextStyle(fontSize: 14, color: _muted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We will email you a secure link to choose a new password. The link expires after a short time.',
                  style: TextStyle(
                      fontSize: 13.5, color: _muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFCBD5E1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5),
                          )
                        : const Text(
                            'Send password reset email',
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tip: never share your password or reset link with anyone. FastNet staff will never ask for them.',
                  style: TextStyle(
                      fontSize: 12.5, color: _muted, height: 1.5),
                ),
              ],
            ),
    );
  }

  Widget _loginGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 48, color: _teal),
            const SizedBox(height: 16),
            const Text('Sign in required',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
            const SizedBox(height: 8),
            const Text(
              'Sign in to manage your account security.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeSlidePageRoute(
                        page: const LoginSignupScreen()),
                  ).then((_) => setState(() {}));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log in or Sign up',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
