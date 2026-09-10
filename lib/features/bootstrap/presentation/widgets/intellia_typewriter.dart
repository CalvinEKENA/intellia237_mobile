import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

/// Surfaces et encres du premier écran. Le papier est celui de l'onboarding :
/// l'application s'ouvre déjà sur le fond qu'elle va garder.
abstract final class SplashPalette {
  static const paper = Color(0xFFF4EFE5);
  static const ink = Color(0xFF25233E);

  // Le drapeau vient des jetons de marque : le 237 du splash et celui du
  // bandeau de l'onboarding ne peuvent pas diverger.
  static const green = IntelliaFlag.green;
  static const red = IntelliaFlag.red;
  static const yellow = IntelliaFlag.yellow;
}

/// Le rythme de la frappe, exprimé en durées et non en fractions : c'est
/// ainsi qu'on le lit, et c'est ainsi qu'on le règle.
abstract final class SplashMotion {
  static const name = 'INTELLIA';
  static const number = '237';

  static const letter = Duration(milliseconds: 70);

  /// Le temps de reprendre son souffle entre le nom et le pays.
  static const breath = Duration(milliseconds: 240);
  static const digit = Duration(milliseconds: 95);
  static const hold = Duration(milliseconds: 380);
  static const exit = Duration(milliseconds: 460);
  static const caretBlink = Duration(milliseconds: 160);

  static Duration get numberStart => letter * name.length + breath;
  static Duration get typed => numberStart + digit * number.length;
  static Duration get total => typed + hold + exit;

  static int lettersAt(Duration elapsed) {
    if (elapsed <= Duration.zero) return 1;
    final count = elapsed.inMilliseconds ~/ letter.inMilliseconds + 1;
    return count.clamp(1, name.length);
  }

  static int digitsAt(Duration elapsed) {
    final start = numberStart;
    if (elapsed < start) return 0;
    final since = elapsed - start;
    final count = since.inMilliseconds ~/ digit.inMilliseconds + 1;
    return count.clamp(0, number.length);
  }

  /// Le curseur est plein tant qu'on frappe, et ne clignote que pendant la
  /// pause : c'est là qu'il faut le voir attendre, entre le nom et le pays.
  static bool caretAt(Duration elapsed) {
    if (elapsed >= typed) return false;
    final pause = letter * name.length;
    if (elapsed < pause || elapsed >= numberStart) return true;
    final half = caretBlink.inMilliseconds ~/ 2;
    return ((elapsed - pause).inMilliseconds ~/ half).isEven;
  }

  static double exitAt(Duration elapsed) {
    final start = typed + hold;
    if (elapsed <= start) return 0;
    final since = (elapsed - start).inMilliseconds / exit.inMilliseconds;
    return since.clamp(0.0, 1.0);
  }
}

/// « INTELLIA237 » frappé lettre après lettre, dans la condensée qui porte
/// les titres de l'onboarding.
///
/// Le rendu est une fonction pure de [elapsed] : aucune horloge interne, donc
/// n'importe quelle image de la séquence peut être reproduite et vérifiée.
class IntelliaTypewriter extends StatelessWidget {
  const IntelliaTypewriter({
    required this.elapsed,
    this.reduceMotion = false,
    super.key,
  });

  final Duration elapsed;
  final bool reduceMotion;

  static const _digitColors = [
    SplashPalette.green,
    SplashPalette.red,
    SplashPalette.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    final letters = reduceMotion
        ? SplashMotion.name.length
        : SplashMotion.lettersAt(elapsed);
    final digits = reduceMotion
        ? SplashMotion.number.length
        : SplashMotion.digitsAt(elapsed);
    final leaving = reduceMotion ? 0.0 : SplashMotion.exitAt(elapsed);

    return LayoutBuilder(
      builder: (context, constraints) {
        // La taille se fixe sur le mot entier, jamais sur ce qui est déjà
        // écrit : sinon les lettres rétréciraient à mesure qu'on tape.
        final width = constraints.maxWidth;
        final size = (width * 0.82 / 4.0).clamp(40.0, 112.0);
        final travelled = Curves.easeInOutCubic.transform(leaving);

        return Semantics(
          label: '${SplashMotion.name}${SplashMotion.number}',
          excludeSemantics: true,
          child: Opacity(
            opacity:
                1 -
                Curves.easeIn.transform(
                  ((leaving - 0.55) / 0.45).clamp(0.0, 1.0),
                ),
            child: Transform.translate(
              offset: Offset(
                -width * 0.17 * travelled,
                -constraints.maxHeight * 0.30 * travelled,
              ),
              child: Transform.scale(
                scale: 1 - 0.64 * travelled,
                // Un gabarit invisible du mot entier fixe la largeur : sans
                // lui, chaque lettre frappée recentrerait les précédentes. Le
                // FittedBox n'est qu'un garde-fou si la police manque.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Opacity(
                        opacity: 0,
                        child: _line(
                          size,
                          SplashMotion.name.length,
                          SplashMotion.number.length,
                          null,
                        ),
                      ),
                      _line(
                        size,
                        letters,
                        digits,
                        const ValueKey('splash-wordmark'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _line(double size, int letters, int digits, Key? key) {
    final style = TextStyle(
      fontFamily: 'BarlowCondensed',
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 0.94,
      letterSpacing: -0.6,
      color: SplashPalette.ink,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text.rich(
          key: key,
          TextSpan(
            children: [
              TextSpan(text: SplashMotion.name.substring(0, letters)),
              for (var index = 0; index < digits; index++)
                TextSpan(
                  text: SplashMotion.number[index],
                  style: TextStyle(color: _digitColors[index]),
                ),
            ],
          ),
          style: style,
          textAlign: TextAlign.center,
        ),
        _caret(size),
      ],
    );
  }

  Widget _caret(double size) {
    final visible = !reduceMotion && SplashMotion.caretAt(elapsed);
    return Padding(
      padding: EdgeInsets.only(left: size * 0.06, bottom: size * 0.10),
      child: SizedBox(
        width: math.max(2, size * 0.055),
        height: size * 0.66,
        child: ColoredBox(
          color: visible ? SplashPalette.ink : Colors.transparent,
        ),
      ),
    );
  }
}
