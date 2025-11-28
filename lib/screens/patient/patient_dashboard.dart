import 'dart:async';
import 'dart:io'; // ADDED
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ADDED

import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/supabase-service.dart';
import '../../theme/app_theme.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

enum GameMode { calm, challenge }

class _PatientDashboardState extends State<PatientDashboard> {
  // Config
  static const Duration _previewDuration = Duration(seconds: 30);
  static const int _pairsCount = 12; // 12 pairs = 24 cards
  static const int _challengeTotalSec = 150; // وقت التحدي بعد المعاينة

  // Game state
  late List<_MemoryCard> _cards;
  final List<int> _flipped = [];
  bool _lock = false;
  bool _previewing = false;
  int _previewLeft = _previewDuration.inSeconds;

  // Timers
  Timer? _previewTimer;
  Timer? _previewCountdown;
  Timer? _gameTimer;

  // Challenge mode timer
  int _timeLeft = _challengeTotalSec;

  // UX settings
  GameMode _mode = GameMode.calm;
  double _scale = 1.0; // 0.9..1.5

  // Avatar (pick from camera/gallery)
  final ImagePicker _picker = ImagePicker(); // ADDED
  File? _avatarFile; // ADDED

  // Patient info from Supabase
  String? _patientName;
  String? _patientPhotoUrl;
  bool _loadingPatient = false;

  @override
  void initState() {
    super.initState();
    _initGame();
    _loadPatientInfo();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _previewTimer?.cancel();
    _previewCountdown?.cancel();
    _gameTimer?.cancel();
  }

  Future<void> _loadPatientInfo() async {
    _loadingPatient = true;
    try {
      final patientUid = SharedPrefsHelper.getString("patientUid") ??
          SharedPrefsHelper.getString("userId");
      if (patientUid == null) {
        _loadingPatient = false;
        return;
      }

      final patientService = PatientService();
      final userService = UserService();

      final patientMap = await patientService.getPatientByUserId(patientUid);
      final userMap = await userService.getUser(patientUid);

      final String? patientName = patientMap?['name'] as String?;
      final String? userName = userMap?['name'] as String?;
      final String? photoUrl = patientMap?['photo_url'] as String?;

      if (!mounted) return;
      setState(() {
        _patientName = patientName ?? userName;
        _patientPhotoUrl = photoUrl;
        _loadingPatient = false;
      });
    } catch (e) {
      debugPrint('Failed to load patient info for dashboard: $e');
      if (!mounted) return;
      setState(() {
        _loadingPatient = false;
      });
    }
  }

  void _initGame() {
    _cancelTimers();
    // Build values list
    final fullSet = [
      '🍓',
      '🍇',
      '🍎',
      '🍌',
      '🍊',
      '🥝',
      '🍉',
      '🍍',
      '🍐',
      '🍑',
      '🍒',
      '🍈',
      '🥕',
      '🌽',
      '🍆',
      '🍋',
      '🫐',
      '🥑',
    ];
    final base = fullSet.take(_pairsCount).toList();
    final values = [...base, ...base]..shuffle(Random());

    // Reset state
    _cards = List.generate(
        values.length, (i) => _MemoryCard(value: values[i], revealed: true));
    _flipped.clear();
    _lock = true;
    _previewing = true;
    _previewLeft = _previewDuration.inSeconds;
    _timeLeft = _challengeTotalSec;

    setState(() {});

    // Preview countdown shown to user
    _previewCountdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_previewing || !mounted) {
        t.cancel();
        return;
      }
      setState(() => _previewLeft--);
    });

    // After preview, hide all and start game (and timer if challenge)
    _previewTimer = Timer(_previewDuration, () {
      if (!mounted) return;
      for (final c in _cards) {
        if (!c.matched) c.revealed = false;
      }
      _previewing = false;
      _lock = false;
      setState(() {});
      if (_mode == GameMode.challenge) _startChallengeTimer();
    });
  }

  void _startChallengeTimer() {
    _gameTimer?.cancel();
    _timeLeft = _challengeTotalSec;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_timeLeft <= 0) {
        t.cancel();
        _lock = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Time's up! Try again ⏳")),
        );
        setState(() {});
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  void _onTapCard(int index) {
    if (_lock || _previewing) return;

    final c = _cards[index];
    if (c.matched || c.revealed) return;

    setState(() => c.revealed = true);
    _flipped.add(index);

    if (_flipped.length == 2) {
      _lock = true;
      final i1 = _flipped[0], i2 = _flipped[1];
      final a = _cards[i1], b = _cards[i2];

      if (a.value == b.value) {
        setState(() {
          a.matched = true;
          b.matched = true;
        });
        _flipped.clear();
        _lock = false;
        _checkWin();
      } else {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            a.revealed = false;
            b.revealed = false;
          });
          _flipped.clear();
          _lock = false;
        });
      }
    }
  }

  void _checkWin() {
    final won = _cards.every((c) => c.matched);
    if (won) {
      _gameTimer?.cancel();

      int stars = 0;
      if (_mode == GameMode.challenge) {
        final ratio = _timeLeft / _challengeTotalSec;
        if (ratio >= 0.5) {
          stars = 3;
        } else if (ratio >= 0.2) {
          stars = 2;
        } else {
          stars = 1;
        }
      }
      final msg = _mode == GameMode.challenge
          ? "Well done! You matched all pairs 🎉  ${'⭐' * stars}"
          : "Well done! You matched all pairs 🎉";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  // UI helpers
  String _fmtTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _faceDownColor => AppTheme.teal600;

  double get _cardRadius => 16 * _scale;

  double get _emojiSize => 28 * _scale;

  // Avatar helpers
  void _openAvatarSheet() {
    // ADDED
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
            if (_avatarFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  setState(() => _avatarFile = null);
                  Navigator.of(context).maybePop();
                },
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // ADDED
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
      }
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? avatarImage;
    if (_avatarFile != null) {
      avatarImage = FileImage(_avatarFile!);
    } else if (_patientPhotoUrl != null && _patientPhotoUrl!.isNotEmpty) {
      if (_patientPhotoUrl!.startsWith('http')) {
        avatarImage = NetworkImage(_patientPhotoUrl!);
      } else {
        final file = File(_patientPhotoUrl!);
        avatarImage = file.existsSync() ? FileImage(file) : null;
      }
    } else {
      avatarImage = null;
    }

    final cardsCount = _cards.length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Avatar with picker
                  Stack(
                    // ADDED
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _openAvatarSheet,
                        child: CircleAvatar(
                          radius: 28 * _scale,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? const Icon(Icons.person,
                                  color: AppTheme.teal600, size: 32)
                              : null,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: AppTheme.teal600, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hi, Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _patientName ?? ' ',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCFFAFE),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Controls row: Mode + scale
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Calm'),
                  selected: _mode == GameMode.calm,
                  onSelected: (v) {
                    if (_mode != GameMode.calm) {
                      setState(() => _mode = GameMode.calm);
                      _initGame();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Challenge'),
                  selected: _mode == GameMode.challenge,
                  onSelected: (v) {
                    if (_mode != GameMode.challenge) {
                      setState(() => _mode = GameMode.challenge);
                      _initGame();
                    }
                  },
                ),
                ActionChip(
                  label: const Text('A-'),
                  onPressed: () =>
                      setState(() => _scale = (_scale - 0.1).clamp(0.9, 1.5)),
                ),
                ActionChip(
                  label: const Text('A+'),
                  onPressed: () =>
                      setState(() => _scale = (_scale + 0.1).clamp(0.9, 1.5)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Status rows: preview countdown OR challenge info
            if (_previewing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.visibility,
                        color: AppTheme.teal600, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Memorize the cards… ${_previewLeft}s',
                      style: const TextStyle(color: AppTheme.teal600),
                    ),
                  ],
                ),
              )
            else if (_mode == GameMode.challenge)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.teal600, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _fmtTime(_timeLeft),
                      style: const TextStyle(
                        color: AppTheme.teal600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ...List.generate(3, (i) {
                      final ratio = _timeLeft / _challengeTotalSec;
                      int starsNow = ratio >= 0.5 ? 3 : (ratio >= 0.2 ? 2 : 1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          i < starsNow ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cardsCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columns => 6 rows for 24 cards
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final c = _cards[index];
                final faceUp = c.revealed || c.matched;

                return GestureDetector(
                  onTap: () => _onTapCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: faceUp ? Colors.white : _faceDownColor,
                      borderRadius: BorderRadius.circular(_cardRadius),
                      boxShadow: faceUp
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: faceUp
                          ? Text(
                              c.value,
                              style: TextStyle(fontSize: _emojiSize),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Play Again
            Center(
              child: ElevatedButton.icon(
                onPressed: _initGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 28 * _scale,
                    vertical: 14 * _scale,
                  ),
                  shape: const StadiumBorder(),
                  elevation: 4,
                  shadowColor: AppTheme.teal600.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard {
  final String value;
  bool revealed;
  bool matched;
  _MemoryCard({
    required this.value,
    this.revealed = false,
    this.matched = false,
  });
}