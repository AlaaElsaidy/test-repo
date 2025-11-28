import 'package:flutter/material.dart';
import '../ai/lobna_voice_controller.dart';
import '../theme/app_theme.dart';

/// Floating action button for Lobna voice assistant
class LobnaListenButton extends StatefulWidget {
  final LobnaVoiceController controller;
  final VoidCallback? onTap;

  const LobnaListenButton({
    super.key,
    required this.controller,
    this.onTap,
  });

  @override
  State<LobnaListenButton> createState() => _LobnaListenButtonState();
}

class _LobnaListenButtonState extends State<LobnaListenButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    widget.controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    final isListening = widget.controller.state == LobnaState.listening;
    if (_isListening != isListening) {
      setState(() {
        _isListening = isListening;
      });
      if (isListening) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  Future<void> _handleTap() async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    if (_isListening) {
      widget.controller.stopListening();
    } else {
      final available = await widget.controller.isListeningAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الاستماع غير متاح. يرجى التحقق من أذونات الميكروفون.'),
            ),
          );
        }
        return;
      }
      await widget.controller.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: _isListening
              ? LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                )
              : AppTheme.tealGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isListening ? Colors.red : AppTheme.teal500)
                  .withOpacity(0.3),
              blurRadius: _isListening ? 20 : 10,
              spreadRadius: _isListening ? 5 : 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isListening)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 72 + (_animationController.value * 18),
                    height: 72 + (_animationController.value * 18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(
                          1 - _animationController.value,
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            // Inner avatar-style circle to match app design
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isListening ? Icons.graphic_eq_rounded : Icons.chat_bubble_rounded,
                  color: _isListening ? Colors.red.shade500 : AppTheme.teal600,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }
}

