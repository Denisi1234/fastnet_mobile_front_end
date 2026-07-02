import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SupportService {
  static final SupportService instance = SupportService._internal();
  SupportService._internal();

  List<Map<String, dynamic>> _inMemoryTickets = [];
  bool _initialized = false;

  File get _dbFile {
    // Both apps run in separate subfolders of the workspace:
    // - airbnb_ui_clone-main/airbnb_ui_clone-main
    // - airbnb_ui_clone-main/admin_portal
    // We point to a shared db_tickets.json in the parent folder
    return File('../db_tickets.json');
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load initial mock tickets if file doesn't exist
    if (!kIsWeb) {
      try {
        if (!await _dbFile.exists()) {
          final initialData = _getInitialMockTickets();
          await _dbFile.writeAsString(jsonEncode(initialData), flush: true);
          _inMemoryTickets = initialData;
        } else {
          final content = await _dbFile.readAsString();
          _inMemoryTickets = List<Map<String, dynamic>>.from(jsonDecode(content));
        }
        return;
      } catch (e) {
        debugPrint('File DB Error: $e');
      }
    }

    // Web / Native fallback
    if (_inMemoryTickets.isEmpty) {
      _inMemoryTickets = _getInitialMockTickets();
    }
  }

  List<Map<String, dynamic>> _getInitialMockTickets() {
    return [
      {
        'id': '#1042',
        'user': 'Bob Jones',
        'role': 'Guest',
        'issue': 'Host canceled last minute',
        'status': 'Open',
        'date': '2 hours ago',
        'description': 'The host canceled my reservation just 2 hours before check-in. I am stranded at the airport and need immediate rebooking assistance or a full refund.',
        'messages': [
          {'sender': 'User', 'text': 'My reservation was canceled out of nowhere! Please help.', 'time': '2 hours ago'},
          {'sender': 'System', 'text': 'Reservation #TRIP-88491 canceled by host Bob Jones.', 'time': '2 hours ago'},
          {'sender': 'User', 'text': 'I need a place to stay tonight. Are there alternative listings nearby?', 'time': '1 hour ago'},
        ]
      },
      {
        'id': '#1041',
        'user': 'Alice Smith',
        'role': 'Host',
        'issue': 'Guest broke a window',
        'status': 'In Progress',
        'date': 'Yesterday',
        'description': 'During checkout today, I discovered that the living room window is shattered. The guest claims it was an accident but refuses to pay for repairs.',
        'messages': [
          {'sender': 'Host', 'text': 'The living room window is completely shattered. Here are the photos.', 'time': 'Yesterday'},
          {'sender': 'Agent', 'text': 'Thanks Alice. We have reached out to the guest to request reimbursement. We will update you shortly.', 'time': 'Yesterday'},
          {'sender': 'Host', 'text': 'Thank you, I appreciate the quick support.', 'time': '18 hours ago'},
        ]
      },
      {
        'id': '#1040',
        'user': 'Charlie Brown',
        'role': 'Guest',
        'issue': 'Refund request',
        'status': 'Resolved',
        'date': '3 days ago',
        'description': 'Requesting a refund for the cleaning fee. The apartment was not clean upon arrival; there was dust on the counter and trash in the bin.',
        'messages': [
          {'sender': 'User', 'text': 'The room was dirty, I want my cleaning fee refunded.', 'time': '3 days ago'},
          {'sender': 'Agent', 'text': 'We apologize for the inconvenience. We have processed a \$50 refund to your original payment method.', 'time': '2 days ago'},
          {'sender': 'User', 'text': 'Got it. Thank you!', 'time': '2 days ago'},
        ]
      },
    ];
  }

  Future<List<Map<String, dynamic>>> loadTickets() async {
    await init();
    if (!kIsWeb) {
      try {
        if (await _dbFile.exists()) {
          final content = await _dbFile.readAsString();
          _inMemoryTickets = List<Map<String, dynamic>>.from(jsonDecode(content));
        }
      } catch (e) {
        debugPrint('File Load Error: $e');
      }
    }
    return _inMemoryTickets;
  }

  Future<void> saveTickets(List<Map<String, dynamic>> tickets) async {
    _inMemoryTickets = tickets;
    if (!kIsWeb) {
      try {
        await _dbFile.writeAsString(jsonEncode(tickets), flush: true);
      } catch (e) {
        debugPrint('File Save Error: $e');
      }
    }
  }

  Future<void> createTicket({
    required String userName,
    required String role,
    required String issue,
    required String description,
    required String initialMessage,
  }) async {
    final tickets = await loadTickets();
    final newId = '#${1043 + tickets.length}';
    final newTicket = {
      'id': newId,
      'user': userName,
      'role': role,
      'issue': issue,
      'status': 'Open',
      'date': 'Just now',
      'description': description,
      'messages': [
        {'sender': role, 'text': initialMessage, 'time': 'Just now'},
      ]
    };
    tickets.insert(0, newTicket);
    await saveTickets(tickets);
    
    // Auto reply simulation for Web
    if (kIsWeb) {
      _simulateAutoReply(newId, issue);
    }
  }

  Future<void> sendMessage(String ticketId, String sender, String text) async {
    final tickets = await loadTickets();
    final ticketIndex = tickets.indexWhere((t) => t['id'] == ticketId);
    if (ticketIndex != -1) {
      final ticket = tickets[ticketIndex];
      final messages = List<Map<String, dynamic>>.from(ticket['messages']);
      messages.add({
        'sender': sender,
        'text': text,
        'time': 'Just now',
      });
      ticket['messages'] = messages;
      tickets[ticketIndex] = ticket;
      await saveTickets(tickets);

      // Auto reply simulation for Web if user sent a message
      if (kIsWeb && sender != 'Agent') {
        _simulateAutoReply(ticketId, text);
      }
    }
  }

  Future<void> updateStatus(String ticketId, String status) async {
    final tickets = await loadTickets();
    final ticketIndex = tickets.indexWhere((t) => t['id'] == ticketId);
    if (ticketIndex != -1) {
      tickets[ticketIndex]['status'] = status;
      await saveTickets(tickets);
    }
  }

  void _simulateAutoReply(String ticketId, String text) {
    Future.delayed(const Duration(seconds: 2), () async {
      final tickets = await loadTickets();
      final ticketIndex = tickets.indexWhere((t) => t['id'] == ticketId);
      if (ticketIndex != -1) {
        final ticket = tickets[ticketIndex];
        if (ticket['status'] == 'Resolved') return;
        
        final messages = List<Map<String, dynamic>>.from(ticket['messages']);
        // Only reply if the last message was from User/Host (not Agent)
        if (messages.last['sender'] != 'Agent') {
          String replyText = "Hello! A member of our Lodge Support Team has been assigned to your ticket and will look into this right away.";
          if (text.toLowerCase().contains('cancel')) {
            replyText = "We are deeply sorry to hear about the cancellation. We are searching for nearby alternative lodges and checking refund eligibility.";
          } else if (text.toLowerCase().contains('refund') || text.toLowerCase().contains('fee')) {
            replyText = "Your refund request has been logged. We are contacting the property host to verify details and process the adjustment.";
          } else if (text.toLowerCase().contains('break') || text.toLowerCase().contains('window') || text.toLowerCase().contains('damage')) {
            replyText = "We understand there is property damage. Please ensure you upload photos. Our resolution center will mediate this dispute.";
          }
          
          messages.add({
            'sender': 'Agent',
            'text': replyText,
            'time': 'Just now',
          });
          ticket['messages'] = messages;
          ticket['status'] = 'In Progress';
          tickets[ticketIndex] = ticket;
          await saveTickets(tickets);
        }
      }
    });
  }
}
