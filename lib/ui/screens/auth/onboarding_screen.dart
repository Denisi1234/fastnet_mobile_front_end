import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isReviewOnly;
  const OnboardingScreen({Key? key, this.isReviewOnly = false}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  double _pageOffset = 0.0;
  int _currentPage = 0;
  late final AnimationController _glowController;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to FastNet Stays',
      'subtitle': 'Discover authentic, curated stays across East Africa. Dodoma, Zanzibar, Dar es Salaam, and more are now at your fingertips.',
      'lottie': 'https://assets10.lottiefiles.com/packages/lf20_5n8y2lka.json',
      'image': 'assets/images/house.jpeg',
    },
    {
      'title': 'Interactive Room Selection',
      'subtitle': 'Pick your preferred room directly from visual floor maps. RED is booked, WHITE is available, BLUE is yours.',
      'lottie': 'https://assets9.lottiefiles.com/packages/lf20_k98vgibk.json',
      'image': 'assets/images/room.webp',
    },
    {
      'title': 'Secure Local Payments',
      'subtitle': 'Easily pay using Tanzanian mobile wallets like M-Pesa, Tigo Pesa, Halopesa, or credit cards with full PIN & OTP simulation.',
      'lottie': 'https://assets10.lottiefiles.com/packages/lf20_y3m3yt.json',
      'image': 'assets/images/house2.webp',
    },
    {
      'title': 'Premium In-Stay Services',
      'subtitle': 'Order Swahili delicacies via Room Service, chat with our Digital Concierge, request laundry, and check out instantly from the app.',
      'lottie': 'https://assets10.lottiefiles.com/packages/lf20_uz32bp9y.json',
      'image': 'assets/images/house4.webp',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The button glow is decorative, so it must not pulse indefinitely for
    // users who have asked the system to reduce motion.
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _glowController
        ..stop()
        ..value = 1.0;
    } else if (!_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onFinish() {
    if (widget.isReviewOnly) {
      Navigator.pop(context);
    } else {
      UserSession.setHasSeenOnboarding(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Parallax Images and Gradient Overlay PageView
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
              double percent = idx - _pageOffset;
              
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full screen background image with Parallax
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(-percent * size.width * 0.45, 0),
                      child: Transform.scale(
                        scale: 1.15 + (percent.abs() * -0.15),
                        child: Image.asset(
                          slide['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.red.shade900,
                            child: const Icon(Icons.home, color: Colors.white, size: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Dark Vignette/Gradient overlay for text legibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.85),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.4, 0.75, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  
                  // Text and Lottie content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Floating Lottie Animation
                          Expanded(
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(-percent * size.width * 0.7, percent.abs() * 50),
                                child: Transform.scale(
                                  scale: 1.0 - (percent.abs() * 0.15),
                                  child: SizedBox(
                                    height: size.height * 0.28,
                                    width: double.infinity,
                                    child: Lottie.network(
                                      slide['lottie']!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.home_work_outlined,
                                        color: Colors.white70,
                                        size: 80,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Slide Title
                          Transform.translate(
                            offset: Offset(percent * 300, 0),
                            child: Opacity(
                              opacity: (1.0 - percent.abs()).clamp(0.0, 1.0),
                              child: Text(
                                slide['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 14),
                          
                          // Slide Subtitle
                          Transform.translate(
                            offset: Offset(percent * 150, 0),
                            child: Opacity(
                              opacity: (1.0 - percent.abs()).clamp(0.0, 1.0),
                              child: Text(
                                slide['subtitle']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 15,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 100),
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
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: TextButton(
                onPressed: _onFinish,
                child: Text(
                  widget.isReviewOnly ? 'CLOSE' : 'SKIP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Row (Dots & Animated Button)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
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
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: isSelected ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pinkAccent : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Next / Get Started Button
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final isLastPage = _currentPage == _slides.length - 1;
                    
                    return GestureDetector(
                      onTap: () {
                        if (isLastPage) {
                          _onFinish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLastPage ? 32 : 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade700,
                              Colors.red.shade900,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.shade700.withOpacity(
                                isLastPage ? 0.4 + (_glowController.value * 0.2) : 0.3,
                              ),
                              blurRadius: isLastPage ? 12 + (_glowController.value * 6) : 8,
                              spreadRadius: isLastPage ? _glowController.value * 2 : 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                isLastPage
                                    ? (widget.isReviewOnly ? 'Done' : 'Get Started')
                                    : 'Next',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
