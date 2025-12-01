import 'dart:io';

import 'package:alzcare/config/router/routes.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';

class PatientProfileScreen extends StatefulWidget {
  // Patient is optional: if you still call const PatientProfileScreen(), it uses default demo data.
  final Patient patient;
  final ValueChanged<Patient>? onSave;

  const PatientProfileScreen({
    super.key,
    Patient? patient,
    this.onSave,
  }) : patient = patient ??
            const Patient(
              name: 'Margaret Smith',
              age: 72,
              // kept in model only; not shown in UI
              phone: '+1 (555) 123-4567',
              email: 'margaret.smith@email.com',
              address: '123 Oak Street, Springfield',
              emergencyContact: EmergencyContact(
                name: 'Emily Smith',
                relation: 'Daughter',
                phone: '+1 (555) 987-6543',
              ),
            );

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final PatientService _patientService = PatientService();
  final UserService _userService = UserService();
  final PatientFamilyService _patientFamilyService = PatientFamilyService();
  final AuthService _authService = AuthService();

  late Patient _patient;
  bool _editing = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  String? _patientRowId;
  String? _patientUserId;
  String? _errorMessage;

  // Controllers (no age in UI)
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emergencyPhoneCtrl;

  FamilyContact? _familyContact;

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;

    if (_patient.avatarPath != null && _patient.avatarPath!.isNotEmpty) {
      final f = File(_patient.avatarPath!);
      if (f.existsSync()) _avatarFile = f;
    }

    _nameCtrl = TextEditingController(text: _patient.name);
    _phoneCtrl = TextEditingController(text: _patient.phone);
    _emailCtrl = TextEditingController(text: _patient.email);
    _addressCtrl = TextEditingController(text: _patient.address);
    _emergencyPhoneCtrl = TextEditingController(
      text: _patient.emergencyContact?.phone ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _editing = !_editing);

  void _resetForm() {
    _nameCtrl.text = _patient.name;
    _phoneCtrl.text = _patient.phone;
    _emailCtrl.text = _patient.email;
    _addressCtrl.text = _patient.address;
    _emergencyPhoneCtrl.text =
        _patient.emergencyContact?.phone ?? _familyContact?.phone ?? '';
  }

  Future<void> _loadProfileData() async {
    final patientUid = SharedPrefsHelper.getString("patientUid") ??
        SharedPrefsHelper.getString("userId");

    if (patientUid == null) {
      setState(() {
        _errorMessage = tr(
            'Patient account not found', 'تعذّر العثور على حساب المريض');
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _patientUserId = patientUid;
    });

    try {
      final patientMap = await _patientService.getPatientByUserId(patientUid);
      final userMap = await _userService.getUser(patientUid);

      String? patientRowId = patientMap?['id'] as String?;

      FamilyContact? familyContact;
      if (patientRowId != null) {
        try {
          final relations =
              await _patientFamilyService.getFamilyMembersByPatient(
            patientRowId,
          );
          if (relations.isNotEmpty) {
            final first = relations.first;
            final relative = first['family_members'] as Map<String, dynamic>?;
            familyContact = FamilyContact(
              id: relative?['id'] as String?,
              name: (relative?['name'] as String?) ?? '',
              relation: (first['relation_type'] as String?) ?? '',
              phone: (relative?['phone'] as String?) ??
                  (patientMap?['phone_emergency'] as String? ?? ''),
            );
          }
        } catch (_) {
          // ignore family load errors, fall back to phone emergency below
        }
      }

      if (familyContact == null) {
        final emergencyPhone =
            (patientMap?['phone_emergency'] as String?)?.trim();
        if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
          familyContact = FamilyContact(
            id: null,
            name: '',
            relation: '',
            phone: emergencyPhone,
          );
        }
      }

      final dynamic ageRaw = patientMap?['age'];
      final int resolvedAge = ageRaw is int
          ? ageRaw
          : int.tryParse(ageRaw?.toString() ?? '') ?? _patient.age;
      final String? userPhone =
          (userMap?['phone'] as String?)?.trim();
      final String? userEmail = (userMap?['email'] as String?);
      final String? patientAddress =
          (patientMap?['home_address'] as String?)?.trim();
      final String? patientPhoto = (patientMap?['photo_url'] as String?);
      final String? patientName = (patientMap?['name'] as String?);
      final String? userName = (userMap?['name'] as String?);

      final updatedPatient = Patient(
        name: patientName ?? userName ?? _patient.name,
        age: resolvedAge,
        phone: (userPhone != null && userPhone.isNotEmpty)
            ? userPhone
            : _patient.phone,
        email: userEmail ?? _patient.email,
        address: patientAddress?.isNotEmpty == true
            ? patientAddress!
            : _patient.address,
        emergencyContact: familyContact != null
            ? EmergencyContact(
                name: familyContact.name,
                relation: familyContact.relation,
                phone: familyContact.phone,
              )
            : _patient.emergencyContact,
        avatarPath: patientPhoto ?? _patient.avatarPath,
      );

      if (!mounted) return;
      setState(() {
        _patient = updatedPatient;
        _patientRowId = patientRowId ?? _patientRowId;
        _familyContact = familyContact;
        _nameCtrl.text = updatedPatient.name;
        _phoneCtrl.text = updatedPatient.phone;
        _emailCtrl.text = updatedPatient.email;
        _addressCtrl.text = updatedPatient.address;
        _emergencyPhoneCtrl.text = familyContact?.phone.isNotEmpty == true
            ? familyContact!.phone
            : (updatedPatient.emergencyContact?.phone ?? '');
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            tr('Failed to load profile', 'فشل تحميل الملف الشخصي');
        _loading = false;
      });
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  ImageProvider? _buildAvatarImage(Patient patient) {
    if (_avatarFile != null) return FileImage(_avatarFile!);
    final path = patient.avatarPath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  Future<void> _uploadAvatar(File file) async {
    if (_patientUserId == null) {
      _showMessage(tr('Patient account not ready', 'حساب المريض غير جاهز'),
          error: true);
      return;
    }
    setState(() => _uploadingPhoto = true);
    try {
      final url = await _patientService.uploadPatientPhoto(
        _patientUserId!,
        file,
      );
      if (_patientRowId != null) {
        await _patientService
            .updatePatient(_patientRowId!, {'photo_url': url});
      }
      // خزن رابط الصورة محلياً عشان الصفحات التانية (زي لعبة الذاكرة) تقدر تستخدمه فوراً
      await SharedPrefsHelper.saveString('patientPhotoUrl', url);
      setState(() {
        _patient = _patient.copyWith(avatarPath: url);
      });
    } catch (e) {
      _showMessage(
        tr('Failed to upload photo', 'فشل رفع الصورة'),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
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
        setState(() => _avatarFile = file); // show immediately
        await _uploadAvatar(file);
      }
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _removeAvatar() async {
    Navigator.of(context).maybePop();
    setState(() => _avatarFile = null);
    if (_patientRowId == null) return;
    try {
      await _patientService.updatePatient(_patientRowId!, {'photo_url': null});
      setState(() {
        _patient = _patient.copyWith(avatarPath: null);
      });
    } catch (e) {
      _showMessage(
        tr('Failed to remove photo', 'تعذّر حذف الصورة'),
        error: true,
      );
    }
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
              title: Text(tr('Take a photo', 'التقاط صورة')),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(tr('Choose from gallery', 'اختيار من المعرض')),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_avatarFile != null ||
                (_patient.avatarPath?.isNotEmpty ?? false))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(tr('Remove photo', 'حذف الصورة')),
                onTap: _removeAvatar,
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // Confirm before logout
  Future<void> _onLogoutTap() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Logout', 'تسجيل الخروج')),
        content: Text(tr('Are you sure you want to logout?',
            'هل أنت متأكد أنك تريد تسجيل الخروج؟')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Cancel', 'إلغاء'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Logout', 'تسجيل الخروج'))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await _authService.signOut();
      } catch (_) {}
      await SharedPrefsHelper.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientUserId == null) {
      _showMessage(
        tr('Patient account not ready', 'حساب المريض غير جاهز'),
        error: true,
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final emergencyPhone = _emergencyPhoneCtrl.text.trim();
    setState(() => _saving = true);
    try {
      // خزن رقم الطوارئ محلياً عشان صفحة التتبع تقدر تستخدمه فوراً
      if (emergencyPhone.isNotEmpty) {
        await SharedPrefsHelper.saveString(
            'patientEmergencyPhone', emergencyPhone);
      }

      final futures = <Future<void>>[
        _userService.updateUser(_patientUserId!, {
          'name': name,
          'phone': phone,
          'email': email,
        }),
      ];

      if (_patientRowId != null) {
        futures.add(_patientService.updatePatient(_patientRowId!, {
          'name': name,
          'home_address': address,
          'phone_emergency':
              emergencyPhone.isNotEmpty ? emergencyPhone : null,
        }));
      }

      await Future.wait(futures);

      final updated = _patient.copyWith(
        name: name,
        phone: phone,
        email: email,
        address: address,
        emergencyContact: emergencyPhone.isNotEmpty
            ? EmergencyContact(
                name: _familyContact?.name ?? _patient.emergencyContact?.name ?? '',
                relation: _familyContact?.relation ??
                    _patient.emergencyContact?.relation ??
                    '',
                phone: emergencyPhone,
              )
            : null,
      );

      if (!mounted) return;
      setState(() {
        _patient = updated;
        _editing = false;
      });
      widget.onSave?.call(updated);

      _showMessage(tr('Profile updated successfully ✅',
          'تم تحديث الملف الشخصي بنجاح ✅'));
    } catch (e) {
      _showMessage(
        tr('Failed to save changes', 'فشل حفظ التعديلات'),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;

    if (_loading) {
      return Directionality(
        textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
        child: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Directionality(
        textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    child: Text(tr('Retry', 'إعادة المحاولة')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final avatarImage = _buildAvatarImage(p);

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header (smaller, no age)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.tealGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? const Icon(Icons.person,
                                    size: 40, color: AppTheme.teal500)
                                : null,
                          ),
                          if (_uploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _uploadingPhoto ? null : _openAvatarSheet,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit,
                                      size: 16, color: AppTheme.teal600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Actions: Edit / Save / Cancel
                Align(
                  alignment: AlignmentDirectional.centerEnd,
              child: _editing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  _resetForm();
                                  setState(() => _editing = false);
                                },
                          child: Text(tr('Cancel', 'إلغاء')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(tr('Save', 'حفظ')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.teal600,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                          onPressed: _toggleEdit,
                          icon: const Icon(Icons.edit),
                          label: Text(tr('Edit', 'تعديل')),
                        ),
                ),

                const SizedBox(height: 12),

                // Contact Information (view or edit)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Contact Information', 'بيانات التواصل'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_editing) ...[
                          _buildTextField(
                            controller: _nameCtrl,
                            label: tr('Full name', 'الاسم الكامل'),
                            icon: Icons.person,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? tr('Name is required', 'الاسم مطلوب')
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _phoneCtrl,
                            label: tr('Phone', 'الهاتف'),
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? tr('Phone is required', 'رقم الهاتف مطلوب')
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _emailCtrl,
                            label: tr('Email', 'البريد الإلكتروني'),
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return tr('Email is required',
                                    'البريد الإلكتروني مطلوب');
                              if (!v.contains('@'))
                                return tr('Enter a valid email',
                                    'أدخل بريدًا إلكترونيًا صحيحًا');
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _addressCtrl,
                            label: tr('Address', 'العنوان'),
                            icon: Icons.location_on,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? tr('Address is required', 'العنوان مطلوب')
                                : null,
                          ),
                        ] else ...[
                          _InfoRow(
                              icon: Icons.person,
                              label: tr('Name', 'الاسم'),
                              value: p.name,
                              color: AppTheme.teal500),
                          const SizedBox(height: 10),
                          _InfoRow(
                              icon: Icons.phone,
                              label: tr('Phone', 'الهاتف'),
                              value: p.phone,
                              color: AppTheme.teal500),
                          const SizedBox(height: 10),
                          _InfoRow(
                              icon: Icons.email,
                              label: tr('Email', 'البريد الإلكتروني'),
                              value: p.email,
                              color: AppTheme.cyan500),
                          const SizedBox(height: 10),
                          _InfoRow(
                              icon: Icons.location_on,
                              label: tr('Address', 'العنوان'),
                              value: p.address,
                              color: AppTheme.teal500),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Emergency Contact (view or edit)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Emergency Contact', 'جهة الطوارئ'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_editing) ...[
                        _buildTextField(
                          controller: _emergencyPhoneCtrl,
                          label: tr('Emergency phone number', 'رقم هاتف جهة الطوارئ'),
                          icon: Icons.phone_in_talk,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_familyContact != null)
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.people,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _familyContact!.name.isNotEmpty
                                        ? _familyContact!.name
                                        : tr('Linked family member',
                                            'القريب المرتبط'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    _familyContact!.relation.isNotEmpty
                                        ? _familyContact!.relation
                                        : tr('Family member', 'قريب'),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.orange),
                                  ),
                                  Text(
                                    _emergencyPhoneCtrl.text.isNotEmpty
                                        ? _emergencyPhoneCtrl.text
                                        : (_familyContact!.phone.isNotEmpty
                                            ? _familyContact!.phone
                                            : tr(
                                                'No phone available',
                                                'لا يوجد رقم هاتف',
                                              )),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          tr(
                              'No family member is linked yet. Please ask your family to send an invitation.',
                              'لا يوجد قريب مرتبط حتى الآن، يرجى طلب دعوة من العائلة.'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Logout with confirmation
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _onLogoutTap,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      tr('Logout', 'تسجيل الخروج'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.teal600),
        filled: true,
        fillColor: AppTheme.teal50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

// Read-only row
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.gray500)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppTheme.teal900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FamilyContact {
  final String? id;
  final String name;
  final String relation;
  final String phone;

  const FamilyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });
}

// Models
class Patient {
  final String name;
  final int age; // not shown in UI
  final String phone;
  final String email;
  final String address;
  final EmergencyContact? emergencyContact;
  final String? avatarPath;

  const Patient({
    required this.name,
    required this.age,
    required this.phone,
    required this.email,
    required this.address,
    this.emergencyContact,
    this.avatarPath,
  });

  Patient copyWith({
    String? name,
    int? age,
    String? phone,
    String? email,
    String? address,
    EmergencyContact? emergencyContact,
    String? avatarPath,
  }) {
    return Patient(
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
}