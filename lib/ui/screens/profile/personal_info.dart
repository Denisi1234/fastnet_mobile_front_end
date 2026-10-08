import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/fade_slide_page_route.dart';

/// Mobile layout of web `/my-profile` (`my-profile.php` + `profile.css`).
///
/// Title + sub, then single-open accordion setting rows (Name, Email,
/// Phone, Date of birth, Gender, Address, Emergency contact, Avatar),
/// each with its own Save/Cancel and a dark toast on save — same tokens
/// (`#0f172a`, `#007fad`, hairline `#f1f5f9`). The photo header is kept
/// as a mobile capability (camera/gallery upload + backend sync).
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Web `profile.css` tokens.
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF007FAD);
  static const _hairline = Color(0xFFF1F5F9);
  static const _inputBorder = Color(0xFFCBD5E1);

  // Web avatar badges (`my-profile.php` row_avatar), verbatim.
  static const _avatarChoices = [
    {'bg': '#f0f9ff', 'fg': '#0284c7'},
    {'bg': '#fef2f2', 'fg': '#dc2626'},
    {'bg': '#f0fdf4', 'fg': '#16a34a'},
    {'bg': '#faf5ff', 'fg': '#9333ea'},
  ];

  // Web gender options, verbatim.
  static const _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  final _picker = ImagePicker();

  late TextEditingController _firstController;
  late TextEditingController _lastController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyController;

  String? _selectedGender;
  String? _pickedImagePath;
  String? _avatarBg;
  String? _avatarFg;

  String? _openRow;
  String? _savingRow;

  @override
  void initState() {
    super.initState();
    final parts = (UserSession.userName ?? '').trim().split(RegExp(r'\s+'));
    _firstController = TextEditingController(
        text: parts.isNotEmpty ? parts.first : '');
    _lastController = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _emailController =
        TextEditingController(text: UserSession.userEmail ?? '');
    _phoneController =
        TextEditingController(text: UserSession.userPhone ?? '');
    _dobController =
        TextEditingController(text: UserSession.dateOfBirth ?? '');
    _addressController =
        TextEditingController(text: UserSession.address ?? '');
    _emergencyController =
        TextEditingController(text: UserSession.emergencyContact ?? '');
    _selectedGender = UserSession.gender;
    _avatarBg = UserSession.avatarBg;
    _avatarFg = UserSession.avatarFg;

    final savedPath = UserSession.profileImagePath;
    if (savedPath != null && File(savedPath).existsSync()) {
      _pickedImagePath = savedPath;
    } else if (savedPath != null) {
      UserSession.profileImagePath = null;
      UserSession.save();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstController,
      _lastController,
      _emailController,
      _phoneController,
      _dobController,
      _addressController,
      _emergencyController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Color _hex(String? hex, Color fallback) {
    try {
      if (hex == null || hex.isEmpty) return fallback;
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return fallback;
    }
  }

  String get _initial {
    final name = (UserSession.userName ?? '').trim();
    if (name.isNotEmpty) return name.substring(0, 1).toUpperCase();
    return 'T';
  }

  String get _fullName {
    final full = '${_firstController.text.trim()} ${_lastController.text.trim()}'.trim();
    if (full.isNotEmpty) return full;
    return (UserSession.userName ?? '').trim().isNotEmpty
        ? UserSession.userName!.trim()
        : 'Traveler';
  }

  // ──────────────────────────────── PHOTO ─────────────────────────
  // (kept from the previous screen: camera/gallery + backend upload)

  ImageProvider _resolveProfileImage() {
    if (_pickedImagePath != null) {
      final f = File(_pickedImagePath!);
      if (f.existsSync()) return FileImage(f);
    }
    return AssetImage(UserSession.userAvatar);
  }

  void _showPhotoOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PhotoOptionsSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onRemove: _pickedImagePath != null
            ? () {
                Navigator.pop(context);
                _removePhoto();
              }
            : null,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_photos');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      final ext = picked.path.split('.').last.toLowerCase();
      final permanentPath =
          '${profileDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(permanentPath);
      if (!mounted) return;
      setState(() {
        _pickedImagePath = permanentPath;
        UserSession.profileImagePath = permanentPath;
      });
      await UserSession.save();
      if (mounted) {
        Provider.of<UserSessionProvider>(context, listen: false)
            .updateSession();
        _toast('Profile photo updated!');
      }
      unawaited(_uploadPhotoInBackground(permanentPath));
    } on PlatformException catch (e) {
      if (mounted) _toast('Permission denied: ${e.message}');
    } catch (_) {
      if (mounted) _toast('Could not save photo. Please try again.');
    }
  }

  Future<void> _uploadPhotoInBackground(String path) async {
    try {
      await ApiService.uploadProfilePhoto(path);
    } catch (_) {}
  }

  void _removePhoto() {
    HapticFeedback.selectionClick();
    setState(() {
      _pickedImagePath = null;
      UserSession.profileImagePath = null;
    });
    UserSession.save();
    Provider.of<UserSessionProvider>(context, listen: false)
        .updateSession();
    _toast('Profile photo removed.');
  }

  // ──────────────────────────────── SAVE ──────────────────────────
  // One Save per row (web `saveName()`/`saveEmail()`/…): PATCH the full
  // current profile, refresh local session + listeners, dark toast.

  Future<void> _saveRow(String rowId, {String? error}) async {
    if (error != null) {
      _toast(error);
      return;
    }
    setState(() => _savingRow = rowId);
    final name = _fullName;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final dob = _dobController.text.trim().isEmpty
        ? null
        : _dobController.text.trim();
    final address = _addressController.text.trim().isEmpty
        ? null
        : _addressController.text.trim();
    final emergency = _emergencyController.text.trim().isEmpty
        ? null
        : _emergencyController.text.trim();

    bool apiSuccess = false;
    try {
      apiSuccess = await ApiService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dob,
        gender: _selectedGender,
        bio: UserSession.bio,
        address: address,
        emergencyContact: emergency,
      );
    } catch (_) {}

    UserSession.userName = name;
    UserSession.userEmail = email;
    UserSession.userPhone = phone;
    UserSession.dateOfBirth = dob;
    UserSession.gender = _selectedGender;
    UserSession.address = address;
    UserSession.emergencyContact = emergency;
    UserSession.avatarBg = _avatarBg;
    UserSession.avatarFg = _avatarFg;
    await UserSession.save();
    if (mounted) {
      Provider.of<UserSessionProvider>(context, listen: false)
          .updateSession();
      setState(() {
        _savingRow = null;
        _openRow = null;
      });
      _toast(apiSuccess
          ? 'Saved successfully!'
          : 'Saved locally. Changes will sync when online.');
    }
  }

  String? _validateEmail() {
    final v = _emailController.text.trim();
    if (v.isEmpty) return 'Email address is required.';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initial;
    try {
      initial = _dobController.text.isNotEmpty
          ? DateTime.parse(_dobController.text)
          : DateTime(1990, 1, 1);
    } catch (_) {
      initial = DateTime(1990, 1, 1);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme:
              const ColorScheme.light(primary: _teal, onPrimary: Colors.white),
          dialogTheme:
              const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _toast(String msg) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _toggleRow(String id) {
    HapticFeedback.selectionClick();
    setState(() => _openRow = _openRow == id ? null : id);
  }

  // ──────────────────────────────── BUILD ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!UserSession.isLoggedIn) return _loginGate();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
        children: [
          _profileHero(),
          const SizedBox(height: 20),
          const Text(
            'Personal info',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.6),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check or change your personal information',
            style: TextStyle(fontSize: 14, color: _muted),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _hairline)),
            ),
            child: Column(
              children: [
                _nameRow(),
                _emailRow(),
                _phoneRow(),
                _dobRow(),
                _genderRow(),
                _addressRow(),
                _emergencyRow(),
                _avatarRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHero() {
    final hasPhoto = _pickedImagePath != null;
    return Row(
      children: [
        GestureDetector(
          onTap: _showPhotoOptions,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: hasPhoto
                    ? CircleAvatar(
                        radius: 36,
                        backgroundImage: _resolveProfileImage(),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hex(_avatarBg,
                              const Color(0xFFF0F9FF)),
                        ),
                        child: Text(
                          _initial,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _hex(_avatarFg,
                                const Color(0xFF0284C7)),
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: _teal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink),
              ),
              const SizedBox(height: 2),
              Text(
                UserSession.userEmail ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Generic accordion row (web `.trivago-setting-row`) ──

  Widget _row({
    required String id,
    required String label,
    required String value,
    required Widget editor,
    required VoidCallback onSave,
  }) {
    final open = _openRow == id;
    final saving = _savingRow == id;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleRow(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                        const SizedBox(height: 4),
                        Text(
                          value.isEmpty ? '—' : value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: _ink),
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
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        editor,
                        const SizedBox(height: 16),
                        // Web ≤575px: stacked full-width Cancel over Save.
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed:
                                saving ? null : () => _toggleRow(id),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: _muted)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                saving ? null : () => onSave(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFFCBD5E1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : const Text('Save',
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 15, color: _ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 15, color: Color(0xFF94A3B8)),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── The 8 web rows ──

  Widget _nameRow() {
    return _row(
      id: 'name',
      label: 'Name',
      value: _fullName,
      onSave: () => _saveRow('name',
          error: _fullName.trim().isEmpty ? 'Name is required.' : null),
      editor: Column(
        children: [
          _input(
              controller: _firstController, label: 'First name'),
          const SizedBox(height: 12),
          _input(controller: _lastController, label: 'Last name'),
        ],
      ),
    );
  }

  Widget _emailRow() {
    return _row(
      id: 'email',
      label: 'Email address',
      value: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : (UserSession.userEmail ?? ''),
      onSave: () => _saveRow('email', error: _validateEmail()),
      editor: _input(
        controller: _emailController,
        label: 'Email address',
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }

  Widget _phoneRow() {
    return _row(
      id: 'phone',
      label: 'Phone number',
      value: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : (UserSession.userPhone ?? ''),
      onSave: () => _saveRow('phone',
          error: _phoneController.text.trim().isEmpty
              ? 'Phone number is required.'
              : null),
      editor: _input(
        controller: _phoneController,
        label: 'Phone number',
        keyboardType: TextInputType.phone,
      ),
    );
  }

  Widget _dobRow() {
    return _row(
      id: 'dob',
      label: 'Date of birth',
      value: _dobController.text.trim().isNotEmpty
          ? _dobController.text.trim()
          : (UserSession.dateOfBirth ?? ''),
      onSave: () => _saveRow('dob'),
      editor: _input(
        controller: _dobController,
        label: 'Date of birth',
        readOnly: true,
        onTap: _pickDateOfBirth,
        suffix: const Icon(Icons.calendar_today_outlined,
            size: 18, color: _muted),
      ),
    );
  }

  Widget _genderRow() {
    final current =
        (_selectedGender ?? UserSession.gender ?? 'Not set');
    return _row(
      id: 'gender',
      label: 'Gender',
      value: current.isEmpty ? 'Not set' : current,
      onSave: () => _saveRow('gender'),
      editor: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569))),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _genderOptions.contains(_selectedGender)
                ? _selectedGender
                : null,
            hint: const Text('Select gender',
                style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
            style: const TextStyle(fontSize: 15, color: _ink),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _muted),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: _teal, width: 1.5),
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
            items: _genderOptions
                .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g,
                          style: const TextStyle(
                              fontSize: 15, color: _ink)),
                    ))
                .toList(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _selectedGender = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _addressRow() {
    return _row(
      id: 'address',
      label: 'Address',
      value: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : (UserSession.address ?? ''),
      onSave: () => _saveRow('address'),
      editor: _input(
        controller: _addressController,
        label: 'Address / Location',
        hint: 'e.g. Dar es Salaam, Tanzania',
      ),
    );
  }

  Widget _emergencyRow() {
    return _row(
      id: 'emergency',
      label: 'Emergency contact',
      value: _emergencyController.text.trim().isNotEmpty
          ? _emergencyController.text.trim()
          : (UserSession.emergencyContact ?? ''),
      onSave: () => _saveRow('emergency'),
      editor: _input(
        controller: _emergencyController,
        label: 'Emergency contact number',
        keyboardType: TextInputType.phone,
      ),
    );
  }

  Widget _avatarRow() {
    return _row(
      id: 'avatar',
      label: 'Choose avatar',
      value: 'Choose an avatar style that represents you',
      onSave: () => _saveRow('avatar'),
      editor: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select your badge color or avatar style:',
              style: TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < _avatarChoices.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                      right: i < _avatarChoices.length - 1 ? 12 : 0),
                  child: _avatarBadge(i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarBadge(int i) {
    final bg = _avatarChoices[i]['bg']!;
    final fg = _avatarChoices[i]['fg']!;
    final selected = (_avatarBg ?? _avatarChoices[0]['bg']) == bg;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _avatarBg = bg;
          _avatarFg = fg;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _teal : _inputBorder,
            width: selected ? 2 : 1.5,
          ),
          color: _hex(bg, Colors.white),
        ),
        child: Text(
          _initial,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _hex(fg, _teal)),
        ),
      ),
    );
  }

  // ── Login gate ──

  Widget _loginGate() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          'Personal info',
          style: TextStyle(
              color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F9FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 44, color: _teal),
              ),
              const SizedBox(height: 20),
              const Text('Sign In Required',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 8),
              const Text(
                'Please sign in to manage your personal profile and account information.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: _muted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      FadeSlidePageRoute(
                          page: const LoginSignupScreen()),
                    ).then((_) => setState(_reloadFromSession));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log In / Register',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reloadFromSession() {
    final parts = (UserSession.userName ?? '').trim().split(RegExp(r'\s+'));
    setState(() {
      _firstController.text = parts.isNotEmpty ? parts.first : '';
      _lastController.text =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _emailController.text = UserSession.userEmail ?? '';
      _phoneController.text = UserSession.userPhone ?? '';
      _dobController.text = UserSession.dateOfBirth ?? '';
      _addressController.text = UserSession.address ?? '';
      _emergencyController.text = UserSession.emergencyContact ?? '';
      _selectedGender = UserSession.gender;
      _avatarBg = UserSession.avatarBg;
      _avatarFg = UserSession.avatarFg;
      _pickedImagePath = UserSession.profileImagePath;
    });
  }
}

// ── Photo options sheet (kept capability, web tokens) ──
class _PhotoOptionsSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _PhotoOptionsSheet({
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Update Profile Photo',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _optionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              sublabel: 'Use your camera',
              onTap: onCamera,
            ),
            _divider(),
            _optionTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              sublabel: 'Pick from your photos',
              onTap: onGallery,
            ),
            if (onRemove != null) ...[
              _divider(),
              _optionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                sublabel: 'Revert to avatar badge',
                onTap: onRemove!,
                destructive: true,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color =
        destructive ? Colors.red.shade700 : const Color(0xFF007FAD);
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _ink)),
      subtitle: Text(sublabel,
          style: const TextStyle(color: _muted, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Color(0xFF94A3B8)),
    );
  }

  Widget _divider() => const Divider(
      height: 1, color: Color(0xFFF1F5F9), indent: 24, endIndent: 24);
}
