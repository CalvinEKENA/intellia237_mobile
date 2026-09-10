import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_experience_scaffold.dart';
import 'package:intellia237/features/student_registration/presentation/widgets/companion_discovery.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import '../../support/contrast.dart';

/// « Rencontre ton compagnon » a été livré avec des textes blancs hérités
/// d'une ancienne maquette sombre, alors que la palette d'authentification est
/// désormais crème. Sur un vrai téléphone le nom, les phrases, la flèche et le
/// bouton de choix étaient donc blancs sur blanc.
///
/// Ces tests mesurent le contraste réel plutôt que la simple présence des
/// widgets : un texte invisible reste « trouvable » par `find.text`.
void main() {
  Future<void> pumpDiscovery(
    WidgetTester tester, {
    required bool reduceMotion,
    double textScale = 1.0,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion,
            ),
            child: const Scaffold(
              backgroundColor: AuthExperienceColors.canvas,
              body: SingleChildScrollView(child: CompanionDiscovery()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Les deux fonds réellement utilisés par l'écran : la toile crème et les
  /// pastilles blanches posées dessus. Un texte doit rester lisible sur les
  /// deux, car il n'existe aucune surface sombre dans cette expérience.
  const backgrounds = <String, Color>{
    'canvas': AuthExperienceColors.canvas,
    'surface': AuthExperienceColors.surface,
    'surfaceSoft': AuthExperienceColors.surfaceSoft,
  };

  testWidgets('aucun texte de découverte n’est blanc sur blanc', (
    tester,
  ) async {
    await pumpDiscovery(tester, reduceMotion: true);

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts, isNotEmpty, reason: 'la scène doit afficher du texte');

    for (final text in texts) {
      final color = text.style?.color;
      expect(
        color,
        isNotNull,
        reason:
            'chaque texte de cet écran doit porter une couleur explicite : '
            '« ${text.data} » hérite du thème et peut redevenir blanc',
      );
      for (final entry in backgrounds.entries) {
        final ratio = Contrast.ratio(color!, entry.value);
        expect(
          ratio,
          greaterThanOrEqualTo(Contrast.aaLargeText),
          reason:
              '« ${text.data} » n’a qu’un contraste de '
              '${ratio.toStringAsFixed(2)}:1 sur ${entry.key}',
        );
      }
    }
  });

  testWidgets('le nom et les phrases du compagnon atteignent le niveau AA', (
    tester,
  ) async {
    await pumpDiscovery(tester, reduceMotion: true);

    // Le nom est un grand titre (26px, w900) : le seuil « grand texte »
    // suffirait, mais la palette retenue dépasse largement le seuil courant.
    final name = tester.widget<Text>(find.text('Kira'));
    expect(
      Contrast.ratio(name.style!.color!, AuthExperienceColors.canvas),
      greaterThanOrEqualTo(Contrast.aaNormalText),
    );

    // Les phrases cinématiques sont du texte courant : seuil AA strict.
    final phrases = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => (text.style?.fontSize ?? 0) == 15)
        .toList();
    expect(phrases, isNotEmpty, reason: 'les phrases doivent être rendues');
    for (final phrase in phrases) {
      expect(
        Contrast.ratio(phrase.style!.color!, AuthExperienceColors.canvas),
        greaterThanOrEqualTo(Contrast.aaNormalText),
        reason: '« ${phrase.data} » doit rester lisible',
      );
    }
  });

  testWidgets('l’état « pas encore découvert » du choix reste lisible', (
    tester,
  ) async {
    // Sans reduced-motion et avant la fin de la révélation, la barre affiche
    // son état désactivé : c'est celui qui était le plus effacé.
    await pumpDiscovery(tester, reduceMotion: false);

    final disabled = tester.widget<Text>(
      find.textContaining('pour pouvoir le choisir', findRichText: false),
    );
    expect(
      Contrast.ratio(disabled.style!.color!, AuthExperienceColors.surfaceSoft),
      greaterThanOrEqualTo(Contrast.aaNormalText),
    );

    // La flèche « Découvrir » rejoue son mouvement en boucle tant que les
    // animations sont actives : on démonte l'arbre pour libérer ses timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('le compagnon choisi garde un libellé blanc sur accent foncé', (
    tester,
  ) async {
    await pumpDiscovery(tester, reduceMotion: true);

    // Le seul texte blanc légitime de l'écran est celui posé sur le dégradé
    // d'accent une fois le compagnon choisi.
    for (final accent in const [
      AuthExperienceColors.purple,
      AuthExperienceColors.blue,
    ]) {
      expect(
        Contrast.ratio(Colors.white, accent),
        greaterThanOrEqualTo(Contrast.aaNormalText),
        reason: 'le CTA choisi doit rester lisible sur $accent',
      );
      expect(
        Contrast.ratio(Colors.white, Color.lerp(accent, Colors.black, 0.18)!),
        greaterThanOrEqualTo(Contrast.aaNormalText),
        reason: 'la fin du dégradé doit rester lisible',
      );
    }
  });

  testWidgets('la découverte reste lisible et sans débordement à textScale 2', (
    tester,
  ) async {
    await pumpDiscovery(tester, reduceMotion: true, textScale: 2.0);

    expect(tester.takeException(), isNull);
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final color = text.style?.color;
      if (color == null) continue;
      expect(
        Contrast.ratio(color, AuthExperienceColors.canvas),
        greaterThanOrEqualTo(Contrast.aaLargeText),
      );
    }
  });
}
