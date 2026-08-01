import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/login_signup_screen.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyController;

  String? _selectedGender;
  String? _pickedImagePath;
  bool _isSaving = false;
  bool _hasChanges = false;

  late AnimationController _avatarAnimCtrl;
  late Animation<double> _avatarScaleAnim;

  static const List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  static const Color _primary = Color(0xFFC62828);
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF1A1A2E);
  static const Color _textSub = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserSession.userName ?? '');
    _emailController = TextEditingController(text: UserSession.userEmail ?? '');
    _phoneController = TextEditingController(text: UserSession.userPhone ?? '');
    _dobController = TextEditingController(text: UserSession.dateOfBirth ?? '');
    _bioController = TextEditingController(text: UserSession.bio ?? '');
    _addressController = TextEditingController(text: UserSession.address ?? '');
    _emergencyController = TextEditingController(text: UserSession.emergencyContact ?? '');
    _selectedGender = UserSession.gender;

    // Verify the saved image path still exists on disk
    final savedPath = UserSession.profileImagePath;
    if (savedPath != null && File(savedPath).existsSync()) {
      _pickedImagePath = savedPath;
    } else if (savedPath != null) {
      // File was deleted externally — clear the stale reference
      UserSession.profileImagePath = null;
      UserSession.save();
    }

    _avatarAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _avatarScaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _avatarAnimCtrl, curve: Curves.easeInOut),
    );

    for (final c in [
      _nameController, _emailController, _phoneController,
      _dobController, _bioController, _addressController, _emergencyController,
    ]) {
      c.addListener(_onFieldChange);
    }
  }

  void _onFieldChange() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  /// Returns the correct ImageProvider: FileImage when a real photo exists,
  /// otherwise the default asset avatar. Never throws on a missing file.
  ImageProvider _resolveProfileImage() {
    if (_pickedImagePath != null) {
      final f = File(_pickedImagePath!);
      if (f.existsSync()) return FileImage(f);
    }
    return AssetImage(UserSession.userAvatar);
  }

  @override
  void dispose() {
    _avatarAnimCtrl.dispose();
    for (final c in [
      _nameController, _emailController, _phoneController,
      _dobController, _bioController, _addressController, _emergencyController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ──────────────────────────────── PHOTO PICKING ─────────────────────────
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PhotoOptionsSheet(
        onCamera: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        onRemove: _pickedImagePath != null
            ? () { Navigator.pop(context); _removePhoto(); }
            : null,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Step 1: Let user pick from camera / gallery (no spinner yet)
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;

      // Step 2: Copy image to permanent app documents directory IMMEDIATELY
      //         so it survives app restarts and temp file cleanup.
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_photos');
      if (!await profileDir.exists()) await profileDir.create(recursive: true);

      final ext = picked.path.split('.').last.toLowerCase();
      final permanentPath = '${profileDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(permanentPath);

      // Step 3: Show in UI instantly — no waiting for anything
      if (!mounted) return;
      setState(() {
        _pickedImagePath = permanentPath;
        UserSession.profileImagePath = permanentPath;
        _hasChanges = true;
      });

      // Save locally right away
      await UserSession.save();
      
      if (mounted) {
        Provider.of<UserSessionProvider>(context, listen: false).updateSession();
        _showSnack('Profile photo updated!', isError: false);
      }

      // Step 4: Upload to backend silently in the background (fire & forget)
      // User is NOT blocked by this — it runs after UI is already updated.
      unawaited(_uploadPhotoInBackground(permanentPath));

    } on PlatformException catch (e) {
      if (mounted) _showSnack('Permission denied: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) _showSnack('Could not save photo. Please try again.', isError: true);
    }
  }

  /// Uploads the photo to the backend quietly — does NOT block the UI or show errors.
  Future<void> _uploadPhotoInBackground(String path) async {
    try {
      await ApiService.uploadProfilePhoto(path);
      // Optionally log success; no UI update needed
    } catch (_) {
      // Silent — the photo is already saved locally
    }
  }

  void _removePhoto() {
    setState(() {
      _pickedImagePath = null;
      UserSession.profileImagePath = null;
      _hasChanges = true;
    });
    UserSession.save();
    _showSnack('Profile photo removed.', isError: false);
  }

  // ──────────────────────────────── DOB PICKER ────────────────────────────
  Future<void> _pickDateOfBirth() async {
    final initial = () {
      try {
        if (_dobController.text.isNotEmpty) {
          return DateTime.parse(_dobController.text);
        }
      } catch (_) {}
      return DateTime(1990, 1, 1);
    }();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _primary, onPrimary: Colors.white),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _hasChanges = true;
      });
    }
  }

  // ──────────────────────────────── SAVE ──────────────────────────────────
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final dob = _dobController.text.trim().isEmpty ? null : _dobController.text.trim();
    final bio = _bioController.text.trim().isEmpty ? null : _bioController.text.trim();
    final address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
    final emergency = _emergencyController.text.trim().isEmpty ? null : _emergencyController.text.trim();

    final sessionProvider = Provider.of<UserSessionProvider>(context, listen: false);

    // Update local session immediately
    UserSession.userName = name;
    UserSession.userEmail = email;
    UserSession.userPhone = phone;
    UserSession.dateOfBirth = dob;
    UserSession.gender = _selectedGender;
    UserSession.bio = bio;
    UserSession.address = address;
    UserSession.emergencyContact = emergency;
    await UserSession.save();
    
    // Notify provider of local updates
    sessionProvider.updateSession();

    // Try backend update
    bool apiSuccess = false;
    try {
      apiSuccess = await ApiService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dob,
        gender: _selectedGender,
        bio: bio,
        address: address,
        emergencyContact: emergency,
      );
    } catch (_) {}

    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });

    if (mounted) {
      _showSnack(
        apiSuccess
            ? 'Profile updated successfully!'
            : 'Saved locally. Changes will sync when online.',
        isError: false,
      );
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ──────────────────────────────── BUILD ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!UserSession.isLoggedIn) {
      return _buildLoginRequired();
    }
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    icon: Icons.badge_outlined,
                    title: 'Basic Information',
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'e.g. John Doe',
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Name is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+255 700 000 000',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    icon: Icons.cake_outlined,
                    title: 'Personal Details',
                    children: [
                      GestureDetector(
                        onTap: _pickDateOfBirth,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _dobController,
                            label: 'Date of Birth',
                            hint: 'Tap to select',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                      _buildGenderDropdown(),
                      _buildTextField(
                        controller: _bioController,
                        label: 'About Me',
                        hint: 'A short bio about yourself...',
                        icon: Icons.edit_note_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  _buildSectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Address & Contact',
                    children: [
                      _buildTextField(
                        controller: _addressController,
                        label: 'Home Address',
                        hint: 'Street, City, Country',
                        icon: Icons.home_outlined,
                        maxLines: 2,
                      ),
                      _buildTextField(
                        controller: _emergencyController,
                        label: 'Emergency Contact',
                        hint: 'Name & phone number',
                        icon: Icons.emergency_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────── SLIVER APP BAR ────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Personal Information',
        style: TextStyle(color: _textMain, fontWeight: FontWeight.bold, fontSize: 17),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHero(),
      ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFC62828), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 44),
            GestureDetector(
              onTapDown: (_) => _avatarAnimCtrl.forward(),
              onTapUp: (_) { _avatarAnimCtrl.reverse(); _showPhotoOptions(); },
              onTapCancel: () => _avatarAnimCtrl.reverse(),
              child: ScaleTransition(
                scale: _avatarScaleAnim,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white12,
                        backgroundImage: _resolveProfileImage(),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: _primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              UserSession.userName ?? 'Your Name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              UserSession.userEmail ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────── SECTION CARD ──────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textMain,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _border, height: 24, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────── TEXT FIELD ────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _textMain, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: _textSub),
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.8),
        ),
      ),
    );
  }

  // ──────────────────────────────── GENDER DROPDOWN ───────────────────────
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      hint: const Text('Select gender', style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13)),
      style: const TextStyle(fontSize: 14, color: _textMain, fontWeight: FontWeight.w500),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSub),
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.wc_outlined, size: 20, color: _textSub),
        labelStyle: const TextStyle(color: _textSub, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      items: _genderOptions.map((g) => DropdownMenuItem(
        value: g,
        child: Text(g, style: const TextStyle(fontSize: 14, color: _textMain)),
      )).toList(),
      onChanged: (val) {
        setState(() {
          _selectedGender = val;
          _hasChanges = true;
        });
      },
    );
  }

  // ──────────────────────────────── SAVE BUTTON ───────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _hasChanges
              ? const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFEF5350)])
              : null,
          color: _hasChanges ? null : Colors.grey.shade300,
          boxShadow: _hasChanges
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _hasChanges && !_isSaving ? _saveChanges : null,
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save_rounded,
                          color: _hasChanges ? Colors.white : Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            color: _hasChanges ? Colors.white : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────── LOGIN REQUIRED ────────────────────────
  Widget _buildLoginRequired() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0.5,
        title: const Text(
          'Personal Information',
          style: TextStyle(color: _textMain, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _textMain),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 56, color: _primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign In Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textMain),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please sign in to manage your personal profile and account information.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSub, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
                    ).then((_) => setState(() {
                      _nameController.text = UserSession.userName ?? '';
                      _emailController.text = UserSession.userEmail ?? '';
                      _phoneController.text = UserSession.userPhone ?? '';
                      _dobController.text = UserSession.dateOfBirth ?? '';
                      _bioController.text = UserSession.bio ?? '';
                      _addressController.text = UserSession.address ?? '';
                      _emergencyController.text = UserSession.emergencyContact ?? '';
                      _selectedGender = UserSession.gender;
                      _pickedImagePath = UserSession.profileImagePath;
                    }));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log In / Register',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────── BOTTOM SHEET ──────────────────────────────
class _PhotoOptionsSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _PhotoOptionsSheet({
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionTile(
              context,
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              sublabel: 'Use your camera',
              onTap: onCamera,
              color: const Color(0xFF1565C0),
            ),
            _buildDivider(),
            _buildOptionTile(
              context,
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              sublabel: 'Pick from your photos',
              onTap: onGallery,
              color: const Color(0xFF2E7D32),
            ),
            if (onRemove != null) ...[
              _buildDivider(),
              _buildOptionTile(
                context,
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                sublabel: 'Revert to default avatar',
                onTap: onRemove!,
                color: Colors.red.shade700,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
      subtitle: Text(sublabel, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 24, endIndent: 24);
}
