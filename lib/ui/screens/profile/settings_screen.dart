import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/personal_info.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/payments_payouts.dart';
import 'package:fastnet_mobile_front_end/ui/screens/profile/notification_settings.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Section 1: Account Settings
            _buildSectionHeader('Account Details'),
            _buildSettingsGroup([
              _buildSettingsTile(
                Icons.person_outline,
                'Personal Information',
                'Update your name, email, and phone number',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                  );
                },
              ),
              _buildSettingsDivider(),
              _buildSettingsTile(
                Icons.payment_outlined,
                'Payments & Payouts',
                'Manage payment methods, transactions, and payouts',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsPayoutsScreen()),
                  );
                },
              ),
              _buildSettingsDivider(),
              _buildSettingsTile(
                Icons.notifications_none_outlined,
                'Notifications',
                'Choose what notifications you receive and how',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Section 2: App Preferences
            _buildSectionHeader('App Preferences'),
            _buildSettingsGroup([
              _buildSettingsTile(
                Icons.info_outline,
                'App Walkthrough',
                'Review the introductory slides and features guide',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(isReviewOnly: true),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 30),
            Center(
              child: Text(
                'Version 1.0.0 (FASTNET)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String label,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black54),
      onTap: onTap,
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 20,
      endIndent: 20,
    );
  }
}
