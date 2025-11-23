import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  late Patient _patient;
  bool _editing = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;

  // Controllers (no age in UI)
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  late final TextEditingController _emNameCtrl;
  late final TextEditingController _emRelationCtrl;
  late final TextEditingController _emPhoneCtrl;

  // Language (UI only, local to this screen)
  String _languageCode = 'en';

  bool get _isAr => _languageCode == 'ar';

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

    _emNameCtrl =
        TextEditingController(text: _patient.emergencyContact?.name ?? '');
    _emRelationCtrl =
        TextEditingController(text: _patient.emergencyContact?.relation ?? '');
    _emPhoneCtrl =
        TextEditingController(text: _patient.emergencyContact?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _emNameCtrl.dispose();
    _emRelationCtrl.dispose();
    _emPhoneCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _editing = !_editing);

  void _resetForm() {
    _nameCtrl.text = _patient.name;
    _phoneCtrl.text = _patient.phone;
    _emailCtrl.text = _patient.email;
    _addressCtrl.text = _patient.address;
    _emNameCtrl.text = _patient.emergencyContact?.name ?? '';
    _emRelationCtrl.text = _patient.emergencyContact?.relation ?? '';
    _emPhoneCtrl.text = _patient.emergencyContact?.phone ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path)); // show immediately
      }
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _removeAvatar() {
    setState(() => _avatarFile = null);
    Navigator.of(context).maybePop();
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
      Navigator.pop(context);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = _patient.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      emergencyContact: (_emNameCtrl.text.trim().isEmpty &&
              _emRelationCtrl.text.trim().isEmpty &&
              _emPhoneCtrl.text.trim().isEmpty)
          ? null
          : EmergencyContact(
              name: _emNameCtrl.text.trim(),
              relation: _emRelationCtrl.text.trim(),
              phone: _emPhoneCtrl.text.trim(),
            ),
      avatarPath: _avatarFile?.path,
    );

    setState(() {
      _patient = updated;
      _editing = false;
    });

    widget.onSave?.call(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(tr('Profile updated successfully ✅',
              'تم تحديث الملف الشخصي بنجاح ✅'))),
    );
  }

  // Language change (UI only)
  void _onLanguageChanged(String code) {
    setState(() => _languageCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;

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
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!)
                                : (p.avatarPath != null &&
                                        p.avatarPath!.isNotEmpty)
                                    ? FileImage(File(p.avatarPath!))
                                    : null,
                            child: (_avatarFile == null &&
                                    (p.avatarPath == null ||
                                        p.avatarPath!.isEmpty))
                                ? const Icon(Icons.person,
                                    size: 40, color: AppTheme.teal500)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _openAvatarSheet,
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
                              onPressed: () {
                                _resetForm();
                                setState(() => _editing = false);
                              },
                              child: Text(tr('Cancel', 'إلغاء')),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save),
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

                // Settings (with Language label fixed to single line)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.teal50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.settings,
                                  color: AppTheme.teal600),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr('Settings', 'الإعدادات'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.teal900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.language, color: AppTheme.teal600),
                            const SizedBox(width: 12),
                            // FIX: keep the label on one line
                            Expanded(
                              child: Text(
                                tr('Language', 'اللغة'),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ToggleButtons(
                              isSelected: [
                                _languageCode == 'en',
                                _languageCode == 'ar'
                              ],
                              onPressed: (i) =>
                                  _onLanguageChanged(i == 0 ? 'en' : 'ar'),
                              borderRadius: BorderRadius.circular(20),
                              constraints: const BoxConstraints(
                                  minHeight: 40, minWidth: 84),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('English'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('العربية'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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
                          controller: _emNameCtrl,
                          label: tr('Contact name', 'اسم جهة الاتصال'),
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _emRelationCtrl,
                          label: tr('Relation', 'الصلة'),
                          icon: Icons.diversity_2,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _emPhoneCtrl,
                          label: tr('Phone', 'الهاتف'),
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ] else ...[
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
                                    p.emergencyContact?.name ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    p.emergencyContact?.relation ?? '-',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.orange),
                                  ),
                                  Text(
                                    p.emergencyContact?.phone ?? '-',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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