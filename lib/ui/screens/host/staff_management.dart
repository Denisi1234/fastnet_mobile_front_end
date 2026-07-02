import 'package:flutter/material.dart';

class StaffManagement extends StatefulWidget {
  const StaffManagement({Key? key}) : super(key: key);

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  final List<Map<String, String>> _staffList = [
    {'name': 'Juma Hamis', 'role': 'Housekeeper', 'phone': '+255 784 111 222', 'status': 'On-Duty', 'room': 'None'},
    {'name': 'Neema Mariam', 'role': 'Receptionist', 'phone': '+255 754 333 444', 'status': 'On-Duty', 'room': 'Front Desk'},
    {'name': 'Ally Salim', 'role': 'Maintenance', 'phone': '+255 712 555 666', 'status': 'Off-Duty', 'room': 'None'},
  ];

  void _addStaffDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Housekeeper';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Staff Full Name', hintText: 'e.g. Juma Hamis'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. +255 784 111 222'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Staff Role'),
                      items: ['Housekeeper', 'Receptionist', 'Maintenance', 'Manager'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedRole = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _staffList.add({
                          'name': nameController.text.trim(),
                          'role': selectedRole,
                          'phone': phoneController.text.trim(),
                          'status': 'Off-Duty',
                          'room': 'None',
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${nameController.text.trim()} added to staff roster.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                  child: const Text('Add Staff', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _assignTask(Map<String, String> staff) {
    final roomController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Assign ${staff['name']}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign this ${staff['role']} to clean or maintain a specific Room Number:'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: roomController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Room Number', hintText: 'e.g. 101 or 204'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter room number' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    staff['status'] = 'On-Duty';
                    staff['room'] = 'Room ${roomController.text.trim()}';
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${staff['name']} has been assigned to ${staff['room']}.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              child: const Text('Assign Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _toggleDutyStatus(Map<String, String> staff) {
    setState(() {
      if (staff['status'] == 'On-Duty') {
        staff['status'] = 'Off-Duty';
        staff['room'] = 'None';
      } else {
        staff['status'] = 'On-Duty';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${staff['name']} status toggled to ${staff['status']}.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Staff Roster', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _staffList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final staff = _staffList[index];
          final isHousekeeper = staff['role'] == 'Housekeeper' || staff['role'] == 'Maintenance';
          final isOnDuty = staff['status'] == 'On-Duty';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(staff['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Text(
                          staff['status']!.toUpperCase(),
                          style: TextStyle(
                            color: isOnDuty ? Colors.green.shade700 : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Switch(
                          value: isOnDuty,
                          activeThumbColor: Colors.green,
                          onChanged: (_) => _toggleDutyStatus(staff),
                        )
                      ],
                    )
                  ],
                ),
                Text('Role: ${staff['role']}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(staff['phone']!, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Active Assign: ${staff['room']}', style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
                if (isHousekeeper) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _assignTask(staff),
                          icon: const Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.black87),
                          label: const Text('Assign Room Task', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaffDialog,
        backgroundColor: Colors.red.shade900,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Invite Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
