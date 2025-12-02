import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/router/routes.dart';
import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/auth-service.dart';
import '../../core/supabase/supabase-config.dart';
import '../../core/supabase/supabase-service.dart';
import '../../theme/app_theme.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late Future<_DoctorProfileData?> _profileFuture;
  final UserService _userService = UserService();
  final FamilyMemberService _familyService = FamilyMemberService();
  final DoctorService _doctorService = DoctorService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final _client = SupabaseConfig.client;

  File? _avatarFile;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_DoctorProfileData?> _loadProfile() async {
    try {
      final doctorId =
          SharedPrefsHelper.getString('doctorUid') ?? SharedPrefsHelper.getString('userId');
      if (doctorId == null) return null;

      final user = await _userService.getUser(doctorId);
      final families = await _familyService.getFamiliesByDoctor(doctorId);
      final doctorRow = await _doctorService.getDoctorById(doctorId);

       // احسب عدد المرضى النشطين بنفس منطق الداشبورد (عدد المرضى الفريدين)
      final Set<String> patientIds = {};
      for (final family in families) {
        final familyId = family['id'] as String?;
        if (familyId == null) continue;
        final relations = await _client
            .from('patient_family_relations')
            .select('patient_id')
            .eq('family_member_id', familyId);
        for (final rel in relations as List) {
          final pid = rel['patient_id'] as String?;
          if (pid != null) patientIds.add(pid);
        }
      }

      return _DoctorProfileData(
        doctorId: doctorId,
        user: user,
        families: families,
        activePatients: patientIds.length,
        totalCases: patientIds.length,
        photoUrl: doctorRow?['photo'] as String?,
      );
    } catch (e) {
      debugPrint('Failed to load doctor profile: $e');
      return null;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ImageProvider? _buildAvatarImage(_DoctorProfileData data) {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    final url = data.photoUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    final file = File(url);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  Future<void> _uploadAvatar(_DoctorProfileData data, File file) async {
    setState(() => _uploadingPhoto = true);
    try {
      final url = await _doctorService.uploadDoctorPhoto(data.doctorId, file);
      await SharedPrefsHelper.saveString('doctorPhotoUrl', url);
      if (!mounted) return;
      setState(() {
        _avatarFile = file;
        _profileFuture = _loadProfile();
      });
      _showSnack('Profile photo updated');
    } catch (e) {
      _showSnack('Failed to upload photo: $e');
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _pickImage(_DoctorProfileData data, ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked != null) {
        final file = File(picked.path);
        await _uploadAvatar(data, file);
      }
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      _showSnack('Image pick error: $e');
    }
  }

  void _openAvatarSheet(_DoctorProfileData data) {
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
              onTap: () => _pickImage(data, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImage(data, ImageSource.gallery),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditContactSheet(_DoctorProfileData data) async {
    final nameCtrl = TextEditingController(text: data.name);
    final phoneCtrl = TextEditingController(text: data.phone ?? '');
    final emailCtrl = TextEditingController(text: data.email ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.teal900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final regex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!regex.hasMatch(value.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await _userService.updateUser(data.doctorId, {
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        _showSnack('Profile updated');
                        setState(() {
                          _profileFuture = _loadProfile();
                        });
                      }
                    } catch (e) {
                      _showSnack('Failed to update: $e');
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
    } catch (_) {}
    await SharedPrefsHelper.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_DoctorProfileData?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  const Text('Failed to load profile'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _profileFuture = _loadProfile();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          final avatarImage = _buildAvatarImage(data);

          return SingleChildScrollView(
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
                        clipBehavior: Clip.none,
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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _uploadingPhoto
                                    ? null
                                    : () => _openAvatarSheet(data),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _uploadingPhoto
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    AppTheme.teal600),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: AppTheme.teal600,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.specialty ?? 'Doctor',
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
                          data.experienceLabel,
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

                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                data.activePatients.toString(),
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
                                data.totalCases.toString(),
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
                              onPressed: () => _openEditContactSheet(data),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: data.phone ?? 'Add phone number',
                          color: AppTheme.teal500,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: data.email ?? 'Add email',
                          color: AppTheme.cyan500,
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
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
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
          );
        },
      ),
    );
  }
}

class _DoctorProfileData {
  final String doctorId;
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> families;
  final int activePatients;
  final int totalCases;
  final String? photoUrl;

  const _DoctorProfileData({
    required this.doctorId,
    required this.user,
    required this.families,
    required this.activePatients,
    required this.totalCases,
    this.photoUrl,
  });

  String get name => (user?['name'] as String?) ?? 'Doctor';
  String? get email => user?['email'] as String?;
  String? get phone => user?['phone'] as String?;
  String? get specialty => user?['specialty'] as String?;

  String get experienceLabel => 'Experience with Alzheimer\'s care';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.teal900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
