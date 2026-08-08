import 'package:flutter/material.dart';

class FullWebsiteView extends StatefulWidget {
  final dynamic destinations;
  final String? currentLocation;
  final Function(dynamic)? onDestinationTap;

  const FullWebsiteView({
    Key? key,
    this.destinations,
    this.currentLocation,
    this.onDestinationTap,
  }) : super(key: key);

  @override
  State<FullWebsiteView> createState() => _FullWebsiteViewState();
}

class _FullWebsiteViewState extends State<FullWebsiteView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sticky Top Header Bar ───────────────────────────────────────────
        _buildStickyHeader(context),

        // ── Scrollable Body Content ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. App Showcase Hero Section (Vibrant Blue Background - Extra Tall)
                _buildAppShowcaseHero(context),

                // 2. Download App Today Section
                _buildDownloadAppSection(context),

                // 3. Benefits / Features Section
                _buildBenefitsSection(context),

                // 4. Footer
                _buildWebFooter(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STICKY TOP HEADER BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStickyHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
        final hPad = isMobile ? 16.0 : (isTablet ? 28.0 : 40.0);

        return Container(
          color: const Color(0xFF2563EB), // Same Vibrant Blue
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // App Decorated Word Logo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'FASTNET',
                            style: TextStyle(
                              fontSize: isMobile ? 18.0 : 24.0,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'STAYS',
                            style: TextStyle(
                              fontSize: isMobile ? 18.0 : 24.0,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF5252),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: '.com',
                            style: TextStyle(
                              fontSize: isMobile ? 12.0 : 15.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _HeroDot(color: const Color(0xFFFF5252), size: isMobile ? 12.0 : 16.0, marginRight: isMobile ? 5.0 : 7.0),
                        _HeroDot(color: const Color(0xFFFF9800), size: isMobile ? 12.0 : 16.0, marginRight: isMobile ? 5.0 : 7.0),
                        _HeroDot(color: const Color(0xFFFFEB3B), size: isMobile ? 12.0 : 16.0, marginRight: isMobile ? 5.0 : 7.0),
                        _HeroDot(color: const Color(0xFF4CAF50), size: isMobile ? 12.0 : 16.0, marginRight: isMobile ? 5.0 : 7.0),
                        _HeroDot(color: const Color(0xFF2196F3), size: isMobile ? 12.0 : 16.0, marginRight: 0),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Get Your App on PlayStore Image Asset
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/GET_YOUR_APP_ON_PLAYSTORE.png',
                    height: isMobile ? 34.0 : 46.0,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Get the App', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  1. APP SHOWCASE HERO SECTION (INCREASED HEIGHT & SPACING)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAppShowcaseHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
        final titleFontSize = isMobile ? 30.0 : (isTablet ? 40.0 : 52.0);
        final phoneWidth = isMobile ? 180.0 : (isTablet ? 210.0 : 250.0);
        final phoneHeight = isMobile ? 340.0 : (isTablet ? 390.0 : 460.0);

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB), // Vibrant Blue
          ),
          child: Column(
            children: [
              // Extra top spacing below sticky header to drop down hero text
              SizedBox(height: isMobile ? 48.0 : 80.0),

              // Sub-tagline
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 24, height: 2, color: Colors.yellowAccent),
                  const SizedBox(width: 10),
                  Text(
                    'The Best Stays Booking App',
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 14.0 : 17.0, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25),
                    children: const [
                      TextSpan(text: 'Your Ultimate Stays\n'),
                      TextSpan(
                        text: 'Booking',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.yellowAccent,
                          decorationThickness: 3.5,
                        ),
                      ),
                      TextSpan(text: ' Solution!'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isMobile ? 36.0 : 54.0),

              // Mockup Phones Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPhoneFrame('assets/images/app_screen_1.jpeg', 'Search Results', phoneWidth, phoneHeight),
                      const SizedBox(width: 16),
                      _buildPhoneFrame('assets/images/app_screen_2.jpeg', 'View Property by Map', phoneWidth, phoneHeight),
                      const SizedBox(width: 16),
                      _buildPhoneFrame('assets/images/app_screen_3.jpeg', 'Complete Payment', phoneWidth, phoneHeight),
                    ],
                  ),
                ),
              ),

              // Extra bottom spacing to give the blue container significant height
              SizedBox(height: isMobile ? 48.0 : 72.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneFrame(String imagePath, String caption, [double width = 240, double height = 440]) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.phone_android, size: 48, color: Colors.grey),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  2. DOWNLOAD APP SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDownloadAppSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final hPad = isMobile ? 20.0 : 60.0;
        final vPad = isMobile ? 40.0 : 72.0;

        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Wrap(
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 32,
            runSpacing: 32,
            children: [
              // Left Text & Stats
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 450),
                child: Column(
                  crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    RichText(
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      text: TextSpan(
                        style: TextStyle(fontSize: isMobile ? 26.0 : 36.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        children: const [
                          TextSpan(text: 'Download Our '),
                          TextSpan(text: 'Stays\nBooking ', style: TextStyle(color: Color(0xFF2563EB))),
                          TextSpan(text: 'App Today!'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Book your favorite stays effortlessly anywhere across Tanzania.',
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ],
                ),
              ),

              // Right: Get It On Google Play Badge
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/GET_YOUR_APP_ON_PLAYSTORE.png',
                  height: isMobile ? 56.0 : 72.0,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shop, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text('Get it on Google Play', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  3. BENEFITS SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBenefitsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final hPad = isMobile ? 20.0 : 60.0;

        return Container(
          color: const Color(0xFFF1F5F9),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 16, height: 2, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Text('Benefits of Stays App', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: isMobile ? 24.0 : 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                  children: const [
                    TextSpan(text: 'Exclusive Benefits of '),
                    TextSpan(text: 'FastNet Stays', style: TextStyle(color: Color(0xFF2563EB))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  _benefitListItem(
                    number: '01',
                    color: const Color(0xFF2563EB),
                    title: 'Instant Confirmation',
                    desc: 'Book your stay and receive immediate confirmation with zero waiting time or delays.',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 20),
                  _benefitListItem(
                    number: '02',
                    color: const Color(0xFF059669),
                    title: 'Verified Host Listings',
                    desc: 'Every property is handpicked, quality audited, and verified before listing on FastNet Stays.',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 20),
                  _benefitListItem(
                    number: '03',
                    color: const Color(0xFF7C3AED),
                    title: 'Local Mobile Payments',
                    desc: 'Pay seamlessly with M-Pesa, Airtel Money, Tigo Pesa, Halopesa, or credit cards.',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 20),
                  _benefitListItem(
                    number: '04',
                    color: const Color(0xFFEA580C),
                    title: '24/7 Local Support',
                    desc: 'Dedicated Tanzanian customer support team ready to assist you any time day or night.',
                    isMobile: isMobile,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _benefitListItem({
    required String number,
    required Color color,
    required String title,
    required String desc,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 36 : 44,
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: isMobile ? 22 : 26,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 16 : 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  4. FOOTER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebFooter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;
        final hPad = isMobile ? 24.0 : 64.0;

        return Container(
          color: const Color(0xFFF5F7FA),
          padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterNavCol('Support', ['Contact Us']),
                    const SizedBox(height: 24),
                    _buildFooterNavCol('Terms', ['Privacy Notice', 'Terms of Service']),
                    const SizedBox(height: 24),
                    _buildFooterNavCol('Partners', ['Host portal login', 'Partner help', 'List your property']),
                    const SizedBox(height: 24),
                    _buildFooterNavCol('About', ['About fastnetstays.com', 'How We Work']),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFooterNavCol('Support', ['Contact Us'])),
                    Expanded(child: _buildFooterNavCol('Terms', ['Privacy Notice', 'Terms of Service'])),
                    Expanded(child: _buildFooterNavCol('Partners', ['Host portal login', 'Partner help', 'List your property'])),
                    Expanded(child: _buildFooterNavCol('About', ['About fastnetstays.com', 'How We Work'])),
                  ],
                ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Copyright © 2026 fastnetstays.com™. All rights reserved.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterNavCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        const SizedBox(height: 12),
        ...links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {},
              child: Text(
                link,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _HeroDot extends StatelessWidget {
  final Color color;
  final double size;
  final double marginRight;

  const _HeroDot({
    required this.color,
    this.size = 14.0,
    this.marginRight = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(right: marginRight),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
