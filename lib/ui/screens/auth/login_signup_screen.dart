import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/forgot_password_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';

/// Mobile layout of web `/login` + `/signup` (`carbon-auth-01/02.css`).
///
/// White card with the 4px blue top accent and square Carbon inputs on a
/// grey-10 page; logo + "Welcome Back!" / "Create New Account" titles with
/// cross-linking ledes; sign-in method switch (Password | Use a code) with
/// the real OTP request/verify flow; inline danger/success alerts and the
/// same validation copy as the web. Pops `true` on success (unchanged
/// contract for existing callers).
class LoginSignupScreen extends StatefulWidget {
  final bool initialSignUp;
  const LoginSignupScreen({super.key, this.initialSignUp = false});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  // Carbon v11 white-theme tokens (web `carbon-polish.css`).
  static const _ink = Color(0xFF161616);
  static const _gray70 = Color(0xFF525252);
  static const _gray60 = Color(0xFF6F6F6F);
  static const _gray50 = Color(0xFF8D8D8D);
  static const _gray30 = Color(0xFFC6C6C6);
  static const _gray20 = Color(0xFFE0E0E0);
  static const _gray10 = Color(0xFFF4F4F4);
  static const _blue = Color(0xFF0F62FE);
  static const _red = Color(0xFFDA1E28);
  static const _redBg = Color(0xFFFFF1F1);
  static const _green = Color(0xFF24A148);
  static const _greenBg = Color(0xFFDEFBE6);
  static const _infoBg = Color(0xFFE8F0FE);

  late bool _isSignUp;
  String _loginMode = 'password'; // password | code

  // Password pane.
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPwVisible = false;
  bool _loginBusy = false;

  // Code pane.
  final _contactCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  bool _otpSent = false;
  String _otpTarget = '';
  bool _codeBusy = false;
  bool _sendBusy = false;
  Timer? _resendTimer;
  int _resendLeft = 0;

  // Signup pane.
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _signupPwVisible = false;
  bool _signupBusy = false;

  // Inline alert (web `#login-alert-box` / `#signup-alert-box`).
  String? _alertKind; // danger | success | info
  String _alertMsg = '';
  String _infoEmail = '';
  final Set<String> _errFields = {};

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _contactCtrl.dispose();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _setAlert(String? kind, [String msg = '', String infoEmail = '']) {
    setState(() {
      _alertKind = kind;
      _alertMsg = msg;
      _infoEmail = infoEmail;
    });
  }

  void _switchAuthMode(bool signUp) {
    HapticFeedback.selectionClick();
    _resendTimer?.cancel();
    setState(() {
      _isSignUp = signUp;
      _loginMode = 'password';
      _otpSent = false;
      _resendLeft = 0;
      _alertKind = null;
      _alertMsg = '';
      _errFields.clear();
    });
  }

  void _switchLoginMode(String mode) {
    HapticFeedback.selectionClick();
    _resendTimer?.cancel();
    setState(() {
      _loginMode = mode;
      _otpSent = false;
      _resendLeft = 0;
      _alertKind = null;
      _alertMsg = '';
      _errFields.clear();
    });
  }

  static bool _validEmail(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);

  String _maskContact(String contact, String channel) {
    if (channel == 'sms') {
      final tail =
          contact.replaceAll(RegExp(r'\D'), '').split('').reversed.take(4).toList().reversed.join();
      return tail.isNotEmpty ? '••••••$tail' : 'your phone';
    }
    final at = contact.indexOf('@');
    if (at < 1) return 'your email';
    return '${contact[0]}•••${contact.substring(at)}';
  }

  void _backToContact() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _resendLeft = 0;
      _alertKind = null;
      _alertMsg = '';
    });
  }

  void _startResendCountdown([int seconds = 45]) {
    _resendTimer?.cancel();
    setState(() => _resendLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendLeft -= 1;
        if (_resendLeft <= 0) {
          _resendLeft = 0;
          t.cancel();
        }
      });
    });
  }

  Future<void> _finishSuccess(String message) async {
    _setAlert('success', message);
    HapticFeedback.mediumImpact();
    if (mounted) {
      Provider.of<UserSessionProvider>(context, listen: false)
          .updateSession();
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.pop(context, true);
  }

  // ── Password sign-in (web `web1-login-form`) ──

  Future<void> _submitPasswordLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPassCtrl.text;
    final errs = <String>{};
    if (!_validEmail(email)) errs.add('login-email');
    if (password.isEmpty) errs.add('login-password');
    setState(() {
      _errFields
        ..clear()
        ..addAll(errs);
    });
    if (errs.isNotEmpty) {
      _setAlert('danger',
          !_validEmail(email) ? 'Please enter a valid email address.' : 'Please enter your password.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _loginBusy = true;
      _alertKind = null;
    });
    final ok = await UserSession.loginWithApi(email, password);
    if (!mounted) return;
    setState(() => _loginBusy = false);
    if (ok) {
      await _finishSuccess('Login successful! Taking you there...');
    } else {
      _setAlert('danger',
          ApiService.lastError ?? 'Invalid email or password.');
    }
  }

  // ── Passwordless sign-in (web `web1-otp-form`) ──

  Future<void> _sendCode({bool resend = false}) async {
    final contact = _contactCtrl.text.trim();
    if (contact.isEmpty) {
      setState(() => _errFields.add('contact'));
      _setAlert('danger', 'Enter your mobile number or email.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (resend) {
        _codeBusy = true;
      } else {
        _sendBusy = true;
      }
      _alertKind = null;
    });
    final data = resend
        ? await ApiService.resendLoginOtp(contact)
        : await ApiService.requestLoginOtp(contact);
    if (!mounted) return;
    setState(() {
      _sendBusy = false;
      _codeBusy = false;
    });
    if (data != null) {
      final channel = (data['channel'] ?? 'email').toString();
      setState(() {
        _otpSent = true;
        _otpTarget = _maskContact(contact, channel);
        _codeCtrl.clear();
      });
      _setAlert('success', 'We sent a 6-digit code to $_otpTarget.');
      _startResendCountdown(
          (data['retry_after'] as num?)?.toInt() ?? 45);
      _codeFocus.requestFocus();
    } else {
      _setAlert('danger',
          ApiService.lastError ?? 'We could not send a code. Please try again.');
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _errFields.add('code'));
      _setAlert('danger', 'Enter all 6 digits of the code.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _codeBusy = true;
      _alertKind = null;
    });
    final ok =
        await UserSession.loginWithOtp(_contactCtrl.text.trim(), code);
    if (!mounted) return;
    setState(() => _codeBusy = false);
    if (ok) {
      await _finishSuccess('Signed in! Taking you there...');
    } else {
      setState(() => _codeCtrl.clear());
      _setAlert('danger',
          ApiService.lastError ?? 'That code is not correct. Please try again.');
      _codeFocus.requestFocus();
    }
  }

  // ── Signup (web `web1-signup-form`) ──

  Future<void> _submitSignup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text;
    String? fail;
    final errs = <String>{};
    if (name.length < 2) {
      fail = 'Please enter your full name.';
      errs.add('name');
    } else if (!_validEmail(email)) {
      fail = 'Please enter a valid email address.';
      errs.add('email');
    } else if (password.length < 8) {
      fail = 'Password must be at least 8 characters.';
      errs.add('password');
    }
    setState(() {
      _errFields
        ..clear()
        ..addAll(errs);
    });
    if (fail != null) {
      _setAlert('danger', fail);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _signupBusy = true;
      _alertKind = null;
    });
    final ok = await UserSession.registerWithApi(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: 'customer',
    );
    if (!mounted) return;
    setState(() => _signupBusy = false);
    if (ok) {
      await _finishSuccess('Registration successful! Taking you there...');
      return;
    }
    final msg = ApiService.lastError ?? 'Registration failed.';
    final lower = msg.toLowerCase();
    if (lower.contains('already been taken') ||
        lower.contains('already taken') ||
        lower.contains('already exists')) {
      _setAlert('info',
          'An account with $email is already registered. Simply sign in.',
          email);
    } else {
      _setAlert('danger', msg);
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gray10,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _ink),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: _blue, width: 4),
              left: BorderSide(color: _gray20),
              right: BorderSide(color: _gray20),
              bottom: BorderSide(color: _gray20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo lockup.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/fastnet_logo_icon.png',
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.bolt_rounded, color: _blue, size: 28),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'fastnetstays.com',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF202124),
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _isSignUp ? 'Create New Account' : 'Welcome Back!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.26,
                  color: _ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              _lede(),
              const SizedBox(height: 16),
              if (_isSignUp) _signupPane() else _loginPane(),
              const SizedBox(height: 16),
              // Copyright footer.
              const Center(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: _gray70),
                    children: [
                      TextSpan(text: '© FastNet Stays Ltd. '),
                      TextSpan(
                          text: 'Privacy',
                          style: TextStyle(color: _blue)),
                      TextSpan(text: ' · '),
                      TextSpan(
                          text: 'Terms', style: TextStyle(color: _blue)),
                      TextSpan(text: ' · '),
                      TextSpan(
                          text: 'Help', style: TextStyle(color: _blue)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lede line with the cross-link (web `/login` ↔ `/signup` links).
  Widget _lede() {
    if (_isSignUp) {
      return _linkRow(
        const TextSpan(
            text: 'Save stays and book instantly. Already a member? ',
            style: TextStyle(fontSize: 14, height: 1.6, color: _gray70)),
        'Sign in',
        () => _switchAuthMode(false),
      );
    }
    return _linkRow(
      const TextSpan(
          text: 'Are you new here? ',
          style: TextStyle(fontSize: 14, height: 1.6, color: _gray70)),
      'Create an account',
      () => _switchAuthMode(true),
    );
  }

  Widget _linkRow(TextSpan prefix, String link, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(children: [
          prefix,
          TextSpan(
              text: link,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: _blue)),
        ]),
      ),
    );
  }

  // ── Login pane (password | code switch) ──

  Widget _loginPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _methodSwitch(),
        const SizedBox(height: 16),
        if (_loginMode == 'password') ...[
          _alertBox(),
          _field(
            key: 'login-email',
            label: 'Email Address',
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
          ),
          const SizedBox(height: 12),
          _field(
            key: 'login-password',
            label: 'Password',
            controller: _loginPassCtrl,
            obscure: true,
            hint: '••••••••',
            onSubmitted: _submitPasswordLogin,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text('Forgot Password?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _blue)),
            ),
          ),
          const SizedBox(height: 16),
          _cta(
            label: 'Log In',
            busyLabel: 'Logging in...',
            busy: _loginBusy,
            onTap: _submitPasswordLogin,
          ),
        ] else ...[
          _alertBox(),
          if (!_otpSent) ...[
            const Text(
              "Sign in without a password. We'll text or email you a 6-digit code.",
              style: TextStyle(fontSize: 14, color: _gray70, height: 1.5),
            ),
            const SizedBox(height: 12),
            _field(
              key: 'contact',
              label: 'Mobile number or email',
              controller: _contactCtrl,
              keyboardType: TextInputType.text,
              hint: '0755 123 456 or you@example.com',
              onSubmitted: () => _sendCode(),
            ),
            const SizedBox(height: 16),
            _cta(
              label: 'Send code',
              busyLabel: 'Sending...',
              busy: _sendBusy,
              onTap: () => _sendCode(),
            ),
            const SizedBox(height: 12),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: _gray70, height: 1.5),
                children: [
                  TextSpan(text: 'By continuing you agree to our '),
                  TextSpan(
                      text: 'Terms',
                      style: TextStyle(color: _blue)),
                  TextSpan(text: ' and '),
                  TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: _blue)),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Enter the 6-digit code sent to $_otpTarget.',
              style: const TextStyle(
                  fontSize: 14, color: _gray70, height: 1.5),
            ),
            const SizedBox(height: 12),
            _codeField(),
            const SizedBox(height: 16),
            _cta(
              label: 'Verify & sign in',
              busyLabel: 'Verifying...',
              busy: _codeBusy,
              onTap: _verifyCode,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _backToContact,
                  child: const Text('Use a different number',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                          decoration: TextDecoration.underline)),
                ),
                GestureDetector(
                  onTap: _resendLeft > 0 ? null : () => _sendCode(resend: true),
                  child: Text(
                    _resendLeft > 0
                        ? 'Resend code in ${_resendLeft}s'
                        : 'Resend code',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _resendLeft > 0 ? _gray50 : _blue,
                      decoration: _resendLeft > 0
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  /// Segmented Password | Use a code switch (web `.cx-switch`).
  Widget _methodSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: _gray10,
        border: Border.all(color: _gray20),
      ),
      child: Row(
        children: [
          _switchBtn('password', 'Password'),
          _switchBtn('code', 'Use a code'),
        ],
      ),
    );
  }

  Widget _switchBtn(String mode, String label) {
    final active = _loginMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchLoginMode(mode),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                  color: active ? _blue : Colors.transparent,
                  width: 3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? _ink : _gray70,
            ),
          ),
        ),
      ),
    );
  }

  /// Single centered 6-digit box (web `.cx-code`).
  Widget _codeField() {
    final invalid = _errFields.contains('code');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification code',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: _gray70)),
        const SizedBox(height: 6),
        TextField(
          controller: _codeCtrl,
          focusNode: _codeFocus,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 10,
            color: _ink,
            height: 1.4,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: const TextStyle(color: _gray50, letterSpacing: 10),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _gray30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide:
                  BorderSide(color: invalid ? _red : _gray30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                  color: invalid ? _red : _blue, width: 2),
            ),
          ),
          onChanged: (v) {
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (digits.length > 6) {
              _codeCtrl.text = digits.substring(0, 6);
              _codeCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _codeCtrl.text.length));
            } else if (v != digits) {
              _codeCtrl.text = digits;
              _codeCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: digits.length));
            }
            if (invalid && digits.isNotEmpty) {
              setState(() => _errFields.remove('code'));
            }
            if (digits.length == 6) _verifyCode();
          },
        ),
      ],
    );
  }

  // ── Signup pane (web `web1-signup-form`) ──

  Widget _signupPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alertBox(),
        _field(
          key: 'name',
          label: 'Full Name',
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 12),
        _field(
          key: 'email',
          label: 'Email Address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _field(
          key: 'phone',
          label: 'Phone Number (Optional)',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _field(
          key: 'password',
          label: 'Enter Password',
          controller: _passCtrl,
          obscure: true,
          onSubmitted: _submitSignup,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Minimum 8 characters.',
              style: TextStyle(fontSize: 12, color: _gray70)),
        ),
        const SizedBox(height: 16),
        _cta(
          label: 'Create An Account',
          busyLabel: 'Creating Account...',
          busy: _signupBusy,
          onTap: _submitSignup,
        ),
      ],
    );
  }

  // ── Shared Carbon pieces ──

  /// Inline form alert (web `.alert-danger` / `.alert-success` + the
  /// already-registered info panel).
  Widget _alertBox() {
    if (_alertKind == null) return const SizedBox.shrink();
    if (_alertKind == 'info') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: _infoBg,
          border: Border(
            left: BorderSide(color: _blue, width: 3),
            top: BorderSide(color: _gray20),
            right: BorderSide(color: _gray20),
            bottom: BorderSide(color: _gray20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You already have an account!',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
            const SizedBox(height: 4),
            Text(
              'An account with $_infoEmail is already registered. Simply sign in.',
              style: const TextStyle(
                  fontSize: 13.5, height: 1.4, color: _ink),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _emailCtrl.clear();
                _loginEmailCtrl.text = _infoEmail;
                _switchAuthMode(false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                color: _blue,
                child: const Text('Sign in instead →',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
    final danger = _alertKind == 'danger';
    final edge = danger ? _red : _green;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger ? _redBg : _greenBg,
        border: Border(
          left: BorderSide(color: edge, width: 3),
          top: const BorderSide(color: _gray20),
          right: const BorderSide(color: _gray20),
          bottom: const BorderSide(color: _gray20),
        ),
      ),
      child: Text(
        _alertMsg,
        style: const TextStyle(fontSize: 13, color: _ink, height: 1.4),
      ),
    );
  }

  /// Carbon boxed field with separate small-caps label (web `.form-label`
  /// + `.form-control`): square, 48px, 15px ink.
  Widget _field({
    required String key,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool obscure = false,
    VoidCallback? onSubmitted,
  }) {
    final invalid = _errFields.contains(key);
    final isPw = key == 'login-password' || key == 'password';
    final shown = key == 'login-password'
        ? _loginPwVisible
        : (key == 'password' ? _signupPwVisible : true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: _gray70)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure && !shown,
          style: const TextStyle(fontSize: 15, color: _ink, height: 1.4),
          textInputAction: onSubmitted == null
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: onSubmitted == null
              ? null
              : (_) => onSubmitted(),
          onChanged: (_) {
            if (invalid) setState(() => _errFields.remove(key));
            if (_alertKind != null) {
              setState(() {
                _alertKind = null;
                _alertMsg = '';
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 15, color: _gray50),
            suffixIcon: isPw
                ? GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (key == 'login-password') {
                          _loginPwVisible = !_loginPwVisible;
                        } else {
                          _signupPwVisible = !_signupPwVisible;
                        }
                      });
                    },
                    child: Container(
                      width: 24,
                      alignment: Alignment.center,
                      child: Icon(
                        shown
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: _gray60,
                      ),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: _gray30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide:
                  BorderSide(color: invalid ? _red : _gray30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                  color: invalid ? _red : _blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Carbon primary button (web `.cx-btn`): full-width 48px square blue,
  /// loading dots + label while busy, grey when disabled.
  Widget _cta({
    required String label,
    required String busyLabel,
    required bool busy,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _gray30,
          disabledForegroundColor: _gray70,
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _Dots(color: Colors.white),
                  const SizedBox(width: 10),
                  Text(busyLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Web `.p-dots` loading dots.
class _Dots extends StatefulWidget {
  final Color color;
  const _Dots({required this.color});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_ctrl.value * 3 - i * 0.5).clamp(0.0, 1.0));
            final scale = 0.5 + 0.5 * (0.5 - (t - 0.5).abs()) * 2;
            return Container(
              width: 6 * scale,
              height: 6 * scale,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.4 + 0.6 * t),
              ),
            );
          }),
        );
      },
    );
  }
}
