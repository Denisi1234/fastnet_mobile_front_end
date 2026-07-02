import 'package:flutter/material.dart';
import 'manage_listings.dart';
import 'host_bookings.dart';
import 'add_property.dart';
import 'room_map_screen.dart';
import 'financial_reports.dart';
import 'staff_management.dart';
import 'host_messages.dart';

class HostDashboard extends StatelessWidget {
  const HostDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Lodge Management', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Earnings', 'TSh 1,250k', Icons.account_balance_wallet, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Active Bookings', '12', Icons.calendar_month, Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Properties', '4', Icons.home_work, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Pending Action', '2', Icons.warning_amber_rounded, Colors.red)),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildToolMenu(context, 'My Properties', 'Manage all your lodge listings', Icons.format_list_bulleted, const ManageListings()),
            _buildToolMenu(context, 'Add New Property', 'Create a new listing for your lodge', Icons.add_business, const AddProperty()),
            _buildToolMenu(context, 'Guest Bookings', 'View and manage all reservations', Icons.people_alt_outlined, const HostBookings()),
            _buildToolMenu(context, 'Room Mapping Map', 'Visual booking sheet (Red = Booked)', Icons.grid_view, const RoomMapScreen()),
            _buildToolMenu(context, 'Financial Reports', 'Track income and payouts', Icons.bar_chart, const FinancialReports()),
            _buildToolMenu(context, 'Staff Management', 'Assign roles and permissions', Icons.manage_accounts, const StaffManagement()),
            _buildToolMenu(context, 'Guest Messages', 'Chat with current and upcoming guests', Icons.forum_outlined, const HostMessagesScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildToolMenu(BuildContext context, String title, String subtitle, IconData icon, Widget? targetPage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.red.shade900),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          if (targetPage != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')));
          }
        },
      ),
    );
  }
}
