import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/supabase-service.dart';
import '../../theme/app_theme.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  final UserService _userService = UserService();

  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  String? _doctorId; // doctors.id
  String? _doctorUserId; // users.id

  String _name = 'Doctor';
  String _specialty = '';
  int? _yearsExperience;
  int? _activePatients;
  int? _totalCases;
  String? _photoUrl;

  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _hospitalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final userId =
          SharedPrefsHelper.getString("userId") ?? SharedPrefsHelper.getString("doctorUid");
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      _doctorUserId = userId;

      // Load doctor profile with joined user data
      final profile = await _doctorService.getDoctorProfile(userId);
      if (profile != null) {
        final users = profile['users'] as Map<String, dynamic>?;
        final specialty = profile['specialty'] as String?;
        final experience = profile['years_experience'];
        final hospital = profile['hospital'] as String?;
        final photoUrl = profile['photo_url'] as String?;

        _doctorId = profile['id'] as String?;
        _name = (users?['name'] as String?) ?? _name;
        _specialty = specialty ?? _specialty;
        if (experience is int) {
          _yearsExperience = experience;
        } else if (experience != null) {
          _yearsExperience = int.tryParse(experience.toString());
        }
        _photoUrl = photoUrl;

        _phoneCtrl.text = (users?['phone'] as String?) ?? '';
        _emailCtrl.text = (users?['email'] as String?) ?? '';
        _hospitalCtrl.text = hospital ?? '';
      }

      // Reuse counts from dashboard if needed is more complex; for now leave as demo or null-safe
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  ImageProvider? _buildAvatarImage() {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    if (_photoUrl == null || _photoUrl!.isEmpty) return null;
    if (_photoUrl!.startsWith('http')) return NetworkImage(_photoUrl!);
    final file = File(_photoUrl!);
    return file.existsSync() ? FileImage(file) : null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked != null) {
        final file = File(picked.path);
        setState(() => _avatarFile = file);
        await _uploadAvatar(file);
      }
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {}
  }

  Future<void> _uploadAvatar(File file) async {
    if (_doctorUserId == null) return;
    try {
      final url = await FamilyMemberService()
          .uploadFamilyPhoto(_doctorUserId!, file); // reuse bucket
      if (_doctorId != null) {
        await _doctorService.updateDoctor(_doctorId!, {'photo_url': url});
      }
      setState(() => _photoUrl = url);
    } catch (_) {}
  }

  void _openAvatarSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (_doctorUserId == null) return;
    setState(() => _saving = true);
    try {
      final phone = _phoneCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final hospital = _hospitalCtrl.text.trim();

      await _userService.updateUser(_doctorUserId!, {
        'phone': phone,
        'email': email,
      });

      if (_doctorId != null) {
        await _doctorService.updateDoctor(_doctorId!, {
          'hospital': hospital,
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final avatarImage = _buildAvatarImage();

    final experienceText = _yearsExperience != null
        ? '$_yearsExperience years experience'
        : 'Experience';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.teal500,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _openAvatarSheet,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: AppTheme.teal600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_specialty.isNotEmpty)
                    Text(
                      _specialty,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFCFFAFE),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      experienceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics (optional – can be wired later)
            if (_activePatients != null || _totalCases != null)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              (_activePatients ?? 0).toString(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.teal600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Active Patients',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              (_totalCases ?? 0).toString(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cyan600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Total Cases',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Contact Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        TextButton(
                          onPressed: _saving ? null : _saveContact,
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone),
                        labelText: 'Phone',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hospitalCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on),
                        labelText: 'Hospital',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _InfoRow لم يعد مستخدماً بعد تحويل المعلومات إلى حقول قابلة للتعديل، لذلك تمت إزالته.
