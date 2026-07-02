import 'dart:async';
import 'package:flutter/material.dart';

class HostMessagesScreen extends StatefulWidget {
  const HostMessagesScreen({Key? key}) : super(key: key);

  @override
  State<HostMessagesScreen> createState() => _HostMessagesScreenState();
}

class _HostMessagesScreenState extends State<HostMessagesScreen> {
  final List<Map<String, dynamic>> _threads = [
    {
      'guestName': 'Mariam K.',
      'lodgeName': 'Zanzibar Sunset Beach Villa',
      'avatar': 'assets/images/man2.jpeg',
      'lastMessage': 'Is check-in possible at 11 AM?',
      'time': '10 mins ago',
      'unread': true,
      'messages': [
        {'sender': 'guest', 'text': 'Hello, I booked the villa for next week!', 'time': '9:30 AM'},
        {'sender': 'host', 'text': 'Karibu! We are preparing the room for you.', 'time': '9:35 AM'},
        {'sender': 'guest', 'text': 'Is check-in possible at 11 AM?', 'time': '9:40 AM'},
      ]
    },
    {
      'guestName': 'Elias M.',
      'lodgeName': 'Kariakoo Budget Lodge',
      'avatar': 'assets/images/man.jpeg',
      'lastMessage': 'Thank you, the Wi-Fi was very fast.',
      'time': 'Yesterday',
      'unread': false,
      'messages': [
        {'sender': 'host', 'text': 'Hope you had a comfortable night!', 'time': 'Yesterday 8:00 AM'},
        {'sender': 'guest', 'text': 'Thank you, the Wi-Fi was very fast.', 'time': 'Yesterday 8:15 AM'},
      ]
    },
    {
      'guestName': 'Thomas L.',
      'lodgeName': 'Arusha Highlands Lodge',
      'avatar': 'assets/images/man.jpeg',
      'lastMessage': 'I have uploaded my passport verification.',
      'time': '3 days ago',
      'unread': false,
      'messages': [
        {'sender': 'guest', 'text': 'Do you require ID verification before check-in?', 'time': '3 days ago'},
        {'sender': 'host', 'text': 'Yes, please upload your passport or national ID.', 'time': '3 days ago'},
        {'sender': 'guest', 'text': 'I have uploaded my passport verification.', 'time': '3 days ago'},
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Guest Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _threads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(thread['avatar']),
                    radius: 24,
                  ),
                  if (thread['unread'])
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    thread['guestName'],
                    style: TextStyle(
                      fontWeight: thread['unread'] ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    thread['time'],
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread['lodgeName'],
                      style: TextStyle(color: Colors.red.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread['lastMessage'],
                      style: TextStyle(
                        color: thread['unread'] ? Colors.black87 : Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: thread['unread'] ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              onTap: () async {
                setState(() {
                  thread['unread'] = false;
                });
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(thread: thread),
                  ),
                );
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> thread;
  const ChatDetailScreen({Key? key, required this.thread}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        widget.thread['messages'].add({
          'sender': 'host',
          'text': text,
          'time': 'Just now',
        });
        widget.thread['lastMessage'] = text;
        widget.thread['time'] = 'Just now';
      });
      _messageController.clear();
      _scrollToBottom();

      // Trigger simulated guest reply after delay
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            const guestReply = 'Understood! Thank you for the quick response.';
            widget.thread['messages'].add({
              'sender': 'guest',
              'text': guestReply,
              'time': 'Just now',
            });
            widget.thread['lastMessage'] = guestReply;
            widget.thread['time'] = 'Just now';
          });
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> messages = List<Map<String, String>>.from(widget.thread['messages']);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.thread['guestName'],
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              widget.thread['lodgeName'],
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isHost = msg['sender'] == 'host';

                return Align(
                  alignment: isHost ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isHost ? Colors.red.shade900 : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isHost ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isHost ? Radius.zero : const Radius.circular(16),
                      ),
                      border: isHost ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isHost ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isHost ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time']!,
                          style: TextStyle(
                            color: isHost ? Colors.white70 : Colors.grey,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.red.shade900,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
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
