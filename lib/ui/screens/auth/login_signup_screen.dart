import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';
import 'package:flutter/material.dart';

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

  void _submitAuth() {
    if (_formKey.currentState!.validate()) {
      final name = _isSignUp ? _nameController.text.trim() : 'Elias John';
      final phone = _isSignUp ? _phoneController.text.trim() : '+255 712 345 678';
      final email = _emailController.text.trim();

      UserSession.login(name, email, phone);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(_isSignUp ? 'Welcome aboard, $name!' : 'Welcome back, $name!'),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
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

              // Headers
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
              const SizedBox(height: 32),

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
                          return 'Please enter a valid email address';
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
                  ],
                ),
              ),
              const SizedBox(height: 28),

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
      labelText: 'Password',
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
        onPressed: () {
          UserSession.login('Elias John', 'elias.john@domain.tz', '+255 712 345 678');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully via Google!')),
          );
          Navigator.pop(context, true);
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Mock Google Multi-colored G Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 12, color: Colors.blue),
                Container(width: 4, height: 12, color: Colors.red),
                Container(width: 4, height: 12, color: Colors.yellow.shade700),
                Container(width: 4, height: 12, color: Colors.green),
              ],
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
        onPressed: () {
          UserSession.login('Elias John', 'elias.john@domain.tz', '+255 712 345 678');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully via Apple!')),
          );
          Navigator.pop(context, true);
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
