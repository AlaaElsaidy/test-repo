// lib/screens/doctor/doctor_activities_screen.dart
// Doctor — Editable Activities (Face Recognition / Photo Memory) + To‑Do
// - Face: choose local image, edit prompt, options, correct answer, hints (relation + first letter)
//   • Shows "Correct answer: <...>" and ✓ mark beside the correct option
//   • Save instead of Skip
// - Photo: choose local image, edit questions/options/correct
//   • Shows "Correct answer: <...>" and ✓ mark beside the correct option
//   • Save instead of Skip
// - To‑Do: same as patient (SharedPreferences + local notifications with tz UTC)

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
// To‑Do deps (same as patient)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../theme/app_theme.dart';

/// =============================================================
/// Models (same as patient demo)
/// =============================================================
class FaceItem {
  final String id;
  final String imageUrl;
  final String name;
  final String relation;

  const FaceItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.relation,
  });
}

class PhotoItem {
  final String id;
  final String imageUrl;
  final List<String> persons; // who appears in photo
  final String? place;
  final int? year;

  const PhotoItem({
    required this.id,
    required this.imageUrl,
    required this.persons,
    this.place,
    this.year,
  });
}

class Question {
  final String prompt;
  final List<String> options; // exactly 3
  final int correctIndex;

  const Question({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
}

/// Demo data (same as patient)
class ActivityRepository {
  static List<FaceItem> demoFaces() => const [
        FaceItem(
            id: 'f1',
            imageUrl: 'https://i.pravatar.cc/300?img=12',
            name: 'Emily',
            relation: 'Daughter'),
        FaceItem(
            id: 'f2',
            imageUrl: 'https://i.pravatar.cc/300?img=32',
            name: 'Ahmed',
            relation: 'Son'),
        FaceItem(
            id: 'f3',
            imageUrl: 'https://i.pravatar.cc/300?img=47',
            name: 'Sara',
            relation: 'Sister'),
        FaceItem(
            id: 'f4',
            imageUrl: 'https://i.pravatar.cc/300?img=66',
            name: 'Omar',
            relation: 'Grandson'),
        FaceItem(
            id: 'f5',
            imageUrl: 'https://i.pravatar.cc/300?img=15',
            name: 'Laila',
            relation: 'Friend'),
        FaceItem(
            id: 'f6',
            imageUrl: 'https://i.pravatar.cc/300?img=5',
            name: 'Youssef',
            relation: 'Brother'),
      ];

  static List<PhotoItem> demoPhotos() => const [
        PhotoItem(
          id: 'p1',
          imageUrl:
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
          persons: ['Emily', 'Ahmed'],
          place: 'Alexandria',
          year: 1998,
        ),
        PhotoItem(
          id: 'p2',
          imageUrl:
              'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800',
          persons: ['Sara'],
          place: 'Cairo',
          year: 2005,
        ),
        PhotoItem(
          id: 'p3',
          imageUrl:
              'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=800',
          persons: ['Omar', 'Laila'],
          place: 'Giza',
          year: 2010,
        ),
        PhotoItem(
          id: 'p4',
          imageUrl:
              'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=801',
          persons: ['Youssef'],
          place: 'Hurghada',
          year: 2012,
        ),
      ];
}

/// =============================================================
/// Doctor Edit Store (SharedPreferences) + Image helper
/// =============================================================
class _DoctorEditStore {
  static const _faceKey = 'doctor_face_edits_v1';
  static const _photoKey = 'doctor_photo_edits_v1';

  static Future<Map<String, FaceEdit>> loadFace() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_faceKey);
    if (s == null) return {};
    final raw = Map<String, dynamic>.from(jsonDecode(s));
    return raw.map(
        (k, v) => MapEntry(k, FaceEdit.fromMap(Map<String, dynamic>.from(v))));
  }

  static Future<void> saveFace(Map<String, FaceEdit> map) async {
    final sp = await SharedPreferences.getInstance();
    final enc = jsonEncode(map.map((k, v) => MapEntry(k, v.toMap())));
    await sp.setString(_faceKey, enc);
  }

  static Future<Map<String, PhotoEdit>> loadPhoto() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_photoKey);
    if (s == null) return {};
    final raw = Map<String, dynamic>.from(jsonDecode(s));
    return raw.map(
        (k, v) => MapEntry(k, PhotoEdit.fromMap(Map<String, dynamic>.from(v))));
  }

  static Future<void> savePhoto(Map<String, PhotoEdit> map) async {
    final sp = await SharedPreferences.getInstance();
    final enc = jsonEncode(map.map((k, v) => MapEntry(k, v.toMap())));
    await sp.setString(_photoKey, enc);
  }

  static Map<String, dynamic> questionToMap(Question q) => {
        'prompt': q.prompt,
        'options': q.options,
        'correctIndex': q.correctIndex,
      };

  static Question questionFromMap(Map<String, dynamic> m) => Question(
        prompt: m['prompt'] ?? '',
        options: (m['options'] as List).cast<String>(),
        correctIndex: m['correctIndex'] ?? 0,
      );
}

class _ImageHelper {
  static Future<String?> copyToAppDir(XFile x, {required String subdir}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final target = Directory('${dir.path}/$subdir');
      if (!target.existsSync()) target.createSync(recursive: true);
      String ext = '.jpg';
      final dot = x.path.lastIndexOf('.');
      if (dot != -1) ext = x.path.substring(dot);
      final fileName = 'img_${DateTime.now().microsecondsSinceEpoch}$ext';
      final newPath = '${target.path}/$fileName';
      final f = await File(x.path).copy(newPath);
      return f.path;
    } catch (e) {
      debugPrint('copyToAppDir error: $e');
      return null;
    }
  }
}

/// =============================================================
/// Edit models
/// =============================================================
class FaceEdit {
  final String id;
  final String? imagePath; // local override
  final String prompt; // default: Who is this?
  final List<String> options; // length 3
  final int correctIndex;
  final bool hintRelation;
  final bool hintFirstLetter;

  const FaceEdit({
    required this.id,
    required this.imagePath,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.hintRelation,
    required this.hintFirstLetter,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'hintRelation': hintRelation,
        'hintFirstLetter': hintFirstLetter,
      };

  static FaceEdit fromMap(Map<String, dynamic> m) => FaceEdit(
        id: m['id'],
        imagePath: m['imagePath'],
        prompt: m['prompt'] ?? 'Who is this?',
        options: (m['options'] as List).cast<String>(),
        correctIndex: m['correctIndex'] ?? 0,
        hintRelation: m['hintRelation'] ?? true,
        hintFirstLetter: m['hintFirstLetter'] ?? true,
      );

  FaceEdit copyWith({
    String? imagePath,
    String? prompt,
    List<String>? options,
    int? correctIndex,
    bool? hintRelation,
    bool? hintFirstLetter,
  }) {
    return FaceEdit(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      hintRelation: hintRelation ?? this.hintRelation,
      hintFirstLetter: hintFirstLetter ?? this.hintFirstLetter,
    );
  }
}

class PhotoEdit {
  final String id;
  final String? imagePath; // local override
  final List<Question> questions; // per photo

  const PhotoEdit({
    required this.id,
    required this.imagePath,
    required this.questions,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'questions': questions.map(_DoctorEditStore.questionToMap).toList(),
      };

  static PhotoEdit fromMap(Map<String, dynamic> m) => PhotoEdit(
        id: m['id'],
        imagePath: m['imagePath'],
        questions: ((m['questions'] as List?) ?? [])
            .map((q) =>
                _DoctorEditStore.questionFromMap(Map<String, dynamic>.from(q)))
            .toList(),
      );

  PhotoEdit copyWith({String? imagePath, List<Question>? questions}) =>
      PhotoEdit(
        id: id,
        imagePath: imagePath ?? this.imagePath,
        questions: questions ?? this.questions,
      );
}

/// =============================================================
/// Shared UI
/// =============================================================
enum _BtnState { idle, correct, wrong, disabled }

class _OptionButton extends StatelessWidget {
  final String text;
  final _BtnState state;
  final VoidCallback onTap;
  final bool showCheck; // show check icon beside correct option
  final bool isCorrect; // is this option the correct one (visual hint)

  const _OptionButton({
    required this.text,
    required this.state,
    required this.onTap,
    this.showCheck = false,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (state) {
      case _BtnState.correct:
        bg = Colors.green;
        fg = Colors.white;
        break;
      case _BtnState.wrong:
        bg = Colors.red;
        fg = Colors.white;
        break;
      case _BtnState.disabled:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade600;
        break;
      default:
        bg = AppTheme.teal600;
        fg = Colors.white;
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state == _BtnState.idle ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: state == _BtnState.idle ? AppTheme.teal600 : bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showCheck && isCorrect) ...[
              const Icon(Icons.check_circle, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(text, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  final Question? initial;

  const _QuestionDialog({this.initial});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _prompt;
  final _opt1 = TextEditingController();
  final _opt2 = TextEditingController();
  final _opt3 = TextEditingController();
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.initial?.prompt ?? '');
    final opts = widget.initial?.options ?? const ['', '', ''];
    if (opts.isNotEmpty) _opt1.text = opts[0];
    if (opts.length > 1) _opt2.text = opts[1];
    if (opts.length > 2) _opt3.text = opts[2];
    _correct = widget.initial?.correctIndex ?? 0;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _opt1.dispose();
    _opt2.dispose();
    _opt3.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final options = [_opt1.text.trim(), _opt2.text.trim(), _opt3.text.trim()];
    Navigator.pop(
      context,
      Question(
          prompt: _prompt.text.trim(),
          options: options,
          correctIndex: _correct),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit question' : 'Add question'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _prompt,
                decoration: const InputDecoration(labelText: 'Question prompt'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < 3; i++)
                Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correct,
                      onChanged: (v) => setState(() => _correct = v ?? 0),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: [_opt1, _opt2, _opt3][i],
                        decoration:
                            InputDecoration(labelText: 'Option ${i + 1}'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}

/// =============================================================
/// Doctor Home: open edit versions + To‑Do card
/// =============================================================
class DoctorActivitiesScreen extends StatelessWidget {
  const DoctorActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faces = ActivityRepository.demoFaces();
    final photos = ActivityRepository.demoPhotos();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doctor — Edit Activities'),
          backgroundColor: AppTheme.teal600,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Editable Activities',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900)),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'Face Recognition (Edit)',
              description: 'Change image, edit question, options, and hints',
              icon: Icons.face_retouching_natural,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditableFaceRecognitionScreen(items: faces),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'Photo Memory (Edit)',
              description: 'Change photo and edit questions/options',
              icon: Icons.photo_library,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditablePhotoMemoryScreen(items: photos),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'To‑Do (Schedule)',
              description: 'Plan daily activities with reminders',
              icon: Icons.schedule,
              color: AppTheme.teal600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TodoScheduleScreen()),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.teal900)),
              const SizedBox(height: 4),
              Text(description,
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.gray600)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// =============================================================
/// Editable Face Recognition (Doctor)
/// =============================================================
class EditableFaceRecognitionScreen extends StatefulWidget {
  final List<FaceItem> items;

  const EditableFaceRecognitionScreen({super.key, required this.items});

  @override
  State<EditableFaceRecognitionScreen> createState() =>
      _EditableFaceRecognitionScreenState();
}

class _EditableFaceRecognitionScreenState
    extends State<EditableFaceRecognitionScreen> {
  late final List<FaceItem> _faces;
  int _index = 0;
  int _selectedIdx = -1;

  // Edit state for current item
  String _prompt = 'Who is this?';
  List<String> _options = const [];
  int _correctIdx = 0;
  bool _hintRelation = true;
  bool _hintFirstLetter = true;
  bool _hintShown = false;
  File? _localImageFile;

  final _picker = ImagePicker();

  Map<String, FaceEdit> _edits = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _faces = List.of(widget.items);
    _loadEdits();
  }

  Future<void> _loadEdits() async {
    _edits = await _DoctorEditStore.loadFace();
    _prepareRound(init: true);
    setState(() => _loaded = true);
  }

  void _prepareRound({bool init = false}) {
    _selectedIdx = -1;
    _hintShown = false;

    final current = _faces[_index];
    final edit = _edits[current.id];

    _prompt = edit?.prompt ?? 'Who is this?';
    _hintRelation = edit?.hintRelation ?? true;
    _hintFirstLetter = edit?.hintFirstLetter ?? true;
    _localImageFile =
        (edit?.imagePath?.isNotEmpty ?? false) ? File(edit!.imagePath!) : null;

    if (edit != null && edit.options.length == 3) {
      _options = List.of(edit.options);
      _correctIdx = edit.correctIndex;
    } else {
      // generate defaults: current name + 2 distractors
      final rnd = Random();
      final namesPool = _faces
          .where((f) => f.name != current.name)
          .map((f) => f.name)
          .toList()
        ..shuffle(rnd);
      final distractors = namesPool.take(2).toList();
      final all = [current.name, ...distractors]..shuffle(rnd);
      _options = all;
      _correctIdx = _options.indexOf(current.name);
    }
    if (!init) setState(() {});
  }

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (src == null) return;
    try {
      final x = await _picker.pickImage(
          source: src, imageQuality: 85, maxWidth: 1280);
      if (x == null) return;
      final saved =
          await _ImageHelper.copyToAppDir(x, subdir: 'doctor_edits/faces');
      if (saved != null) setState(() => _localImageFile = File(saved));
    } catch (e) {
      debugPrint('pick face image err: $e');
    }
  }

  Future<void> _editPromptAndOptions() async {
    final q = await showDialog<Question>(
      context: context,
      builder: (_) => _QuestionDialog(
        initial: Question(
            prompt: _prompt, options: _options, correctIndex: _correctIdx),
      ),
    );
    if (q == null) return;
    setState(() {
      _prompt = q.prompt;
      _options = q.options;
      _correctIdx = q.correctIndex;
    });
  }

  Future<void> _saveCurrent() async {
    final current = _faces[_index];
    final edit = FaceEdit(
      id: current.id,
      imagePath: _localImageFile?.path,
      prompt: _prompt,
      options: _options,
      correctIndex: _correctIdx,
      hintRelation: _hintRelation,
      hintFirstLetter: _hintFirstLetter,
    );
    _edits[current.id] = edit;
    await _DoctorEditStore.saveFace(_edits);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved changes')));
    }
  }

  void _onSelect(int i) {
    if (_selectedIdx != -1) return;
    setState(() => _selectedIdx = i);
  }

  void _next() {
    if (_index < _faces.length - 1) {
      _index++;
      _prepareRound();
    } else {
      Navigator.pop(context);
    }
  }

  _BtnState _btnState(int i) {
    if (_selectedIdx == -1) return _BtnState.idle;
    if (i == _correctIdx) return _BtnState.correct;
    if (i == _selectedIdx && i != _correctIdx) return _BtnState.wrong;
    return _BtnState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final current = _faces[_index];
    final correctText = (_options.isNotEmpty &&
            _correctIdx >= 0 &&
            _correctIdx < _options.length)
        ? _options[_correctIdx]
        : '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition (Edit)'),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Item ${_index + 1}/${_faces.length}',
                              style: const TextStyle(
                                  color: AppTheme.teal900,
                                  fontWeight: FontWeight.w600)),
                          const Text('Edit mode',
                              style: TextStyle(color: AppTheme.gray600)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Image + edit
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: _localImageFile != null
                                  ? Image.file(_localImageFile!,
                                      fit: BoxFit.cover)
                                  : Image.network(
                                      current.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppTheme.teal50,
                                        child: const Center(
                                            child:
                                                Icon(Icons.person, size: 64)),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _pickImage,
                              icon: const Icon(Icons.edit),
                              label: const Text('Change'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Hints config
                      const Text('Hints',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.teal900)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show relation as hint'),
                        value: _hintRelation,
                        onChanged: (v) => setState(() => _hintRelation = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show first letter of name'),
                        value: _hintFirstLetter,
                        onChanged: (v) => setState(() => _hintFirstLetter = v),
                      ),
                      if (_hintShown)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppTheme.teal50,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'Hint: ${_hintRelation ? current.relation : '-'}'
                            ' • ${_hintFirstLetter ? 'Name starts with "${current.name[0]}"' : ''}',
                            style: const TextStyle(color: AppTheme.teal900),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Question title with edit
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _prompt,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.teal900),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _editPromptAndOptions,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Q/Options'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Correct answer label
                      Text('Correct answer: $correctText',
                          style: const TextStyle(color: AppTheme.gray600)),
                      const SizedBox(height: 8),

                      // Options
                      for (var i = 0; i < _options.length; i++) ...[
                        _OptionButton(
                          text: _options[i],
                          state: _btnState(i),
                          onTap: () => _onSelect(i),
                          showCheck: true,
                          isCorrect: i == _correctIdx,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ]),
              ),
            ),

            // bottom controls: Hint + Save + Next
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _hintShown = !_hintShown),
                      icon: const Icon(Icons.lightbulb),
                      label: const Text('Hint'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saveCurrent, // Save instead of Skip
                      child: const Text('Save'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================
/// Editable Photo Memory (Doctor)
/// =============================================================
class EditablePhotoMemoryScreen extends StatefulWidget {
  final List<PhotoItem> items;

  const EditablePhotoMemoryScreen({super.key, required this.items});

  @override
  State<EditablePhotoMemoryScreen> createState() =>
      _EditablePhotoMemoryScreenState();
}

class _EditablePhotoMemoryScreenState extends State<EditablePhotoMemoryScreen> {
  late final List<PhotoItem> _photos;
  late List<List<Question>> _qByPhoto; // editable per photo

  int _photoIdx = 0;
  int _qIdx = 0;
  int _selectedIdx = -1;

  final _picker = ImagePicker();
  File? _localImageFile;

  Map<String, PhotoEdit> _edits = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.items);
    _qByPhoto = _generateDefaults(_photos);
    _loadEdits();
  }

  Future<void> _loadEdits() async {
    _edits = await _DoctorEditStore.loadPhoto();
    // Apply overrides if exist
    for (int i = 0; i < _photos.length; i++) {
      final id = _photos[i].id;
      final e = _edits[id];
      if (e != null && e.questions.isNotEmpty) {
        _qByPhoto[i] = e.questions;
      }
    }
    // load image override for first photo
    final first = _edits[_photos[_photoIdx].id];
    _localImageFile = (first?.imagePath?.isNotEmpty ?? false)
        ? File(first!.imagePath!)
        : null;
    setState(() => _loaded = true);
  }

  List<List<Question>> _generateDefaults(List<PhotoItem> items) {
    final rnd = Random();
    final allNames = <String>{for (final p in items) ...p.persons}.toList();
    final allPlaces =
        items.map((e) => e.place).whereType<String>().toSet().toList();

    List<List<Question>> out = [];
    for (final item in items) {
      final perPhoto = <Question>[];

      // Who is in this photo?
      if (item.persons.isNotEmpty) {
        final correct = item.persons[rnd.nextInt(item.persons.length)];
        final pool = allNames.where((n) => !item.persons.contains(n)).toList()
          ..shuffle(rnd);
        final List<String> distractors = [];
        for (final n in pool) {
          if (distractors.length < 2 && n != correct) distractors.add(n);
        }
        final fallback = ['A friend', 'A relative', 'A neighbor'];
        var fi = 0;
        while (distractors.length < 2) {
          final cand = fallback[fi % fallback.length];
          if (cand != correct && !distractors.contains(cand))
            distractors.add(cand);
          fi++;
        }
        final options = [correct, ...distractors]..shuffle(rnd);
        perPhoto.add(Question(
          prompt: 'Who is in this photo?',
          options: options,
          correctIndex: options.indexOf(correct),
        ));
      }

      // Where was this taken?
      if ((item.place ?? '').isNotEmpty) {
        final correct = item.place!;
        final pool = allPlaces.where((p) => p != correct).toList()
          ..shuffle(rnd);
        final List<String> distractors = [];
        for (final p in pool) {
          if (distractors.length < 2 && p != correct) distractors.add(p);
        }
        final fallback = ['At home', 'At the park', 'Downtown'];
        var fi = 0;
        while (distractors.length < 2) {
          final cand = fallback[fi % fallback.length];
          if (cand != correct && !distractors.contains(cand))
            distractors.add(cand);
          fi++;
        }
        final options = [correct, ...distractors]..shuffle(rnd);
        perPhoto.add(Question(
          prompt: 'Where was this taken?',
          options: options,
          correctIndex: options.indexOf(correct),
        ));
      }

      out.add(perPhoto.take(2).toList());
    }
    return out;
  }

  Question get _currentQ => _qByPhoto[_photoIdx][_qIdx];

  void _onSelect(int i) {
    if (_selectedIdx != -1) return;
    setState(() => _selectedIdx = i);
  }

  void _next() {
    _selectedIdx = -1;
    if (_qIdx < _qByPhoto[_photoIdx].length - 1) {
      _qIdx++;
    } else {
      if (_photoIdx < _photos.length - 1) {
        _photoIdx++;
        _qIdx = 0;
        // load image override for next
        final e = _edits[_photos[_photoIdx].id];
        _localImageFile =
            (e?.imagePath?.isNotEmpty ?? false) ? File(e!.imagePath!) : null;
      } else {
        Navigator.pop(context);
        return;
      }
    }
    setState(() {});
  }

  Future<void> _editCurrentQuestion() async {
    final q = await showDialog<Question>(
      context: context,
      builder: (_) => _QuestionDialog(initial: _currentQ),
    );
    if (q == null) return;
    setState(() {
      _qByPhoto[_photoIdx][_qIdx] = q;
    });
  }

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (src == null) return;
    try {
      final x = await _picker.pickImage(
          source: src, imageQuality: 85, maxWidth: 1600);
      if (x == null) return;
      final saved =
          await _ImageHelper.copyToAppDir(x, subdir: 'doctor_edits/photos');
      if (saved != null) setState(() => _localImageFile = File(saved));
    } catch (e) {
      debugPrint('pick photo image err: $e');
    }
  }

  Future<void> _saveCurrentPhotoEdits() async {
    final id = _photos[_photoIdx].id;
    final edit = PhotoEdit(
        id: id,
        imagePath: _localImageFile?.path,
        questions: List.of(_qByPhoto[_photoIdx]));
    _edits[id] = edit;
    await _DoctorEditStore.savePhoto(_edits);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved changes')));
    }
  }

  _BtnState _btnState(int i) {
    if (_selectedIdx == -1) return _BtnState.idle;
    if (i == _currentQ.correctIndex) return _BtnState.correct;
    if (i == _selectedIdx && i != _currentQ.correctIndex)
      return _BtnState.wrong;
    return _BtnState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final photo = _photos[_photoIdx];
    final correctText = (_currentQ.options.isNotEmpty &&
            _currentQ.correctIndex >= 0 &&
            _currentQ.correctIndex < _currentQ.options.length)
        ? _currentQ.options[_currentQ.correctIndex]
        : '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Memory (Edit)'),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Photo ${_photoIdx + 1}/${_photos.length}',
                              style: const TextStyle(
                                  color: AppTheme.teal900,
                                  fontWeight: FontWeight.w600)),
                          const Text('Edit mode',
                              style: TextStyle(color: AppTheme.gray600)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Photo + edit
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: _localImageFile != null
                                  ? Image.file(_localImageFile!,
                                      fit: BoxFit.cover)
                                  : Image.network(
                                      photo.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppTheme.teal50,
                                        child: const Center(
                                            child: Icon(Icons.photo, size: 64)),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _pickImage,
                              icon: const Icon(Icons.edit),
                              label: const Text('Change'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Question + edit
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentQ.prompt,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.teal900),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _editCurrentQuestion,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Q/Options'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Correct answer label
                      Text('Correct answer: $correctText',
                          style: const TextStyle(color: AppTheme.gray600)),
                      const SizedBox(height: 8),

                      // Options
                      for (var i = 0; i < _currentQ.options.length; i++) ...[
                        _OptionButton(
                          text: _currentQ.options[i],
                          state: _btnState(i),
                          onTap: () => _onSelect(i),
                          showCheck: true,
                          isCorrect: i == _currentQ.correctIndex,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ]),
              ),
            ),

            // Bottom controls: Save + Next (Skip replaced with Save)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    TextButton(
                        onPressed: _saveCurrentPhotoEdits,
                        child: const Text('Save')),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================
/// To‑Do (same as patient) — Models + Storage + Notifications (UTC)
/// =============================================================
class TodoTask {
  final int id; // also notification id
  final String title;
  final String description;
  final DateTime scheduledAt; // date + time
  final bool done;

  const TodoTask({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledAt,
    this.done = false,
  });

  TodoTask copyWith(
      {String? title, String? description, DateTime? scheduledAt, bool? done}) {
    return TodoTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'done': done,
      };

  static TodoTask fromMap(Map<String, dynamic> m) => TodoTask(
        id: m['id'],
        title: m['title'],
        description: m['description'],
        scheduledAt: DateTime.parse(m['scheduledAt']),
        done: m['done'] ?? false,
      );
}

class TodoStore {
  static const _key = 'todo_tasks_v1';

  static Future<List<TodoTask>> load() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_key);
    if (s == null) return [];
    final list = (jsonDecode(s) as List)
        .cast<Map>()
        .map((m) => TodoTask.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    return list;
  }

  static Future<void> save(List<TodoTask> tasks) async {
    final sp = await SharedPreferences.getInstance();
    final list = tasks.map((t) => t.toMap()).toList();
    await sp.setString(_key, jsonEncode(list));
  }
}

class LocalNotifHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const init = InitializationSettings(android: android, iOS: iOS);
    await _plugin.initialize(init);

    // Android 13+: ask notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Use UTC (no flutter_native_timezone)
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    _inited = true;
  }

  static NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'todo_channel',
      'Reminders',
      channelDescription: 'To-Do reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const ios = DarwinNotificationDetails(presentSound: true);
    return const NotificationDetails(android: android, iOS: ios);
  }

  static Future<void> schedule(TodoTask t) async {
    if (t.scheduledAt.isBefore(DateTime.now())) return;
    await _plugin.cancel(t.id); // avoid duplicates

    // Convert selected local time to UTC and schedule
    final DateTime utc = t.scheduledAt.toUtc();
    final tz.TZDateTime scheduled = tz.TZDateTime.from(utc, tz.UTC);

    await _plugin.zonedSchedule(
      t.id,
      'Activity Reminder',
      '${t.title} • ${_fmtTime(t.scheduledAt)}',
      scheduled,
      _details(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(t.toMap()),
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class TodoScheduleScreen extends StatefulWidget {
  const TodoScheduleScreen({super.key});

  @override
  State<TodoScheduleScreen> createState() => _TodoScheduleScreenState();
}

class _TodoScheduleScreenState extends State<TodoScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<TodoTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await LocalNotifHelper.init();
    _tasks = await TodoStore.load();
    // Reschedule future tasks
    for (final t in _tasks) {
      await LocalNotifHelper.schedule(t);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<TodoTask> get _today {
    final now = DateTime.now();
    return _tasks
        .where((t) =>
            t.scheduledAt.year == now.year &&
            t.scheduledAt.month == now.month &&
            t.scheduledAt.day == now.day)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> _addOrEdit({TodoTask? original}) async {
    final result = await showModalBottomSheet<TodoTask>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _TaskEditorSheet(initial: original),
    );
    if (result == null) return;

    if (original == null) {
      _tasks.add(result);
    } else {
      final i = _tasks.indexWhere((x) => x.id == original.id);
      if (i != -1) _tasks[i] = result;
      await LocalNotifHelper.cancel(original.id);
    }
    await LocalNotifHelper.schedule(result);
    await TodoStore.save(_tasks);
    if (mounted) setState(() {});
  }

  Future<void> _toggleDone(TodoTask t) async {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    final newVal = !t.done;
    _tasks[i] = t.copyWith(done: newVal);
    if (newVal) await LocalNotifHelper.cancel(t.id);
    await TodoStore.save(_tasks);
    if (mounted) setState(() {});
  }

  Future<void> _delete(TodoTask t) async {
    _tasks.removeWhere((x) => x.id == t.id);
    await LocalNotifHelper.cancel(t.id);
    await TodoStore.save(_tasks);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = [..._tasks]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('To‑Do Schedule'),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _TaskList(
            tasks: _today,
            emptyText: 'No activities scheduled for today.',
            onToggle: _toggleDone,
            onEdit: (t) => _addOrEdit(original: t),
            onDelete: _delete,
          ),
          _TaskList(
            tasks: all,
            emptyText: 'No scheduled activities yet.',
            onToggle: _toggleDone,
            onEdit: (t) => _addOrEdit(original: t),
            onDelete: _delete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TodoTask> tasks;
  final String emptyText;
  final Future<void> Function(TodoTask) onToggle;
  final Future<void> Function(TodoTask) onDelete;
  final Future<void> Function(TodoTask) onEdit;

  const _TaskList({
    required this.tasks,
    required this.emptyText,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: AppTheme.gray600),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final t = tasks[i];
        final time =
            '${t.scheduledAt.hour.toString().padLeft(2, '0')}:${t.scheduledAt.minute.toString().padLeft(2, '0')}';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.done ? AppTheme.gray50 : AppTheme.teal50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.teal600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.teal900,
                          decoration:
                              t.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.description.isEmpty ? '-' : t.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.scheduledAt.year}/${t.scheduledAt.month.toString().padLeft(2, '0')}/${t.scheduledAt.day.toString().padLeft(2, '0')} • $time',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.gray500),
                      ),
                    ]),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: t.done ? 'Mark as not done' : 'Mark as done',
                onPressed: () => onToggle(t),
                icon: Icon(
                    t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: t.done ? Colors.green : AppTheme.gray500),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => onEdit(t),
                icon: const Icon(Icons.edit, color: AppTheme.gray500),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => onDelete(t),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskEditorSheet extends StatefulWidget {
  final TodoTask? initial;

  const _TaskEditorSheet({this.initial});

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _desc;
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(minutes: 2));
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _desc = TextEditingController(text: widget.initial?.description ?? '');
    _date =
        widget.initial?.scheduledAt ?? DateTime(now.year, now.month, now.day);
    _time = widget.initial != null
        ? TimeOfDay(
            hour: widget.initial!.scheduledAt.hour,
            minute: widget.initial!.scheduledAt.minute)
        : TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final scheduled =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final task = (widget.initial ??
            TodoTask(
              id: DateTime.now().millisecondsSinceEpoch %
                  2147483647, // 32-bit safe
              title: _title.text.trim(),
              description: _desc.text.trim(),
              scheduledAt: scheduled,
            ))
        .copyWith(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      scheduledAt: scheduled,
    );
    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    height: 4,
                    width: 48,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                const Text('Add / Edit Activity',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Activity title',
                    prefixIcon: Icon(Icons.edit),
                    filled: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes),
                    filled: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                            '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_time.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.teal600,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}