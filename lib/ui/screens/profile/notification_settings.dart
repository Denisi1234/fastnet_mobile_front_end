import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _smsConfirmations = true;
  bool _conciergeAlerts = true;
  bool _supportSyncAlerts = true;
  bool _marketingPromos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notification Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Customize which stay updates and messaging alerts you wish to receive.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 24),

            _buildSwitchTile(
              title: 'SMS Stays Confirmation',
              subtitle: 'Receive instant booking codes and payment validation alerts via SMS.',
              value: _smsConfirmations,
              onChanged: (val) {
                setState(() {
                  _smsConfirmations = val;
                });
              },
            ),
            const Divider(height: 32),

            _buildSwitchTile(
              title: 'Concierge Live Message',
              subtitle: 'Get alerts when the Digital Concierge or room service desk replies.',
              value: _conciergeAlerts,
              onChanged: (val) {
                setState(() {
                  _conciergeAlerts = val;
                });
              },
            ),
            const Divider(height: 32),

            _buildSwitchTile(
              title: 'Support Helpdesk Sync',
              subtitle: 'Receive instant notifications when back-office staff respond to support tickets.',
              value: _supportSyncAlerts,
              onChanged: (val) {
                setState(() {
                  _supportSyncAlerts = val;
                });
              },
            ),
            const Divider(height: 32),

            _buildSwitchTile(
              title: 'Marketing Promos',
              subtitle: 'Get customized discounts and seasonal lodge promotions in East Africa.',
              value: _marketingPromos,
              onChanged: (val) {
                setState(() {
                  _marketingPromos = val;
                });
              },
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings saved successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Notification Settings', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeThumbColor: Colors.red.shade900,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
