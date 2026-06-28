import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../app/theme/design_tokens.dart';
import 'onboarding_visual_view.dart';

/// Slide 3 — « Teste-toi sans stress ».
///
/// Une conversation façon iMessage : une question reçue, puis des réponses
/// qui s'écrivent lettre par lettre, en boucle. Reprend la scène « anglais ».
class ChatTypingVisual extends StatefulWidget {
  const ChatTypingVisual({super.key});

  @override
  State<ChatTypingVisual> createState() => _ChatTypingVisualState();
}

class _ChatTypingVisualState extends State<ChatTypingVisual>
    with SingleTickerProviderStateMixin {
  static const _phrases = <String>[
    'Hello! How are you?',
    'I can explain this.',
    "Let's practice together.",
  ];

  late final AnimationController _cursor;
  Timer? _typer;
  int _phrase = 0;
  int _chars = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _cursor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (prefersReducedMotion(context)) {
      _chars = _phrases[0].length; // phrase complète figée, sans curseur
      return;
    }
    _cursor.repeat();
    _tick();
  }

  void _tick() {
    final full = _phrases[_phrase];
    if (_chars < full.length) {
      _typer = Timer(const Duration(milliseconds: 55), () {
        if (!mounted) return;
        setState(() => _chars++);
        _tick();
      });
    } else {
      // Phrase complète : pause, puis on passe à la suivante.
      _typer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _phrase = (_phrase + 1) % _phrases.length;
          _chars = 0;
        });
        _tick();
      });
    }
  }

  @override
  void dispose() {
    _typer?.cancel();
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typed = _phrases[_phrase].substring(0, _chars);

    return Center(
      child: SizedBox(
        width: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Halo chaud derrière la conversation.
            Container(
              width: 280,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB566).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.center, child: _languageBadge()),
                const SizedBox(height: 18),
                // Bulle reçue (gauche).
                Align(
                  alignment: Alignment.centerLeft,
                  child:
                      _Bubble(
                            text: 'Can you help me?',
                            background: const Color(0xFFE5E5EA),
                            textColor: const Color(0xFF3C3C43),
                            radius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                              bottomLeft: Radius.circular(6),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.12, end: 0),
                ),
                const SizedBox(height: 10),
                // Bulle envoyée (droite) qui s'écrit.
                Align(
                  alignment: Alignment.centerRight,
                  child: _Bubble(
                    background: IntelliaColors.brandBlue,
                    textColor: Colors.white,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(6),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: typed.isEmpty ? ' ' : typed),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: FadeTransition(
                              opacity: _cursor.drive(_BlinkTween()),
                              child: Container(
                                width: 2,
                                height: 16,
                                margin: const EdgeInsets.only(left: 2),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: IntelliaColors.surfaceSolid.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
      border: Border.all(
        color: const Color(0xFFFF9500).withValues(alpha: 0.25),
      ),
      boxShadow: IntelliaShadows.card(Colors.black),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.translate_rounded, size: 14, color: Color(0xFFFF9500)),
        const SizedBox(width: 6),
        Text(
          'English',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: IntelliaColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

/// Tween de clignotement : opaque la moitié du cycle, transparent l'autre.
class _BlinkTween extends Animatable<double> {
  @override
  double transform(double t) => t < 0.5 ? 1.0 : 0.0;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.background,
    required this.textColor,
    required this.radius,
    this.text,
    this.child,
  });

  final Color background;
  final Color textColor;
  final BorderRadius radius;
  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child:
            child ??
            Text(
              text ?? '',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.3,
              ),
            ),
      ),
    );
  }
}
