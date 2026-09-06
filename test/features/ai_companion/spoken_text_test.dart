import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/domain/spoken_text.dart';
import 'package:intellia237/features/ai_companion/domain/voice_profile.dart';

/// Sur appareil, la lecture énonçait les emojis, prononçait l'anglais avec la
/// phonétique française et lisait « x² » caractère par caractère.
///
/// Le principe : **texte affiché ≠ texte parlé**.
void main() {
  String spoken(String source, {String base = 'fr'}) =>
      SpokenText.plain(source, baseLanguage: base);

  group('décorations', () {
    test('les pictogrammes ne sont pas prononcés', () {
      const source = '🚀 Bravo ! 🔥 Tu progresses 👊 vraiment bien 💥';
      final result = spoken(source);

      for (final emoji in ['🚀', '🔥', '👊', '💥', '✨', '🎯']) {
        expect(result, isNot(contains(emoji)));
      }
      expect(result, contains('Bravo'));
      expect(result, contains('Tu progresses'));
      expect(result, contains('vraiment bien'));
    });

    test('un emoji composé disparaît entièrement', () {
      // Séquence avec liaison et teinte de peau.
      final result = spoken('Regarde 👨🏽‍🏫 ce point.');
      expect(result, isNot(contains('👨')));
      expect(result, contains('Regarde'));
      expect(result, contains('ce point'));
    });

    test('le balisage résiduel n’est jamais lu', () {
      final result = spoken('### Titre\n- **Point** un\n`code`');
      expect(result, isNot(contains('#')));
      expect(result, isNot(contains('*')));
      expect(result, isNot(contains('`')));
      expect(result, contains('Titre'));
    });

    test('les puces décoratives ne sont pas énoncées', () {
      expect(spoken('• Premier point'), isNot(contains('•')));
    });
  });

  group('mathématiques', () {
    test('la forme parlée française est intelligible', () {
      final result = spoken('Δ = b² − 4ac et x² ≤ 9');

      expect(result, contains('delta'));
      expect(result, contains('égale'));
      expect(result, contains('au carré'));
      expect(result, contains('moins'));
      expect(result, contains('inférieur ou égal'));
      expect(result, isNot(contains('²')));
      expect(result, isNot(contains('Δ')));
    });

    test('la forme parlée anglaise utilise les mots anglais', () {
      final result = spoken('x² ≥ 4', base: 'en');

      expect(result, contains('squared'));
      expect(result, contains('greater than or equal to'));
      expect(result, isNot(contains('au carré')));
    });
  });

  group('langues', () {
    test('une réponse française reste en français', () {
      final segments = SpokenText.from(
        'Le discriminant décide du nombre de solutions.',
        baseLanguage: 'fr',
      );

      expect(segments, hasLength(1));
      expect(segments.single.languageCode, 'fr');
    });

    test('une phrase anglaise dans une explication française bascule', () {
      final segments = SpokenText.from(
        'Voici un exemple. I am going to school every day. '
        'Retiens cette tournure.',
        baseLanguage: 'fr',
      );

      final languages = segments.map((s) => s.languageCode).toList();
      expect(languages, contains('en'));
      expect(languages, contains('fr'));

      final english = segments.firstWhere((s) => s.languageCode == 'en');
      // C'est bien la phrase anglaise qui change de voix, pas le reste.
      expect(english.text, contains('I am going to school'));
    });

    test('les accents français empêchent toute bascule à tort', () {
      final segments = SpokenText.from(
        'Révise the present perfect à la maison.',
        baseLanguage: 'fr',
      );

      expect(segments.every((s) => s.languageCode == 'fr'), isTrue);
    });

    test('un mot isolé ne suffit pas à changer de langue', () {
      final segments = SpokenText.from(
        'Le mot « homework » se traduit par devoirs.',
        baseLanguage: 'fr',
      );

      expect(segments.every((s) => s.languageCode == 'fr'), isTrue);
    });

    test('les fragments voisins de même langue sont fusionnés', () {
      final segments = SpokenText.from(
        'Première phrase. Deuxième phrase. Troisième phrase.',
        baseLanguage: 'fr',
      );

      expect(segments, hasLength(1));
    });

    test('une réponse vide ne produit aucun fragment', () {
      expect(SpokenText.from('   ', baseLanguage: 'fr'), isEmpty);
      expect(SpokenText.from('🚀✨', baseLanguage: 'fr'), isEmpty);
    });
  });

  group('profils de voix', () {
    const voices = [
      DeviceVoice(name: 'fr-fr-x-vlf#female_1-local', locale: 'fr-FR'),
      DeviceVoice(name: 'fr-fr-x-vlm#male_2-local', locale: 'fr-FR'),
      DeviceVoice(name: 'en-us-x-tpf#female_1-local', locale: 'en-US'),
      DeviceVoice(name: 'en-us-x-iom#male_1-local', locale: 'en-US'),
    ];

    test('Kira et Léo ne partagent pas la même voix', () {
      final kira = VoiceSelection.select(
        voices: voices,
        languageCode: 'fr',
        profile: VoiceProfile.feminine,
      );
      final leo = VoiceSelection.select(
        voices: voices,
        languageCode: 'fr',
        profile: VoiceProfile.masculine,
      );

      expect(kira, isNotNull);
      expect(leo, isNotNull);
      expect(kira!.name, isNot(leo!.name));
      expect(kira.name, contains('female'));
      // « female » contient « male » : le masculin doit exclure le féminin.
      expect(leo.name, contains('male'));
      expect(leo.name, isNot(contains('female')));
    });

    test('la voix suit la langue demandée', () {
      final english = VoiceSelection.select(
        voices: voices,
        languageCode: 'en',
        profile: VoiceProfile.masculine,
      );

      expect(english!.locale, startsWith('en'));
    });

    test('aucune voix pour la langue : le moteur décide', () {
      final result = VoiceSelection.select(
        voices: voices,
        languageCode: 'es',
        profile: VoiceProfile.feminine,
      );

      expect(result, isNull);
    });

    test('sans marqueur de genre, une voix neutre est préférée', () {
      const unlabelled = [
        DeviceVoice(name: 'fr-fr-x-default', locale: 'fr-FR'),
      ];

      final result = VoiceSelection.select(
        voices: unlabelled,
        languageCode: 'fr',
        profile: VoiceProfile.masculine,
      );

      expect(result, isNotNull);
      expect(result!.name, 'fr-fr-x-default');
    });

    test('jamais la voix explicitement opposée', () {
      const feminineOnly = [
        DeviceVoice(name: 'fr-fr-x-vlf#female_1-local', locale: 'fr-FR'),
      ];

      // Le moteur ne propose aucune voix masculine : on l'assume plutôt que
      // de donner à Léo une voix féminine.
      final result = VoiceSelection.select(
        voices: feminineOnly,
        languageCode: 'fr',
        profile: VoiceProfile.masculine,
      );

      expect(result, isNull);
    });
  });
}
