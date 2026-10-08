import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';

/// Mobile layout matching the Carbon auth surface (`carbon-auth-01/02.css`):
/// grey-10 page, white square card with the 4px blue top accent, boxed
/// 48px inputs, square blue CTA, inline danger/success alerts.
///
/// 3 steps: Email → 6-digit code (verified against real `POST /verify-otp`)
/// → New password (backend requires min 8, `POST /reset-password`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _ink = Color(0xFF161616);
  static const _gray70 = Color(0xFF525252);
  static const _gray30 = Color(0xFFC6C6C6);
  static const _gray20 = Color(0xFFE0E0E0);
  static const _gray10 = Color(0xFFF4F4F4);
  static const _blue = Color(0xFF0F62FE);
  static const _red = Color(0xFFDA1E28);
  static const _redBg = Color(0xFFFFF1F1);
  static const _green = Color(0xFF24A148);
  static const _greenBg = Color(0xFFDEFBE6);

  // 0 = Email, 1 = OTP, 2 = New Password
  int _step = 0;

  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  String _email = '';
  String? _alertKind; // danger | success
  String _alertMsg = '';

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join();

  void _setAlert(String? kind, [String msg = '']) {
    setState(() {
      _alertKind = kind;
      _alertMsg = msg;
    });
  }

  // ── Step actions ─────────────────────────────────────────────────────────

  Future<void> _onSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _setAlert('danger', 'Please enter a valid email address.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _alertKind = null;
    });
    await ApiService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);
    // Proceed regardless (UX: don't reveal whether email exists).
    _email = email;
    setState(() => _step = 1);
    _setAlert('success', 'A 6-digit code has been sent to $email');
  }

  Future<void> _onVerifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      _setAlert('danger', 'Please enter all 6 digits of the code.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _alertKind = null;
    });
    final res = await ApiService.verifyResetOtp(_email, otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res != null) {
      setState(() => _step = 2);
      _setAlert('success', 'Code confirmed. Choose a new password.');
    } else {
      _setAlert('danger',
          ApiService.lastError ?? 'Invalid verification code.');
    }
  }

  Future<void> _onResendCode() async {
    HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _alertKind = null;
    });
    await ApiService.forgotPassword(_email);
    if (!mounted) return;
    setState(() => _loading = false);
    for (final c in _otpControllers) {
      c.clear();
    }
    _setAlert('success', 'A new code has been sent to $_email');
    _otpFocusNodes.first.requestFocus();
  }

  Future<void> _onResetPassword() async {
    final pwd = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (pwd.length < 8) {
      _setAlert('danger', 'Password must be at least 8 characters.');
      return;
    }
    if (pwd != confirm) {
      _setAlert('danger', 'Passwords do not match.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _alertKind = null;
    });
    final res =
        await ApiService.resetPassword(_email, _otpValue, pwd);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res != null) {
      _setAlert('success',
          'Your password has been reset. You can now sign in.');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } else {
      _setAlert('danger',
          ApiService.lastError ?? 'Could not reset the password.');
    }
  }

  // ── Shared Carbon pieces ─────────────────────────────────────────────────

  Widget _alertBox() {
    if (_alertKind == null) return const SizedBox.shrink();
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

  Widget _stepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: isActive ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isDone || isActive ? _blue : _gray20,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (i < 2)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 36,
                height: 2,
                color: isDone ? _blue : _gray20,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        );
      }),
    );
  }

  Widget _otpField(int index) {
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: _ink),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: _gray30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: _blue, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          if (_alertKind != null) {
            setState(() {
              _alertKind = null;
              _alertMsg = '';
            });
          }
        },
      ),
    );
  }

  InputDecoration _decoration({String? label, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _gray70, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: _gray30),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: _blue, width: 2),
      ),
      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _gray30,
          disabledForegroundColor: _gray70,
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ── Steps ────────────────────────────────────────────────────────────────

  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alertBox(),
        const Text(
          'Forgot your password?',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w600, color: _ink, height: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the email address associated with your account and we\'ll send you a reset code.',
          style: TextStyle(color: _gray70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Text('Email Address',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: _gray70)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 15, color: _ink),
          decoration:
              _decoration().copyWith(hintText: 'you@example.com'),
        ),
        const SizedBox(height: 16),
        _primaryButton('Send Reset Code', _onSendCode),
      ],
    );
  }

  Widget _buildStepOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alertBox(),
        const Text(
          'Enter verification code',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w600, color: _ink, height: 1.2),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
                color: _gray70, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _email,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, _otpField),
        ),
        const SizedBox(height: 16),
        _primaryButton('Verify Code', _onVerifyOtp),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _loading ? null : _onResendCode,
            child: const Text(
              'Resend code',
              style: TextStyle(
                color: _blue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alertBox(),
        const Text(
          'Create new password',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w600, color: _ink, height: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a strong password that you haven\'t used before.',
          style: TextStyle(color: _gray70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Text('New Password',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: _gray70)),
        const SizedBox(height: 6),
        TextField(
          controller: _newPasswordController,
          obscureText: !_passwordVisible,
          style: const TextStyle(fontSize: 15, color: _ink),
          decoration: _decoration(
              suffix: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _gray70,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              )),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Minimum 8 characters.',
              style: TextStyle(fontSize: 12, color: _gray70)),
        ),
        const SizedBox(height: 12),
        const Text('Confirm New Password',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
                color: _gray70)),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_confirmVisible,
          style: const TextStyle(fontSize: 15, color: _ink),
          decoration: _decoration(
              suffix: IconButton(
                icon: Icon(
                  _confirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _gray70,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
              )),
        ),
        const SizedBox(height: 16),
        _primaryButton('Reset Password', _onResetPassword),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildStepEmail(),
      _buildStepOtp(),
      _buildStepNewPassword(),
    ];

    return Scaffold(
      backgroundColor: _gray10,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
              color: _ink, fontWeight: FontWeight.w600, fontSize: 18),
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
              _stepDots(),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: _gray20,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_blue),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Step ${_step + 1} of 3',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _blue,
                  letterSpacing: 0.24,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_step),
                  child: steps[_step],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
