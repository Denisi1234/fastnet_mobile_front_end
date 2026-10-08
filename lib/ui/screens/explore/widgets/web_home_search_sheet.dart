import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:fastnet_mobile_front_end/config/constants.dart';

/// Exact replica of the web mobile search sheet
/// (`gh-search-bar.php` sheet + `gh-search-suggest.php` +
/// `gh-search-dates.php` + `gh-search-mobile.php`).
///
/// Full-screen white sheet: drag handle, "Search stays" header + round
/// close button, Where/When/Who tabs, single-open accordions on a grey
/// body, and a sticky footer ("Clear all" + "Search stays · N stays").
/// City picks advance to When; dates/guests/clear apply live (web
/// `replaceState`); the footer Search closes + submits (web `pushState`).
class WebHomeSearchSheet extends StatefulWidget {
  final String initialCity;
  final DateTime initialCheckIn;
  final DateTime initialCheckOut;
  final int initialAdults;
  final int initialChildren;
  final int initialRooms;
  final String initialStep;
  final List<String> initialRecentCities;

  /// Live-apply callbacks (parent setState + persist, no backend reload).
  final ValueChanged<String> onCityChanged;

  /// Real picks (not keystrokes): parent records recent searches.
  final ValueChanged<String> onCityPicked;
  final VoidCallback onClearRecents;
  final void Function(DateTime checkIn, DateTime checkOut) onDatesChanged;
  final void Function(int adults, int children, int rooms) onGuestsChanged;

  /// Footer actions.
  final VoidCallback onClearAll;
  final VoidCallback onSearch;

  /// Live footer count: stays matching the draft city (web markers count).
  final int Function(String city) countMatches;

  const WebHomeSearchSheet({
    super.key,
    required this.initialCity,
    required this.initialCheckIn,
    required this.initialCheckOut,
    required this.initialAdults,
    required this.initialChildren,
    required this.initialRooms,
    required this.initialStep,
    required this.initialRecentCities,
    required this.onCityChanged,
    required this.onCityPicked,
    required this.onClearRecents,
    required this.onDatesChanged,
    required this.onGuestsChanged,
    required this.onClearAll,
    required this.onSearch,
    required this.countMatches,
  });

  @override
  State<WebHomeSearchSheet> createState() => _WebHomeSearchSheetState();
}

class _WebHomeSearchSheetState extends State<WebHomeSearchSheet> {
  // Web tokens.
  static const _blue = Color(0xFF0F62FE);
  static const _bluePale = Color(0xFFEFF6FF);
  static const _ink = Color(0xFF1F2937);
  static const _muted = Color(0xFF6B7280);
  static const _faint = Color(0xFF9CA3AF);
  static const _border = Color(0xFFE5E7EB);
  static const _bodyBg = Color(0xFFF9FAFB);
  static const _iconTile = Color(0xFFF3F4F6);

  // Web POPULAR list, verbatim (labels, subs, typo-tolerant aliases).
  static const _popular = [
    {
      'label': 'Arusha',
      'sub': 'Gateway to Serengeti & Ngorongoro',
      'icon': Icons.landscape_outlined,
      'aka': 'arusa arushatown',
    },
    {
      'label': 'Zanzibar',
      'sub': 'Stone Town & Beaches',
      'icon': Icons.beach_access_outlined,
      'aka': 'znz stonetown zanzibartown',
    },
    {
      'label': 'Dar es Salaam',
      'sub': 'Commercial capital',
      'icon': Icons.location_city_outlined,
      'aka': 'dsm daressalaam daressalam daresalaam',
    },
    {
      'label': 'Kilimanjaro',
      'sub': 'Mount Kilimanjaro region',
      'icon': Icons.terrain_outlined,
      'aka': 'moshi',
    },
    {
      'label': 'Serengeti',
      'sub': 'National Park',
      'icon': Icons.pets_outlined,
      'aka': 'seronera',
    },
    {
      'label': 'Mwanza',
      'sub': 'Lake Victoria',
      'icon': Icons.water_drop_outlined,
      'aka': 'lakevictoria',
    },
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late String _tab;
  String? _open;
  late String _city;
  late TextEditingController _queryCtrl;
  late FocusNode _queryFocus;
  late DateTime _ci;
  late DateTime _co;
  late int _ad;
  late int _ch;
  late int _rm;
  String _picking = 'ci';
  String _preset = '';
  late List<String> _recents;

  // Mapbox suggest state (web fnsMbxSuggest: debounce 250ms, cache,
  // stale-response guard, Tanzania-only).
  Timer? _debounce;
  int _reqId = 0;
  final Map<String, List<Map<String, String>>> _mbxCache = {};
  List<Map<String, String>> _mbxResults = [];
  String _mbxQ = '';
  bool _mbxSearching = false;

  final ScrollController _gridCtrl = ScrollController();
  late List<GlobalKey> _monthKeys;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _tab = widget.initialStep;
    _open = widget.initialStep;
    _city = widget.initialCity;
    _queryCtrl = TextEditingController(text: widget.initialCity);
    _queryFocus = FocusNode();
    _ci = _day(widget.initialCheckIn);
    _co = _day(widget.initialCheckOut);
    if (!_co.isAfter(_ci)) _co = _ci.add(const Duration(days: 1));
    _ad = widget.initialAdults;
    _ch = widget.initialChildren;
    _rm = widget.initialRooms;
    _recents = List.of(widget.initialRecentCities);
    _monthKeys = List.generate(6, (_) => GlobalKey());
    if (_tab == 'when') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCiMonth());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    _queryFocus.dispose();
    _gridCtrl.dispose();
    super.dispose();
  }

  int get _nights => _co.difference(_ci).inDays.clamp(1, 365);

  String _fmtFull(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_monthsShort[d.month - 1]} ${d.day}';

  /// Web guest label, verbatim.
  String _guestText() {
    if (_ch > 0) {
      return '$_ad adults · $_ch child${_ch == 1 ? '' : 'ren'} · '
          '$_rm room${_rm == 1 ? '' : 's'}';
    }
    return '$_ad adult${_ad == 1 ? '' : 's'} · $_rm room${_rm == 1 ? '' : 's'}';
  }

  // ── Sheet navigation (web fnsSheetGo / fnsAccToggle) ──

  void _go(String step) {
    HapticFeedback.selectionClick();
    setState(() {
      _tab = step;
      _open = step;
    });
    if (step == 'when') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCiMonth());
    }
  }

  void _toggle(String step) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_open == step) {
        _open = null;
      } else {
        _open = step;
        _tab = step;
      }
    });
    if (_open == 'when') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCiMonth());
    }
  }

  void _scrollToCiMonth() {
    // Grid always starts at the check-in month (web renderMobileCal), so
    // the selected month is index 0 — mirror scrollIntoView(range-start).
    if (_gridCtrl.hasClients) {
      _gridCtrl.jumpTo(0);
    } else {
      final ctx = _monthKeys[0].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0,
            curve: Curves.easeOut);
      }
    }
  }

  // ── Where (web renderDest / fnsMbxSuggest / fnsPickDest) ──

  bool _matchPopular(Map<String, Object> p, String ql, String qslug) {
    if (ql.isEmpty) return true;
    final label = (p['label'] as String).toLowerCase();
    final sub = (p['sub'] as String).toLowerCase();
    final aka = (p['aka'] as String).toLowerCase();
    if (label.contains(ql) || sub.contains(ql) || aka.contains(ql)) {
      return true;
    }
    if (qslug.isNotEmpty &&
        aka.replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(' ', '').contains(qslug)) {
      return true;
    }
    return false;
  }

  void _setCity(String v) {
    setState(() {
      _city = v;
      _queryCtrl.text = v;
    });
    widget.onCityChanged(v);
  }

  void _onQueryChanged(String v) {
    setState(() {});
    widget.onCityChanged(v);
    _city = v;
    final ql = v.toLowerCase().trim();
    _debounce?.cancel();
    if (ql.length < 2) {
      setState(() {
        _mbxResults = [];
        _mbxQ = '';
        _mbxSearching = false;
      });
      return;
    }
    if (_mbxCache.containsKey(ql)) {
      setState(() {
        _mbxResults = _mbxCache[ql]!;
        _mbxQ = ql;
        _mbxSearching = false;
      });
      return;
    }
    setState(() => _mbxSearching = true);
    _debounce = Timer(const Duration(milliseconds: 250), () => _mbxSuggest(ql));
  }

  Future<void> _mbxSuggest(String ql) async {
    final id = ++_reqId;
    try {
      final params =
          'country=tz&limit=6&types=place,locality,neighborhood,address,poi'
          '&language=en&bbox=28.85,-11.75,40.5,-0.95'
          '&access_token=${AppConstants.mapboxApiKey}';
      final uri = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/'
          '${Uri.encodeComponent(ql)}.json?$params');
      final res = await http.get(uri);
      if (id != _reqId || !mounted) return;
      if (res.statusCode != 200) {
        setState(() => _mbxSearching = false);
        return;
      }
      // Ignore stale responses the user already typed past.
      if (_queryCtrl.text.toLowerCase().trim() != ql) return;
      final feats =
          (jsonDecode(res.body)['features'] as List? ?? []).cast<Map>();
      final out = feats.map((f) {
        final text = (f['text'] ?? '').toString();
        final types = (f['place_type'] as List? ?? []).map((e) => e.toString()).toList();
        String icon = 'city';
        final joined = types.join(' ');
        if (joined.contains('poi')) {
          icon = 'poi';
        } else if (joined.contains('address')) {
          icon = 'address';
        } else if (joined.contains('neighborhood') || joined.contains('locality')) {
          icon = 'pin';
        }
        final parts = (f['place_name'] ?? '').toString().split(',');
        parts.removeAt(0);
        final rest = parts.join(',').trim();
        return {
          'text': text,
          'sub': rest.isEmpty ? 'Tanzania' : rest,
          'city': _mbxCity(f),
          'icon': icon,
        };
      }).toList();
      _mbxCache[ql] = out;
      setState(() {
        _mbxResults = out;
        _mbxQ = ql;
        _mbxSearching = false;
      });
    } catch (_) {
      if (id != _reqId || !mounted) return;
      setState(() => _mbxSearching = false);
    }
  }

  /// Backend filters by city-level name: map exact POI coords but search
  /// the parent city (web mbxCityName, verbatim).
  String _mbxCity(Map f) {
    final types = (f['place_type'] as List? ?? []).map((e) => e.toString()).toList();
    if (types.contains('country')) return '';
    if (types.contains('place') || types.contains('region')) {
      return (f['text'] ?? '').toString();
    }
    final ctx = (f['context'] as List? ?? []).cast<Map>();
    for (final c in ctx) {
      final cid = (c['id'] ?? '').toString();
      if (cid.startsWith('place') || cid.startsWith('region')) {
        return (c['text'] ?? '').toString();
      }
    }
    return (f['text'] ?? '').toString();
  }

  IconData _mbxIcon(String kind) {
    switch (kind) {
      case 'poi':
        return Icons.location_on_outlined;
      case 'address':
        return Icons.house_outlined;
      case 'pin':
        return Icons.place_outlined;
      default:
        return Icons.location_city_outlined;
    }
  }

  void _pickCity(String city) {
    if (city.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _recents.remove(city);
      _recents.insert(0, city);
      if (_recents.length > 5) _recents.removeLast();
    });
    widget.onCityPicked(city);
    _setCity(city);
    _go('when');
  }

  void _clearRecents() {
    HapticFeedback.lightImpact();
    setState(() => _recents.clear());
    widget.onClearRecents();
  }

  void _clearQuery() {
    _debounce?.cancel();
    setState(() {
      _queryCtrl.clear();
      _city = '';
      _mbxResults = [];
      _mbxQ = '';
      _mbxSearching = false;
    });
    widget.onCityChanged('');
  }

  // ── When (web syncDate / fnsStep / renderMobileCal / fnsPreset) ──

  void _applyDates() {
    setState(() {});
    widget.onDatesChanged(_ci, _co);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCiMonth());
  }

  void _tapDay(DateTime day) {
    HapticFeedback.selectionClick(); // web navigator.vibrate(12)
    if (_picking == 'ci' || !day.isAfter(_ci)) {
      _ci = day;
      if (!_co.isAfter(_ci)) _co = _ci.add(const Duration(days: 1));
      _picking = 'co';
    } else {
      _co = day;
      _picking = 'ci';
    }
    _preset = '';
    _applyDates();
  }

  void _stepDay(String which, int delta) {
    HapticFeedback.selectionClick();
    final today = _today();
    if (which == 'ci') {
      final iso = _ci.add(Duration(days: delta));
      if (iso.isBefore(today)) return;
      _ci = iso;
      if (!_co.isAfter(_ci)) _co = _ci.add(const Duration(days: 1));
    } else {
      final iso = _co.add(Duration(days: delta));
      if (!iso.isAfter(_ci)) return;
      _co = iso;
    }
    _preset = '';
    _applyDates();
  }

  void _presetTap(String kind) {
    HapticFeedback.selectionClick();
    setState(() => _preset = kind);
    if (kind == 'weekend') {
      final t = _today();
      final jsDay = t.weekday % 7; // Sun=0 … Sat=6
      final fri = t.add(Duration(days: (5 - jsDay + 7) % 7));
      _ci = fri;
      _co = fri.add(const Duration(days: 2));
    } else if (kind == 'week') {
      _ci = _today();
      _co = _ci.add(const Duration(days: 7));
    }
    _picking = 'ci';
    _applyDates();
  }

  // ── Who (web fnsG) ──

  void _bump(String kind, int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      if (kind == 'adults') {
        _ad = (_ad + delta).clamp(1, 10);
      } else if (kind == 'children') {
        _ch = (_ch + delta).clamp(0, 6);
      } else {
        _rm = (_rm + delta).clamp(1, 5);
      }
    });
    widget.onGuestsChanged(_ad, _ch, _rm);
  }

  // ── Sheet drag-to-dismiss (web spring handle) ──
  double _dragDy = 0;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragDy = (_dragDy + d.delta.dy).clamp(0.0, 400.0));
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_dragDy > 120 || v > 600) {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    } else {
      setState(() => _dragDy = 0);
    }
  }

  // ── Footer (web fnsClearAllMobile / fnsMobileSearch) ──

  void _clearAll() {
    HapticFeedback.lightImpact();
    _debounce?.cancel();
    final t = _today();
    setState(() {
      _queryCtrl.clear();
      _city = '';
      _ci = t;
      _co = t.add(const Duration(days: 1));
      _ad = 2;
      _ch = 0;
      _rm = 1;
      _picking = 'ci';
      _preset = '';
      _mbxResults = [];
      _mbxQ = '';
      _mbxSearching = false;
    });
    widget.onClearAll();
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _dragDy),
      child: Column(
        children: [
          GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DragHandle(),
                // Header: title + round close.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Search stays',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              letterSpacing: -0.17)),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 20, color: _ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Tabs.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border))),
          child: Row(
            children: [
              _tabBtn('where', 'Where'),
              _tabBtn('when', 'When'),
              _tabBtn('who', 'Who'),
            ],
          ),
        ),
        // Accordions on grey body.
        Expanded(
          child: Container(
            color: _bodyBg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  _accordion(
                    'where',
                    'Where to?',
                    _city.isEmpty ? 'All Tanzanian Destinations' : _city,
                    _whereBody(),
                  ),
                  _accordion(
                    'when',
                    'When?',
                    '${_fmtFull(_ci)} – ${_fmtFull(_co)} · ${_nights}n',
                    _whenBody(),
                  ),
                  _accordion(
                    'who',
                    "Who's coming?",
                    _guestText(),
                    _whoBody(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Footer: Clear all + Search stays · N stays.
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _border))),
          child: Row(
            children: [
              TextButton(
                onPressed: _clearAll,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Clear all',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _muted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onSearch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: _blue.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999)),
                    ),
                    child: Text(
                      'Search stays · ${widget.countMatches(_city)} stays',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _tabBtn(String step, String label) {
    final active = _tab == step;
    return Expanded(
      child: InkWell(
        onTap: () => _go(step),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 13, 6, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: active ? _blue : Colors.transparent,
                  width: 2.5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? _blue : _muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _accordion(
      String step, String title, String value, Widget body) {
    final open = _open == step;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 3,
              offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggle(step),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              color: open ? _bodyBg : Colors.white,
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: _muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: _iconTile))),
                    child: body,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  // ── Where body ──

  Widget _whereBody() {
    final ql = _queryCtrl.text.toLowerCase().trim();
    final qslug = ql.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final filtered =
        _popular.where((p) => _matchPopular(p, ql, qslug)).toList();
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1.5),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 15, color: _muted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  focusNode: _queryFocus,
                  autofocus: _tab == 'where',
                  style:
                      const TextStyle(fontSize: 16, color: _ink),
                  decoration: const InputDecoration(
                    hintText: 'City, landmark, or hotel name',
                    hintStyle:
                        TextStyle(fontSize: 16, color: _faint),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => widget.onSearch(),
                ),
              ),
              if (_queryCtrl.text.isNotEmpty)
                InkWell(
                  onTap: _clearQuery,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _iconTile,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: _muted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (_mbxSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Searching real places…',
                style: TextStyle(fontSize: 13, color: _muted)),
          ),
        // Mobile-only upgrade: recent searches (web shows popular only).
        if (ql.isEmpty && _mbxResults.isEmpty && _recents.isNotEmpty) ...[
          _SectionLabel('Recent searches', onClear: _clearRecents),
          for (final c in _recents)
            _suggestTile(
              icon: Icons.history_rounded,
              label: c,
              sub: 'Recent search',
              onTap: () => _pickCity(c),
            ),
        ],
        if (_mbxQ.isNotEmpty && _mbxResults.isNotEmpty) ...[
          const _SectionLabel('Real places'),
          for (final f in _mbxResults)
            _suggestTile(
              icon: _mbxIcon(f['icon']!),
              label: f['text']!,
              sub: f['sub']!,
              onTap: () => _pickCity(f['city']!),
            ),
        ],
        for (final p in filtered)
          _suggestTile(
            icon: p['icon'] as IconData,
            label: p['label'] as String,
            sub: p['sub'] as String,
            onTap: () => _pickCity(p['label'] as String),
          ),
        if (filtered.isEmpty &&
            !(_mbxQ.isNotEmpty && _mbxResults.isNotEmpty))
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No matches — try Arusha, Zanzibar, Mwanza',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _muted)),
          ),
      ],
    );
  }

  Widget _suggestTile({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconTile,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 14, color: _muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                          height: 1.2)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 11, color: _faint),
          ],
        ),
      ),
    );
  }

  // ── When body ──

  Widget _whenBody() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ciBox()),
            const SizedBox(width: 8),
            Expanded(child: _coBox()),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final w in _weekdayLetters)
              Expanded(
                child: Text(w,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted)),
              ),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.42,
          child: ListView.builder(
            controller: _gridCtrl,
            itemCount: 6,
            itemBuilder: (_, m) => _month(m),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _presetBtn('weekend', 'Weekend'),
            const SizedBox(width: 8),
            _presetBtn('week', '1 Week'),
            const SizedBox(width: 8),
            _presetBtn('custom', 'Custom'),
          ],
        ),
      ],
    );
  }

  Widget _ciBox() {
    final active = _picking == 'ci';
    return InkWell(
      onTap: () => setState(() => _picking = 'ci'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? _blue : _border, width: 1.5),
          color: active ? _bluePale : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _dayStep('ci', -1),
            Flexible(
              child: Text(_fmtFull(_ci),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
            ),
            _dayStep('ci', 1),
          ],
        ),
      ),
    );
  }

  Widget _dayStep(String which, int delta) {
    return InkWell(
      onTap: () => _stepDay(which, delta),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _bodyBg,
        ),
        child: Icon(
          delta < 0
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          size: 18,
          color: _muted,
        ),
      ),
    );
  }

  Widget _coBox() {
    final active = _picking == 'co';
    return InkWell(
      onTap: () => setState(() => _picking = 'co'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? _blue : _border, width: 1.5),
          color: active ? _bluePale : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(_fmtFull(_co),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minHeight: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _bluePale,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Text('${_nights}n',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                      height: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _month(int offset) {
    final base = DateTime(_ci.year, _ci.month + offset, 1);
    final yr = base.year;
    final mo = base.month;
    final firstDow = DateTime(yr, mo, 1).weekday % 7; // Sun=0
    final days = DateTime(yr, mo + 1, 0).day;
    final today = _today();
    return Container(
      key: _monthKeys[offset],
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border))),
      child: Column(
        children: [
          Text('${_monthsFull[mo - 1]} $yr',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: firstDow + days,
            itemBuilder: (_, i) {
              if (i < firstDow) return const SizedBox.shrink();
              final day = DateTime(yr, mo, i - firstDow + 1);
              return _dayCell(day, today);
            },
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime day, DateTime today) {
    final past = day.isBefore(today);
    final isStart = day == _ci;
    final isEnd = day == _co;
    final inRange = day.isAfter(_ci) && day.isBefore(_co);
    return InkWell(
      onTap: past ? null : () => _tapDay(day),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints:
            const BoxConstraints(minHeight: 44, minWidth: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: inRange ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: inRange ? BorderRadius.circular(8) : null,
          color: (isStart || isEnd)
              ? _blue
              : (inRange ? _bluePale : Colors.transparent),
          boxShadow: (isStart || isEnd)
              ? [
                  BoxShadow(
                      color: _blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: (isStart || isEnd || inRange)
                ? FontWeight.w700
                : FontWeight.w500,
            color: past
                ? const Color(0xFFD1D5DB)
                : ((isStart || isEnd)
                    ? Colors.white
                    : (inRange ? _blue : _ink)),
          ),
        ),
      ),
    );
  }

  Widget _presetBtn(String kind, String label) {
    final active = _preset == kind;
    return Expanded(
      child: InkWell(
        onTap: () => _presetTap(kind),
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
                color: active
                    ? const Color(0xFFBFDBFE)
                    : _border),
            color: active ? _bluePale : Colors.white,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? _blue : _ink)),
        ),
      ),
    );
  }

  // ── Who body ──

  Widget _whoBody() {
    return Column(
      children: [
        _guestRow('Adults', 'Ages 13+', _ad, 1, 10,
            (d) => _bump('adults', d)),
        _guestRow('Children', 'Ages 0–12', _ch, 0, 6,
            (d) => _bump('children', d)),
        _guestRow('Rooms', '1–5 rooms', _rm, 1, 5,
            (d) => _bump('rooms', d)),
      ],
    );
  }

  Widget _guestRow(String title, String sub, int value, int min,
      int max, ValueChanged<int> onBump) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
          Row(
            children: [
              _stepBtn(value > min, Icons.remove_rounded,
                  () => onBump(-1)),
              SizedBox(
                width: 40,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
              ),
              _stepBtn(value < max, Icons.add_rounded,
                  () => onBump(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(bool enabled, IconData icon, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
            color: Colors.white,
          ),
          child: Icon(icon, size: 18, color: _muted),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      alignment: Alignment.center,
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final VoidCallback? onClear;
  const _SectionLabel(this.text, {this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.72,
                    color: Color(0xFF6B7280))),
          ),
          if (onClear != null)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text('Clear',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280))),
              ),
            ),
        ],
      ),
    );
  }
}
