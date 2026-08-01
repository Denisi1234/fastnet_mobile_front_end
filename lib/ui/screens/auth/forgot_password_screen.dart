import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // 0 = Email, 1 = OTP, 2 = New Password
  int _step = 0;

  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 6-digit OTP controllers
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  // Stored email for API calls
  String _email = '';

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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Step actions ─────────────────────────────────────────────────────────

  Future<void> _onSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.forgotPassword(email);
    setState(() => _loading = false);

    // We proceed regardless (UX: don't reveal whether email exists)
    _email = email;
    setState(() => _step = 1);
    _showSuccess('A 6-digit code has been sent to $email');
  }

  Future<void> _onVerifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      _showError('Please enter all 6 digits of the code.');
      return;
    }
    // In real app: verify OTP via API. Here we just move to step 2.
    setState(() => _step = 2);
  }

  Future<void> _onResetPassword() async {
    final pwd = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (pwd.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (pwd != confirm) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    await ApiService.resetPassword(_email, _otpValue, pwd);
    setState(() => _loading = false);

    _showSuccess('Password reset successfully! Please log in.');
    if (mounted) Navigator.pop(context);
  }

  // ── Progress dots ─────────────────────────────────────────────────────────

  Widget _buildStepDots() {
    final labels = ['Email', 'Verify Code', 'New Password'];
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
                color: isDone || isActive
                    ? Colors.red.shade900
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (i < 2)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 36,
                height: 2,
                color: isDone
                    ? Colors.red.shade900
                    : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        );
      }),
    );
  }

  // ── OTP field ─────────────────────────────────────────────────────────────

  Widget _buildOtpField(int index) {
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
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.red.shade900, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  // ── Input decoration ──────────────────────────────────────────────────────

  InputDecoration _buildDecoration(String label, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.black54, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, color: Colors.black54, size: 20),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Colors.red.shade900, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ── Step widgets ──────────────────────────────────────────────────────────

  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot your password?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email address associated with your account and we\'ll send you a reset code.',
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: _buildDecoration('Email Address', Icons.email_outlined),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton('Send Reset Code', _loading, _onSendCode),
      ],
    );
  }

  Widget _buildStepOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter verification code',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _email,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, _buildOtpField),
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton('Verify Code', _loading, _onVerifyOtp),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: Text(
              'Resend code',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
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
        Text(
          'Create new password',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a strong password that you haven\'t used before.',
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _newPasswordController,
          obscureText: !_passwordVisible,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: _buildDecoration('New Password', Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              )),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_confirmVisible,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: _buildDecoration(
              'Confirm New Password', Icons.lock_person_outlined,
              suffix: IconButton(
                icon: Icon(
                  _confirmVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _confirmVisible = !_confirmVisible),
              )),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
            'Reset Password', _loading, _onResetPassword),
      ],
    );
  }

  Widget _buildPrimaryButton(
      String label, bool loading, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade700, Colors.red.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade900.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: loading
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildStepEmail(),
      _buildStepOtp(),
      _buildStepNewPassword(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step dots
              _buildStepDots(),
              const SizedBox(height: 8),
              // Animated progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.red.shade900),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 32),

              // Step label
              Text(
                'Step ${_step + 1} of 3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Animated step content
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
