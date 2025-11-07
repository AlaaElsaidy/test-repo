import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _soundOn = true;
  bool _hapticsOn = true;
  bool _highContrast = false;
  double _scale = 1.0; // 0.9..1.5

  @override
  void initState() {
    super.initState();
    _initGame();
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

  void _initGame() {
    _cancelTimers();
    // Build values list
    final fullSet = [
      '🍓', '🍇', '🍎', '🍌', '🍊', '🥝',
      '🍉', '🍍', '🍐', '🍑', '🍒', '🍈',
      '🥕', '🌽', '🍆', '🍋', '🫐', '🥑', // احتياطي لو زودنا أزواج لاحقًا
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
        _feedback(matched: true);
        _flipped.clear();
        _lock = false;
        _checkWin();
      } else {
        _feedback(matched: false);
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
    } else {
      // single flip feedback
      if (_hapticsOn) HapticFeedback.lightImpact();
      if (_soundOn) SystemSound.play(SystemSoundType.click);
    }
  }

  void _feedback({required bool matched}) {
    if (_hapticsOn) {
      matched ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    }
    if (_soundOn) {
      matched
          ? SystemSound.play(SystemSoundType.click)
          : SystemSound.play(SystemSoundType.alert);
    }
  }

  void _checkWin() {
    final won = _cards.every((c) => c.matched);
    if (won) {
      // Stop game timer
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

  Color get _faceDownColor =>
      _highContrast ? Colors.blue.shade900 : AppTheme.teal600;

  double get _cardRadius => 16 * _scale;

  double get _emojiSize => 28 * _scale;

  @override
  Widget build(BuildContext context) {
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
                  CircleAvatar(
                    radius: 28 * _scale,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: const Icon(Icons.person,
                        color: AppTheme.teal600, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hi, Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Margaret Smith',
                          style: TextStyle(
                            color: Color(0xFFCFFAFE),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mode switcher menu icon optional
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Controls row: Mode + toggles + scale + contrast
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
                FilterChip(
                  label: Text(_soundOn ? 'Sound On' : 'Sound Off'),
                  selected: _soundOn,
                  onSelected: (v) => setState(() => _soundOn = v),
                  avatar: Icon(_soundOn ? Icons.volume_up : Icons.volume_off),
                ),
                FilterChip(
                  label: Text(_hapticsOn ? 'Haptics On' : 'Haptics Off'),
                  selected: _hapticsOn,
                  onSelected: (v) => setState(() => _hapticsOn = v),
                  avatar: const Icon(Icons.vibration),
                ),
                FilterChip(
                  label: const Text('High Contrast'),
                  selected: _highContrast,
                  onSelected: (v) => setState(() => _highContrast = v),
                  avatar: const Icon(Icons.tonality),
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