import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/shimmer_widget.dart';

class StaffManagement extends StatefulWidget {
  const StaffManagement({Key? key}) : super(key: key);

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final list = await ApiService.fetchStaff();
    if (mounted) {
      setState(() {
        _staffList = list.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
      });
    }
  }

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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final role = selectedRole;
                      
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      
                      final result = await ApiService.addStaff(name: name, role: role, phone: phone);
                      if (result != null) {
                        await _loadStaff();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to staff roster.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        await _loadStaff();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to add staff member.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  void _assignTask(Map<String, dynamic> staff) {
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final roomNum = roomController.text.trim();
                  
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  final result = await ApiService.updateStaff(staff['id'], {
                    'status': 'On-Duty',
                    'room': 'Room $roomNum',
                  });
                  
                  if (result != null) {
                    await _loadStaff();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${staff['name']} has been assigned to Room $roomNum.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    await _loadStaff();
                  }
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

  void _toggleDutyStatus(Map<String, dynamic> staff) async {
    final nextStatus = staff['status'] == 'On-Duty' ? 'Off-Duty' : 'On-Duty';
    
    setState(() => _isLoading = true);
    final result = await ApiService.updateStaff(staff['id'], {
      'status': nextStatus,
      if (nextStatus == 'Off-Duty') 'room': 'None',
    });
    
    if (result != null) {
      await _loadStaff();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${staff['name']} status toggled to $nextStatus.'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      await _loadStaff();
    }
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
      body: _isLoading
          ? ListView.builder(
              itemCount: 4,
              padding: const EdgeInsets.only(top: 20),
              itemBuilder: (context, index) => const SkeletonCard(height: 100),
            )
          : _staffList.isEmpty
              ? const Center(child: Text('No staff members registered.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
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
