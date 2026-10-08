import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mobile equivalent of web `/language-and-currency`: persisted app
/// language + display currency preferences.
class LanguageCurrencyScreen extends StatefulWidget {
  const LanguageCurrencyScreen({super.key});

  @override
  State<LanguageCurrencyScreen> createState() =>
      _LanguageCurrencyScreenState();
}

class _LanguageCurrencyScreenState extends State<LanguageCurrencyScreen> {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF007FAD);
  static const _hairline = Color(0xFFF1F5F9);

  static const _languages = ['English', 'Kiswahili', 'French'];
  static const _currencies = [
    {'code': 'TZS', 'label': 'Tanzanian Shilling', 'symbol': 'TSh'},
    {'code': 'USD', 'label': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'label': 'Euro', 'symbol': '€'},
  ];

  String _language = 'English';
  String _currency = 'TZS';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        final lang = prefs.getString('pref_language') ?? 'English';
        if (_languages.contains(lang)) _language = lang;
        final cur = prefs.getString('pref_currency') ?? 'TZS';
        if (_currencies.any((c) => c['code'] == cur)) _currency = cur;
      });
    } catch (_) {}
  }

  Future<void> _pickLanguage(String v) async {
    HapticFeedback.selectionClick();
    setState(() => _language = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_language', v);
    } catch (_) {}
  }

  Future<void> _pickCurrency(String v) async {
    HapticFeedback.selectionClick();
    setState(() => _currency = v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_currency', v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'Language and currency',
          style: TextStyle(
              color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          const Text('Language',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
          const SizedBox(height: 4),
          const Text('Choose the language for the app.',
              style: TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(height: 12),
          for (final l in _languages)
            _optionRow(
              label: l,
              selected: _language == l,
              onTap: () => _pickLanguage(l),
            ),
          const SizedBox(height: 28),
          const Text('Currency',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
          const SizedBox(height: 4),
          const Text('Prices across the app display in this currency.',
              style: TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(height: 12),
          for (final c in _currencies)
            _optionRow(
              label: '${c['label']} (${c['symbol']})',
              selected: _currency == c['code'],
              onTap: () => _pickCurrency(c['code']!),
            ),
        ],
      ),
    );
  }

  Widget _optionRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _teal : _ink,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: _teal, size: 20),
          ],
        ),
      ),
    );
  }
}
