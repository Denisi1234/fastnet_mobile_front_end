import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/host/host_dashboard.dart';

class HostOnboardingScreen extends StatefulWidget {
  const HostOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<HostOnboardingScreen> createState() => _HostOnboardingScreenState();
}

class _HostOnboardingScreenState extends State<HostOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'List Your Property on Fastnet',
      'subtitle': 'Join thousands of hosts in East Africa earning steady income. Reach vacationers, corporate clients, and budget travelers instantly.',
      'image': 'assets/images/house.jpeg',
      'bullets': [
        'Free to list, minimal commission fees',
        'Direct connection to millions of active guests',
        'Complete control over your pricing and availability'
      ]
    },
    {
      'title': 'Visual Lodge Management Tools',
      'subtitle': 'Manage your check-ins and room layouts with state-of-the-art interactive corridor views and simple scheduling tools.',
      'image': 'assets/images/room.webp',
      'bullets': [
        'Real-time color-coded room maps (red for booked, white for free)',
        'Assign housekeeping and reception staff roles instantly',
        'Built-in secure messenger for guest inquiries'
      ]
    },
    {
      'title': 'Track Income & Growth Insights',
      'subtitle': 'Keep track of every shilling with our automated financial dashboard. Get paid securely through M-Pesa, Tigo Pesa, or direct bank transfer.',
      'image': 'assets/images/house2.webp',
      'bullets': [
        'Detailed monthly earnings reports and PDF statements',
        'Instant payouts with automatic commission deductions',
        'Dynamic occupancy and pricing recommendations'
      ]
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleAction() async {
    if (!UserSession.isLoggedIn) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
      if (loggedIn == true && UserSession.isLoggedIn) {
        UserSession.hasSeenHostOnboarding = true;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HostDashboard()),
          );
        }
      }
    } else {
      UserSession.hasSeenHostOnboarding = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HostDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Images and overlays
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, idx) {
              final slide = _slides[idx];
              final List<String> bullets = slide['bullets'];

              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slide['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.red.shade900,
                      child: const Icon(Icons.home, color: Colors.white, size: 80),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide['subtitle']!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Column(
                            children: bullets.map((bullet) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.pinkAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        bullet,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white90,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 120), // Leave room for indicator / buttons
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Header Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom Control Bar
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Slide Indicators (Dots)
                Row(
                  children: List.generate(_slides.length, (idx) {
                    final isSelected = _currentPage == idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: isSelected ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pinkAccent : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Action Button
                GestureDetector(
                  onTap: () {
                    if (_currentPage == _slides.length - 1) {
                      _handleAction();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade700, Colors.red.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.shade700.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1
                              ? (UserSession.isLoggedIn
                                  ? 'Get Started'
                                  : 'Login & Register')
                              : 'Next',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
