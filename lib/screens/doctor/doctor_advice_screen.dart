import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

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

  // Stored advice (local)
  final List<Advice> _adviceList = [];

  static const _fakeBaseLink =
      'https://example.com/advice'; // TODO: backend link

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
    return true;
  }

  Advice _buildAdvice({required bool sent}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return Advice(
      id: id,
      tips: List<String>.from(_tips),
      videoPath: _videoXFile?.path,
      createdAt: DateTime.now(),
      sent: sent,
    );
  }

  void _clearForm() {
    _tips.clear();
    _tipCtrl.clear();
    _addingTip = false;
    _removeVideo();
    setState(() {});
  }

  void _saveDraft() {
    if (!_validateForm()) return;
    final advice = _buildAdvice(sent: false);
    setState(() => _adviceList.insert(0, advice));
    _clearForm();
    _snack('Saved as draft');
  }

  void _sendToRelative() {
    if (!_validateForm()) return;

    final advice = _buildAdvice(sent: true);
    setState(() => _adviceList.insert(0, advice));

    final link = '$_fakeBaseLink/${advice.id}';
    final tipsText =
        advice.tips.isEmpty ? '' : advice.tips.map((t) => '• $t').join('\n');
    final shareText = 'Doctor Advice'
        '${tipsText.isEmpty ? '' : '\n\nTips:\n$tipsText'}'
        '\n\nOpen advice: $link';

    if (advice.videoPath != null) {
      Share.shareXFiles(
        [XFile(advice.videoPath!)],
        text: shareText,
        subject: 'Doctor Advice',
      );
    } else {
      Share.share(shareText, subject: 'Doctor Advice');
    }

    _clearForm();
  }

  void _shareExisting(Advice advice) {
    final link = '$_fakeBaseLink/${advice.id}';
    final tipsText =
        advice.tips.isEmpty ? '' : advice.tips.map((t) => '• $t').join('\n');
    final shareText = 'Doctor Advice'
        '${tipsText.isEmpty ? '' : '\n\nTips:\n$tipsText'}'
        '\n\nOpen advice: $link';

    if (advice.videoPath != null) {
      Share.shareXFiles(
        [XFile(advice.videoPath!)],
        text: shareText,
        subject: 'Doctor Advice',
      );
    } else {
      Share.share(shareText, subject: 'Doctor Advice');
    }
  }

  // ============== UI helpers ==============
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _openAdviceDetails(Advice a) {
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
                        color: (a.sent ? Colors.green : Colors.orange)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.sent ? 'Sent' : 'Draft',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: a.sent ? Colors.green : Colors.orange,
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
                const SizedBox(height: 12),
                if (a.videoPath != null)
                  _InlineVideoPreview(path: a.videoPath!),
                if (a.videoPath != null) const SizedBox(height: 12),
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
                    if (narrow) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _shareExisting(a),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.teal600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _shareExisting(a),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.teal600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
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
                        'Upload a video from phone and share with relatives',
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
                onPressed: (i) => setState(() => _tabIndex = i),
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
        if (narrow) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _sendToRelative,
                  icon: const Icon(Icons.send),
                  label: const Text('Send to relative',
                      overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  icon: const Icon(Icons.save_alt),
                  label:
                      const Text('Save Draft', overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _sendToRelative,
                  icon: const Icon(Icons.send),
                  label: const Text('Send to relative',
                      overflow: TextOverflow.ellipsis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdviceList() {
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
              'Add a few tips, attach a video, then share with relatives.',
              style: TextStyle(fontSize: 12, color: AppTheme.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _adviceList.map((a) {
        final snippet = a.tips.isNotEmpty ? a.tips.first : 'No tips';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openAdviceDetails(a),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.teal50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        a.videoPath == null
                            ? Icons.description
                            : Icons.play_circle,
                        color: AppTheme.teal600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Doctor Advice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.teal900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.gray600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (a.sent ? Colors.green : Colors.orange)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  a.sent ? 'Sent' : 'Draft',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        a.sent ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.access_time,
                                  size: 14, color: AppTheme.gray500),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(a.createdAt),
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.gray500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (a.videoPath != null) ...[
                                const Icon(Icons.videocam,
                                    size: 14, color: AppTheme.gray600),
                                const SizedBox(width: 4),
                                const Text('Video',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.gray600)),
                                const SizedBox(width: 10),
                              ],
                              const Icon(Icons.tips_and_updates,
                                  size: 14, color: AppTheme.gray600),
                              const SizedBox(width: 4),
                              Text('${a.tips.length} tip(s)',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.gray600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Share',
                      onPressed: () => _shareExisting(a),
                      icon: const Icon(Icons.share, color: AppTheme.gray600),
                    ),
                  ],
                ),
              ),
            ),
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

class Advice {
  final String id;
  final List<String> tips;
  final String? videoPath;
  final DateTime createdAt;
  final bool sent;

  Advice({
    required this.id,
    required this.tips,
    required this.videoPath,
    required this.createdAt,
    required this.sent,
  });

  Advice copyWith({
    String? id,
    List<String>? tips,
    String? videoPath,
    DateTime? createdAt,
    bool? sent,
  }) {
    return Advice(
      id: id ?? this.id,
      tips: tips ?? this.tips,
      videoPath: videoPath ?? this.videoPath,
      createdAt: createdAt ?? this.createdAt,
      sent: sent ?? this.sent,
    );
  }
}