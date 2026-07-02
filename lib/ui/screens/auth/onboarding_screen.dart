import 'package:flutter/material.dart';
import 'package:airbnb_ui_clone/ui/screens/main_screen.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isReviewOnly;
  const OnboardingScreen({Key? key, this.isReviewOnly = false}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to LODGE',
      'subtitle': 'Discover authentic, curated stays across East Africa. Dodoma, Zanzibar, Dar es Salaam, and more are now at your fingertips.',
      'image': 'assets/images/house.jpeg',
    },
    {
      'title': 'Interactive Room Selection',
      'subtitle': 'Pick your preferred room directly from visual floor maps. RED is booked, WHITE is available, BLUE is yours.',
      'image': 'assets/images/room.webp',
    },
    {
      'title': 'Secure Local Payments',
      'subtitle': 'Easily pay using Tanzanian mobile wallets like M-Pesa, Tigo Pesa, Halopesa, or credit cards with full PIN & OTP simulation.',
      'image': 'assets/images/house2.webp',
    },
    {
      'title': 'Premium In-Stay Services',
      'subtitle': 'Order Swahili delicacies via Room Service, chat with our Digital Concierge, request laundry, and check out instantly from the app.',
      'image': 'assets/images/house4.webp',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() {
    if (widget.isReviewOnly) {
      Navigator.pop(context);
    } else {
      UserSession.hasSeenOnboarding = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['subtitle']!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 140),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Header Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _onFinish,
              child: Text(
                widget.isReviewOnly ? 'CLOSE' : 'SKIP',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),

          // Bottom Navigation Row (Dots & Button)
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
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

                // Next / Get Started Button
                GestureDetector(
                  onTap: () {
                    if (_currentPage == _slides.length - 1) {
                      _onFinish();
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
                          color: Colors.pink.shade700.withValues(alpha: 0.3),
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
                              ? (widget.isReviewOnly ? 'Done' : 'Get Started')
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
