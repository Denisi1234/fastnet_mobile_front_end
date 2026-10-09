import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';


class SupportHelpScreen extends StatefulWidget {
  const SupportHelpScreen({Key? key}) : super(key: key);

  @override
  State<SupportHelpScreen> createState() => _SupportHelpScreenState();
}

class _SupportHelpScreenState extends State<SupportHelpScreen> {
  List<Map<String, dynamic>> _userTickets = [];
  Timer? _pollTimer;

  // Static list of FAQs for premium UI feel
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I check in to my lodge?',
      'answer': 'Check-in is confirmed by your host at the property. Open My Bookings, choose your stay, then Receipt, and show the QR code on your confirmation along with a valid photo ID matching the lead guest name. Standard check-in is from 2:00 PM — message the property ahead for early arrival.'
    },
    {
      'question': 'Can I request a refund for a cancellation?',
      'answer': 'Refund eligibility depends on the lodge cancellation policy. Please open a support ticket if your host canceled last minute or if there is a dispute.'
    },
    {
      'question': 'How secure are the payment methods?',
      'answer': 'Lodge uses industry-standard encryption for Visa/Mastercard payments and secure M-Pesa/Tigo Pesa carrier PIN validation for local mobile wallets.'
    },
    {
      'question': 'How do I request room service or cleaning?',
      'answer': 'Once checked in, you can unlock the "Lodge Services" dashboard to order local Swahili cuisine, request laundry, spa appointments, or call a taxi.'
    }
  ];

  @override
  void initState() {
    super.initState();
    if (UserSession.isLoggedIn) {
      _loadUserTickets();
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _loadUserTickets();
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserTickets() async {
    final tickets = await ApiService.fetchTickets();
    if (mounted) {
      setState(() {
        _userTickets = List<Map<String, dynamic>>.from(tickets);
      });
    }
  }

  void _triggerLogin() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
    );
    if (success == true) {
      _loadUserTickets();
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _loadUserTickets();
      });
    }
  }

  void _showCreateTicketDialog() {
    final formKey = GlobalKey<FormState>();
    String selectedIssue = 'Booking Dispute';
    final descController = TextEditingController();
    final msgController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Open Support Ticket',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    const SizedBox(height: 12),
                    
                    const Text('Select Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedIssue,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: ['Booking Dispute', 'Refund Request', 'Property Damage', 'Lodge Inquiry', 'Other'].map((issue) {
                        return DropdownMenuItem(value: issue, child: Text(issue));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedIssue = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Subject Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Briefly describe your request (e.g. Host canceled my booking or incorrect billing fee)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade900)),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Detailed Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: msgController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type your message to the support agent...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade900)),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please type your initial message' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade700, Colors.red.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            await ApiService.createTicket(
                              issue: selectedIssue,
                              description: descController.text.trim(),
                              initialMessage: msgController.text.trim(),
                            );
                            _loadUserTickets();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Support ticket opened successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Submit Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!UserSession.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Lodge Support & Help', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.headset_mic_outlined, size: 48, color: Colors.red.shade900),
              ),
              const SizedBox(height: 24),
              const Text('How can we help?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Text(
                'Log in to contact our customer support team, view active help requests, and open resolution cases.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.pink.shade700, Colors.red.shade900]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _triggerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Log In or Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Lodge Support & Help', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Cases Title
                  const Text('Active Cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  
                  if (_userTickets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No active support tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Open a ticket if you need help with your lodge bookings.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _userTickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = _userTickets[index];
                        final isOpen = t['status'] == 'Open';
                        final isProgress = t['status'] == 'In Progress';
                        Color statusBg = isOpen ? Colors.red.shade50 : (isProgress ? Colors.orange.shade50 : Colors.green.shade50);
                        Color statusText = isOpen ? Colors.red.shade700 : (isProgress ? Colors.orange.shade800 : Colors.green.shade700);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Text('#${t['id']}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(t['issue'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(t['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(t['status'].toUpperCase(), style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    Text('Last update: ${t['updated_at'] != null ? t['updated_at'].toString().substring(0, 10) : 'Today'}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SupportChatScreen(ticketId: t['id'] as int)),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 28),
                  
                  // FAQs
                  const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _faqs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final faq = _faqs[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ExpansionTile(
                          iconColor: Colors.red.shade900,
                          collapsedIconColor: Colors.black54,
                          title: Text(faq['question']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                              child: Text(faq['answer']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketDialog,
        backgroundColor: Colors.red.shade900,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text('Create Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  final int ticketId;
  const SupportChatScreen({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _ticket;
  Timer? _pollTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadTicketDetails();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    final tickets = await ApiService.fetchTickets();
    final ticket = tickets.firstWhere((t) => t['id'] == widget.ticketId, orElse: () => null);
    if (mounted && ticket != null) {
      setState(() {
        _ticket = Map<String, dynamic>.from(ticket);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await ApiService.sendTicketMessage(widget.ticketId, text);
    _loadTicketDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ticket == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
        body: Center(child: CircularProgressIndicator(color: Colors.red.shade900)),
      );
    }

    final ticket = _ticket!;
    final messages = ticket['messages'] as List<dynamic>;

    Color statusColor;
    if (ticket['status'] == 'Open') {
      statusColor = Colors.red.shade700;
    } else if (ticket['status'] == 'In Progress') {
      statusColor = Colors.orange.shade800;
    } else {
      statusColor = Colors.green.shade700;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ticket['id']} - Live Chat', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  ticket['status'],
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Issue Description banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.red.shade50.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade900, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description of Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(ticket['description'], style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['sender'] == 'User' || msg['sender'] == 'Host';
                final isSystem = msg['sender'] == 'System';

                if (isSystem) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Text(msg['text'], style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                    ),
                  );
                }

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(colors: [Colors.pink.shade700, Colors.red.shade900])
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(14),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        if (!isUser)
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg['time'],
                            style: TextStyle(color: isUser ? Colors.white70 : Colors.black38, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input bar
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
