import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../app/theme/design_tokens.dart';

class OnboardingSlide3Visual extends StatefulWidget {
  const OnboardingSlide3Visual({super.key});

  @override
  State<OnboardingSlide3Visual> createState() => _OnboardingSlide3VisualState();
}

class _OnboardingSlide3VisualState extends State<OnboardingSlide3Visual>
    with TickerProviderStateMixin {
  int _phraseIndex = 0;
  int _typedLength = 0;
  bool _isResetting = false;
  Timer? _cycleTimer;
  Timer? _blinkTimer;
  bool _cursorVisible = true;

  static const List<String> _phrases = [
    'Hello! How are you?',
    'I can explain this.',
    'Let\'s practice together.',
  ];

  static const Duration _typingSpeed = Duration(milliseconds: 55);
  static const Duration _pauseAfterFull = Duration(milliseconds: 1400);
  static const Duration _pauseBeforeNext = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _startBlinking();
    _runTypingCycle();
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _startBlinking() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });
  }

  void _runTypingCycle() {
    if (!mounted) return;

    final currentPhrase = _phrases[_phraseIndex];

    if (_isResetting) {
      _cycleTimer = Timer(_pauseBeforeNext, () {
        if (mounted) {
          setState(() {
            _phraseIndex = (_phraseIndex + 1) % _phrases.length;
            _typedLength = 0;
            _isResetting = false;
          });
          _runTypingCycle();
        }
      });
      return;
    }

    if (_typedLength < currentPhrase.length) {
      _cycleTimer = Timer(_typingSpeed, () {
        if (mounted) {
          setState(() {
            _typedLength++;
          });
          _runTypingCycle();
        }
      });
      return;
    }

    // Phrase is fully typed, pause before resetting
    _cycleTimer = Timer(_pauseAfterFull, () {
      if (mounted) {
        setState(() {
          _isResetting = true;
        });
        _runTypingCycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentPhrase = _phrases[_phraseIndex];
    final visibleText = currentPhrase.substring(0, _typedLength);

    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle warm glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB566).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.25, 0.75],
                ),
              ),
            ),
          ),

          // Chat bubbles container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bubble 1 (Received - Left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.75,
                    child: _ChatBubble(
                      text: 'Can you help me?',
                      isMe: false,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bubble 2 (Sent - Right)
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.82,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: IntelliaColors.brandBlue,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: IntelliaColors.brandBlue.withValues(alpha: 0.24),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: visibleText),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Opacity(
                                opacity: _cursorVisible ? 1.0 : 0.0,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 2.0),
                                  width: 2,
                                  height: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Language tag below
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🇬🇧',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'English',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? IntelliaColors.textTertiary : IntelliaColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.isDark,
  });

  final String text;
  final bool isMe;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isMe
        ? IntelliaColors.brandBlue
        : (isDark ? IntelliaColors.backgroundSecondaryDark : IntelliaColors.backgroundSecondary);

    final textColor = isMe
        ? Colors.white
        : (isDark ? IntelliaColors.textPrimaryDark : IntelliaColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }
}
