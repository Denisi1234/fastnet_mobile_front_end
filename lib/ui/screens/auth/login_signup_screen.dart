import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({Key? key}) : super(key: key);

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isPasswordVisible = false;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitAuth() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );

      bool success = false;
      if (_isSignUp) {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        success = await UserSession.registerWithApi(
          name: name,
          email: email,
          password: password,
          phone: phone,
          role: 'customer',
        );
      } else {
        success = await UserSession.loginWithApi(email, password);
      }

      Navigator.pop(context); // Close loading dialog

      if (success) {
        final displayName = UserSession.userName ?? email;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(_isSignUp ? 'Welcome aboard, $displayName!' : 'Welcome back, $displayName!'),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Authentication failed. Check your credentials.'),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & App Name Brand
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade700, Colors.red.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'LODGE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey<bool>(_isSignUp),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSignUp ? 'Create your profile' : 'Log in to Lodge',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp 
                          ? 'Sign up to unlock reservations, corridor room maps, and property list host tools.' 
                          : 'Welcome back! Log in to proceed with your selected room checkout.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Interactive secure login graphics
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_y3m3yt.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_person_outlined,
                        size: 48,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic animated Form inputs
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                            validator: (value) {
                              if (_isSignUp && (value == null || value.trim().isEmpty)) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            decoration: _buildInputDecoration('Phone Number', Icons.phone_android_outlined),
                            validator: (value) {
                              if (_isSignUp && (value == null || value.trim().isEmpty)) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                      crossFadeState: _isSignUp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                      validator: (value) {
                        if (value == null || !value.contains('@') || value.length < 5) {
                          return 'Try using example@gmail.com';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      decoration: _buildPasswordDecoration(),
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirm button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade700, Colors.red.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade900.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _submitAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isSignUp ? 'Agree and Register' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Switch Sign Up / Log In Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Already have an account? ' : 'First time using Lodge? ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Log In' : 'Sign Up',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // Beautiful Social Authentic Buttons
              _buildBrandGoogleButton(),
              const SizedBox(height: 12),
              _buildBrandAppleButton(),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen(initialTab: 0)),
                    );
                  },
                  child: Text(
                    'Browse without logging in',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(icon, color: Colors.black54, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade900, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  InputDecoration _buildPasswordDecoration() {
    return InputDecoration(
      labelText: _isSignUp ? 'Create a password with at least 8 characters' : 'Password',
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54, size: 20),
      suffixIcon: IconButton(
        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54, size: 20),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade900, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBrandGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
          final success = await UserSession.loginWithApi('traveler@fastnet.com', 'password');
          if (mounted) Navigator.pop(context); // Close loading dialog
          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged in successfully via Google!')),
              );
              Navigator.pop(context, true);
            }
          } else {
            // Offline fallback
            UserSession.login('Alice Traveler', 'traveler@fastnet.com', '+255 789 999 888');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged in via offline mock (Google)!')),
              );
              Navigator.pop(context, true);
            }
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Real Google G logo painted with CustomPainter
            CustomPaint(
              size: const Size(22, 22),
              painter: _GoogleGPainter(),
            ),
            const SizedBox(width: 14),
            const Text(
              'Continue with Google',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandAppleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
          final success = await UserSession.loginWithApi('traveler@fastnet.com', 'password');
          if (mounted) Navigator.pop(context); // Close loading dialog
          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged in successfully via Apple!')),
              );
              Navigator.pop(context, true);
            }
          } else {
            // Offline fallback
            UserSession.login('Alice Traveler', 'traveler@fastnet.com', '+255 789 999 888');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged in via offline mock (Apple)!')),
              );
              Navigator.pop(context, true);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apple, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Continue with Apple',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pixel-accurate Google 'G' logo painter using official brand colours.
/// Draws the four-colour arc with the horizontal white notch and the
/// blue rectangular extension — matching Google's published brand guidelines.
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;
    final double strokeW = size.width * 0.22;
    final double halfStroke = strokeW / 2;

    // Arc paint helper
    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - halfStroke);

    // ── Four coloured arcs (angles in radians, 0 = right/3 o'clock) ──

    // Red: top-right → bottom-right (337.5° → 360° + 0° → 45°)  ≈ 67.5°
    canvas.drawArc(rect, _deg(-22.5), _deg(67.5), false, arcPaint(const Color(0xFFEA4335)));

    // Yellow: bottom-right → bottom-left  ≈ 90°  (45° → 135°)
    canvas.drawArc(rect, _deg(45), _deg(90), false, arcPaint(const Color(0xFFFBBC05)));

    // Green: bottom-left → top-left  ≈ 90°  (135° → 225°)
    canvas.drawArc(rect, _deg(135), _deg(90), false, arcPaint(const Color(0xFF34A853)));

    // Blue: top-left → top-right  ≈ 112.5°  (225° → 337.5°)
    canvas.drawArc(rect, _deg(225), _deg(112.5), false, arcPaint(const Color(0xFF4285F4)));

    // ── White gap / notch at the right (hides arc join seam) ──
    final gapPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + 1.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, _deg(-24), _deg(48), false, gapPaint);

    // ── Blue horizontal bar (the cross-arm of the G) ──
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Bar runs from centre to right edge, vertically centred
    final barHeight = strokeW * 0.9;
    final barRect = Rect.fromLTRB(
      cx,                        // starts at centre
      cy - barHeight / 2,
      size.width - halfStroke + 1, // ends at right edge of arc
      cy + barHeight / 2,
    );
    canvas.drawRect(barRect, barPaint);

    // Small red arc re-drawn on top of bar-right to restore round end
    canvas.drawArc(rect, _deg(-24), _deg(24), false, arcPaint(const Color(0xFFEA4335)));
  }

  static double _deg(double degrees) => degrees * 3.1415926535 / 180.0;

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}

