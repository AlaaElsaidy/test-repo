import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/doctor_advice_model.dart';
import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/doctor-advice-service.dart';
import '../../core/supabase/supabase-service.dart';
import '../../theme/app_theme.dart';

class DoctorAdviceScreen extends StatefulWidget {
  const DoctorAdviceScreen({super.key});

  @override
  State<DoctorAdviceScreen> createState() => _DoctorAdviceScreenState();
}

class _DoctorAdviceScreenState extends State<DoctorAdviceScreen> {
  // Tabs: 0 = Create, 1 = My Advice
  int _tabIndex = 0;

  // Tips
  final _tipCtrl = TextEditingController();
  final _tipFocus = FocusNode();
  bool _addingTip = false;
  final List<String> _tips = [];

  // Video (Gallery only)
  final ImagePicker _picker = ImagePicker();
  XFile? _videoXFile;
  VideoPlayerController? _videoCtrl;

  final DoctorAdviceService _adviceService = DoctorAdviceService();
  final FamilyMemberService _familyService = FamilyMemberService();

  List<DoctorAdviceModel> _adviceList = [];
  List<Map<String, dynamic>> _families = [];
  String? _selectedFamilyId;
  String? _selectedPatientId;
  String? _doctorId;
  bool _loadingAdvice = true;
  bool _loadingFamilies = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final doctorId = SharedPrefsHelper.getString("userId");
    if (doctorId == null) {
      _snack('Doctor ID not found. Please login again.');
      setState(() {
        _loadingAdvice = false;
        _loadingFamilies = false;
      });
      return;
    }

    setState(() => _doctorId = doctorId);
    await Future.wait([_loadAdvice(doctorId), _loadFamilies(doctorId)]);
  }

  Future<void> _loadAdvice(String doctorId) async {
    try {
      final advices = await _adviceService.getAdviceByDoctor(doctorId);
      setState(() {
        _adviceList = advices;
        _loadingAdvice = false;
      });
    } catch (e) {
      _snack('Failed to load advice: $e');
      setState(() => _loadingAdvice = false);
    }
  }

  Future<void> _loadFamilies(String doctorId) async {
    try {
      final families = await _familyService.getFamiliesByDoctor(doctorId);
      setState(() {
        _families = families;
        if (families.isNotEmpty && _selectedFamilyId == null) {
          _selectedFamilyId = families.first['id'] as String?;
          _selectedPatientId = families.first['patient_id'] as String?;
        }
        _loadingFamilies = false;
      });
    } catch (e) {
      _snack('Failed to load families: $e');
      setState(() => _loadingFamilies = false);
    }
  }

  @override
  void dispose() {
    _tipCtrl.dispose();
    _tipFocus.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  // ================= Video =================
  Future<void> _pickVideoFromGallery() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (picked == null) return;

      _videoCtrl?.dispose();
      final controller = VideoPlayerController.file(File(picked.path));
      await controller.initialize();
      controller.setLooping(true);

      setState(() {
        _videoXFile = picked;
        _videoCtrl = controller;
      });
    } catch (e) {
      debugPrint('Pick video error: $e');
      _snack('Could not pick video');
    }
  }

  void _removeVideo() {
    _videoCtrl?.dispose();
    setState(() {
      _videoXFile = null;
      _videoCtrl = null;
    });
  }

  void _togglePlay() {
    if (_videoCtrl == null) return;
    setState(() {
      if (_videoCtrl!.value.isPlaying) {
        _videoCtrl!.pause();
      } else {
        _videoCtrl!.play();
      }
    });
  }

  // ================= Tips =================
  void _beginAddTip() {
    setState(() => _addingTip = true);
    Future.delayed(Duration.zero, () => _tipFocus.requestFocus());
  }

  void _addTip() {
    final t = _tipCtrl.text.trim();
    if (t.isEmpty) {
      _tipFocus.requestFocus();
      return;
    }
    setState(() {
      _tips.add(t);
      _tipCtrl.clear();
    });
    _tipFocus.requestFocus(); // يكمل كتابة بسرعة
  }

  void _cancelAddTip() {
    setState(() {
      _addingTip = false;
      _tipCtrl.clear();
    });
  }

  void _removeTipAt(int i) {
    setState(() => _tips.removeAt(i));
  }

  // ============== Save / Share ==============
  bool _validateForm() {
    if (_tips.isEmpty && _videoXFile == null) {
      _snack('Add at least one tip or attach a video');
      return false;
    }
    if (_selectedFamilyId == null) {
      _snack('Select a family member to receive the advice');
      return false;
    }
    return true;
  }

  void _clearForm() {
    _tips.clear();
    _tipCtrl.clear();
    _addingTip = false;
    _removeVideo();
    setState(() {});
  }

  Future<void> _sendToRelative() async {
    await _submitAdvice();
  }

  Future<void> _submitAdvice() async {
    if (!_validateForm()) return;
    if (_doctorId == null) {
      _snack('Doctor ID not found');
      return;
    }
    final familyId = _selectedFamilyId;
    if (familyId == null) {
      _snack('Select a family member');
      return;
    }

    setState(() => _sending = true);

    try {
      String? uploadedVideoUrl;
      if (_videoXFile != null) {
        try {
          uploadedVideoUrl = await _adviceService.uploadMedia(
            file: File(_videoXFile!.path),
            doctorId: _doctorId!,
            adviceId: DateTime.now().microsecondsSinceEpoch.toString(),
          );
        } catch (uploadError) {
          debugPrint('Video upload failed: $uploadError');
          // Continue without video - save advice without video URL
          _snack('Warning: Video upload failed, saving advice without video. Error: $uploadError');
        }
      }

      final advice = await _adviceService.createAdvice(
        doctorId: _doctorId!,
        familyMemberId: familyId,
        patientId: _selectedPatientId,
        tips: List<String>.from(_tips),
        videoUrl: uploadedVideoUrl,
        status: 'sent',
      );

      setState(() {
        _adviceList.insert(0, advice);
      });

      _snack('Advice sent successfully');
      _clearForm();
    } catch (e) {
      _snack('Failed to save advice: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _deleteAdvice(DoctorAdviceModel advice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Advice'),
        content: const Text('Are you sure you want to delete this advice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    
    try {
      // Delete from database first
      await _adviceService.deleteAdvice(advice.id);
      
      if (!mounted) return;
      
      // Remove from UI after successful deletion
      setState(() {
        _adviceList.removeWhere((a) => a.id == advice.id);
      });
      
      // Reload from database to ensure consistency
      if (_doctorId != null) {
        await _loadAdvice(_doctorId!);
      }
      
      _snack('Advice deleted successfully');
    } catch (e) {
      debugPrint('Delete advice error: $e');
      if (!mounted) return;
      _snack('Failed to delete advice: $e');
      
      // Reload to ensure UI is in sync with database
      if (_doctorId != null) {
        await _loadAdvice(_doctorId!);
      }
    }
  }

  Future<void> _openVideoUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _snack('Invalid video url');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack('Could not open video');
    }
  }

  String _familyName(String? id) {
    if (id == null) return 'Family';
    final match = _families.firstWhere(
      (f) => f['id'] == id,
      orElse: () => {},
    );
    return (match['name'] as String?) ?? 'Family';
  }

  // ============== UI helpers ==============
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _openAdviceDetails(DoctorAdviceModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(Icons.video_library,
                          color: AppTheme.teal600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Doctor Advice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.teal900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ((a.status == 'sent') ? Colors.green : Colors.orange)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.status == 'sent' ? 'Sent' : a.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: a.status == 'sent' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDate(a.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Family: ${_familyName(a.familyMemberId)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                ),
                const SizedBox(height: 12),
                if (a.videoUrl != null) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openVideoUrl(a.videoUrl!),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play video'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (a.tips.isNotEmpty) ...[
                  const Text(
                    'Tips',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.teal900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...a.tips.map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(
                                  fontSize: 18, color: AppTheme.teal600)),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppTheme.gray600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 380;
                    final deleteButton = SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteAdvice(a);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Advice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );

                    final closeButton = SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          closeButton,
                          const SizedBox(height: 8),
                          deleteButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: closeButton),
                        const SizedBox(width: 8),
                        Expanded(child: deleteButton),
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= Build =================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (no overflow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Doctor\'s Advice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.teal900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upload a video from phone and send to relatives',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.tealGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_information,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs
            Align(
              alignment: Alignment.centerLeft,
              child: ToggleButtons(
                isSelected: [_tabIndex == 0, _tabIndex == 1],
                onPressed: (i) {
                  setState(() => _tabIndex = i);
                  // Reload advice when switching to "My Advice" tab
                  if (i == 1 && _doctorId != null) {
                    _loadAdvice(_doctorId!);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Create')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('My Advice')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_tabIndex == 0) _buildCreateForm() else _buildAdviceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Advice',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.teal900),
            ),
            const SizedBox(height: 12),
            if (_loadingFamilies)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_families.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No family members assigned to you yet. Once a family is linked, you can send advice here.',
                  style: TextStyle(fontSize: 13, color: AppTheme.teal900),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedFamilyId,
                decoration: const InputDecoration(
                  labelText: 'Select family',
                  prefixIcon: Icon(Icons.family_restroom),
                  filled: true,
                ),
                items: _families
                    .map(
                      (f) => DropdownMenuItem(
                        value: f['id'] as String?,
                        child: Text(
                          (f['name'] as String?) ?? 'Family member',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFamilyId = value;
                    final match = _families.firstWhere(
                      (f) => f['id'] == value,
                      orElse: () => {},
                    );
                    _selectedPatientId = match['patient_id'] as String?;
                  });
                },
              ),
            const SizedBox(height: 12),

            // Tips section
            const Text(
              'Tips',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.teal900),
            ),
            const SizedBox(height: 8),
            _buildTipsInputResponsive(),

            if (_tips.isNotEmpty) const SizedBox(height: 8),
            if (_tips.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(
                  _tips.length,
                  (i) => Chip(
                    label: Text(_tips[i]),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTipAt(i),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Video picker / preview (Gallery only)
            if (_videoCtrl == null)
              _VideoPickerPlaceholder(onPick: _pickVideoFromGallery)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: _videoCtrl!.value.aspectRatio == 0
                        ? 16 / 9
                        : _videoCtrl!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoCtrl!),
                        Container(color: Colors.black26),
                        IconButton(
                          iconSize: 64,
                          color: Colors.white,
                          onPressed: _togglePlay,
                          icon: Icon(
                            _videoCtrl!.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickVideoFromGallery,
                        icon: const Icon(Icons.video_file),
                        label: const Text('Replace video'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _removeVideo,
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Remove',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Actions (responsive; no overflow)
            _buildActionsResponsive(),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsInputResponsive() {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 380;

        if (!_addingTip) {
          // زر كبير يبدأ الكتابة
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _beginAddTip,
              icon: const Icon(Icons.add),
              label: const Text('Add tip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        // حالة الكتابة: فورس على TextField + زر Add
        if (narrow) {
          return Column(
            children: [
              TextField(
                focusNode: _tipFocus,
                controller: _tipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Write a tip',
                  prefixIcon: Icon(Icons.lightbulb),
                  filled: true,
                ),
                onSubmitted: (_) => _addTip(),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _addTip,
                        icon: const Icon(Icons.check),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teal600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _cancelAddTip,
                        icon: const Icon(Icons.close),
                        label: const Text('Done'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // شاشات أوسع: صف واحد
        return Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: _tipFocus,
                controller: _tipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Write a tip',
                  prefixIcon: Icon(Icons.lightbulb),
                  filled: true,
                ),
                onSubmitted: (_) => _addTip(),
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 110),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addTip,
                  icon: const Icon(Icons.check),
                  label: const Text('Add', overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _cancelAddTip,
                icon: const Icon(Icons.close),
                label: const Text('Done'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionsResponsive() {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 380;
        final button = SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _sending || _families.isEmpty ? null : _sendToRelative,
            icon: const Icon(Icons.send),
            label: Text(
              _sending ? 'Sending...' : 'Send to relative',
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.teal600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

        if (narrow) {
          return button;
        }

        return Row(
          children: [
            Expanded(child: button),
          ],
        );
      },
    );
  }

  Widget _buildAdviceList() {
    if (_loadingAdvice) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_adviceList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Text(
              'No advice yet',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.teal900),
            ),
            SizedBox(height: 6),
            Text(
              'Add a few tips, attach a video, then send to relatives.',
              style: TextStyle(fontSize: 12, color: AppTheme.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _adviceList.map((a) {
        final firstTip = a.tips.isNotEmpty ? a.tips.first : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Family Name, Status, Time, and Delete
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Family Name and Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _familyName(a.familyMemberId),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.teal900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (a.status == 'sent'
                                            ? Colors.green
                                            : Colors.orange)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    a.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: a.status == 'sent'
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 16, color: AppTheme.gray500),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _formatDate(a.createdAt),
                                    style: const TextStyle(
                                        fontSize: 13, color: AppTheme.gray600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 22),
                                  onPressed: () => _deleteAdvice(a),
                                  tooltip: 'Delete advice',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Video Card (if video exists)
              if (a.videoUrl != null) ...[
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openVideoUrl(a.videoUrl!),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    size: 40,
                                    color: AppTheme.teal600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to play video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Tip Card (if tip exists)
              if (firstTip != null) ...[
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: AppTheme.teal50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.teal600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tip',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.teal600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                firstTip,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.teal900,
                                  height: 1.4,
                                ),
                              ),
                              if (a.tips.length > 1) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _openAdviceDetails(a),
                                  child: Text(
                                    'View all ${a.tips.length} tips',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.teal600,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // View Details Button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openAdviceDetails(a),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Full Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.teal600,
                    side: const BorderSide(color: AppTheme.teal200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ================== Widgets ==================

class _VideoPickerPlaceholder extends StatelessWidget {
  final VoidCallback onPick;

  const _VideoPickerPlaceholder({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.ondemand_video, size: 48, color: AppTheme.gray500),
          const SizedBox(height: 8),
          const Text(
            'Attach a video from your phone (optional)',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.teal900),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.video_library),
              label: const Text('Choose video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineVideoPreview extends StatefulWidget {
  final String path;

  const _InlineVideoPreview({required this.path});

  @override
  State<_InlineVideoPreview> createState() => _InlineVideoPreviewState();
}

class _InlineVideoPreviewState extends State<_InlineVideoPreview> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
    _ctrl?.setLooping(true);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _ctrl?.value.isInitialized ?? false;
    return AspectRatio(
      aspectRatio: initialized ? _ctrl!.value.aspectRatio : 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (initialized)
            VideoPlayer(_ctrl!)
          else
            Container(color: Colors.black12),
          Container(color: Colors.black26),
          IconButton(
            iconSize: 56,
            color: Colors.white,
            onPressed: () {
              if (!initialized) return;
              setState(() {
                if (_ctrl!.value.isPlaying) {
                  _ctrl!.pause();
                } else {
                  _ctrl!.play();
                }
              });
            },
            icon: Icon(initialized && _ctrl!.value.isPlaying
                ? Icons.pause_circle
                : Icons.play_circle),
          ),
        ],
      ),
    );
  }
}

// ================== Model ==================
