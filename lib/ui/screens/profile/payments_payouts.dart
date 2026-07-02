import 'package:flutter/material.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/login_signup_screen.dart';

class PaymentsPayoutsScreen extends StatefulWidget {
  const PaymentsPayoutsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsPayoutsScreen> createState() => _PaymentsPayoutsScreenState();
}

class _PaymentsPayoutsScreenState extends State<PaymentsPayoutsScreen> {
  final List<Map<String, String>> _paymentMethods = [
    {'type': 'Card', 'provider': 'Visa ending in *4829', 'isDefault': 'true'},
    {'type': 'Mobile Wallet', 'provider': 'Vodacom M-Pesa (*5678)', 'isDefault': 'false'},
  ];

  final List<Map<String, dynamic>> _transactions = [
    {'title': 'Zanzibar Beach Resort', 'date': 'Jun 12, 2026', 'amount': 455000, 'method': 'Visa *4829'},
    {'title': 'Swahili Dinner Room Service', 'date': 'Jun 13, 2026', 'amount': 38000, 'method': 'Visa *4829'},
    {'title': 'Dodoma Executive Stay', 'date': 'May 04, 2026', 'amount': 240000, 'method': 'M-Pesa *5678'},
  ];

  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _addPaymentMethod() {
    String selectedType = 'Card';
    final cardNoController = TextEditingController();
    final providerController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Method Type'),
                      items: ['Card', 'Mobile Money Wallet'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedType == 'Card') ...[
                      TextFormField(
                        controller: cardNoController,
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        decoration: const InputDecoration(labelText: 'Card Number', hintText: '16 digits'),
                        validator: (val) => val == null || val.length != 16 ? 'Enter 16 digit card number' : null,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: providerController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Wallet Number', hintText: 'e.g. 0712345678'),
                        validator: (val) => val == null || val.trim().length < 9 ? 'Enter a valid number' : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              if (selectedType == 'Card') {
                                final last4 = cardNoController.text.substring(12);
                                _paymentMethods.add({
                                  'type': 'Card',
                                  'provider': 'Visa ending in *$last4',
                                  'isDefault': 'false',
                                });
                              } else {
                                final phone = providerController.text.trim();
                                _paymentMethods.add({
                                  'type': 'Mobile Wallet',
                                  'provider': 'Mobile Money (*${phone.substring(phone.length - 4)})',
                                  'isDefault': 'false',
                                });
                              }
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment option saved successfully.'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                        child: const Text('Save Payment Option', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _setDefault(Map<String, String> method) {
    setState(() {
      for (var m in _paymentMethods) {
        m['isDefault'] = 'false';
      }
      method['isDefault'] = 'true';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${method['provider']} set as default payment option.')),
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
          title: const Text('Payments & Payouts', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text(
                  'Login Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in or register to view and manage your payment accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
                      ).then((_) => setState(() {}));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Log In / Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Payments & Payouts', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentMethods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final m = _paymentMethods[index];
                final isDefault = m['isDefault'] == 'true';
                final isCard = m['type'] == 'Card';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isCard ? Icons.credit_card : Icons.phone_android, color: Colors.black87),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['provider']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(isDefault ? 'Default payment method' : 'Alternative backup', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      if (!isDefault)
                        TextButton(
                          onPressed: () => _setDefault(m),
                          child: const Text('Set Default', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        )
                      else
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _addPaymentMethod,
                icon: const Icon(Icons.add, color: Colors.black87),
                label: const Text('Add Payment Account', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text('Payment Transaction Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = _transactions[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Paid via ${tx['method']} • ${tx['date']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      Text(
                        _formatPrice(tx['amount']!),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 15),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
