import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/application/dictation_controller.dart';
import 'package:intellia237/features/ai_companion/application/listen_controller.dart';
import 'package:intellia237/features/ai_companion/data/speech_services.dart';
import 'package:intellia237/features/ai_companion/domain/dictation_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// « Parler » est une autre manière d'écrire, pas une conversation vocale :
/// l'élève dicte, relit, corrige, puis envoie du texte. « Écouter » est
/// disponible pour tous les paliers.
///
/// Ces tests utilisent des moteurs simulés : la dictée doit être vérifiable
/// sans micro, et rien ici ne touche au réseau.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _FakeRecognizer recognizer;
  late _FakeSpeaker speaker;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await SharedPreferences.getInstance();
    recognizer = _FakeRecognizer();
    speaker = _FakeSpeaker();
    container = ProviderContainer(
      overrides: [
        speechRecognizerProvider.overrideWithValue(recognizer),
        speechSpeakerProvider.overrideWithValue(speaker),
      ],
    );
  });

  tearDown(() => container.dispose());

  DictationController dictationOf() =>
      container.read(dictationControllerProvider.notifier);
  DictationState stateOf() => container.read(dictationControllerProvider);

  group('dictée', () {
    test('le micro ne démarre jamais sans geste explicite', () {
      expect(stateOf().status, DictationStatus.idle);
      expect(recognizer.listenCalls, 0);
    });

    test('un refus du micro laisse « Parler » utilisable', () async {
      recognizer
        ..available = true
        ..initializeResult = false;

      final started = await dictationOf().start();

      expect(started, isFalse);
      expect(stateOf().status, DictationStatus.permissionDenied);
      expect(recognizer.listenCalls, 0);
    });

    test('un appareil sans moteur le dit honnêtement', () async {
      recognizer
        ..available = false
        ..initializeResult = false;

      await dictationOf().start();

      expect(stateOf().status, DictationStatus.unavailable);
    });

    test('la transcription arrive au fil de la parole', () async {
      await dictationOf().start();
      expect(stateOf().status, DictationStatus.listening);

      recognizer.emit('douze', isFinal: false);
      expect(stateOf().transcript, 'douze');
      expect(stateOf().isListening, isTrue);
    });

    test('le niveau sonore est normalisé pour le fil d’encre', () async {
      await dictationOf().start();

      recognizer.emitLevel(10);
      expect(stateOf().soundLevel, greaterThan(0.9));

      recognizer.emitLevel(-2);
      expect(stateOf().soundLevel, 0);
    });

    test('arrêter conserve la transcription pour correction', () async {
      await dictationOf().start();
      recognizer.emit('douze plus trois', isFinal: false);

      await dictationOf().stop();

      expect(stateOf().status, DictationStatus.ready);
      expect(stateOf().transcript, 'douze plus trois');
      expect(stateOf().canSend, isTrue);
      expect(recognizer.stopCalls, 1);
    });

    test(
      'la transcription reste modifiable : « douze » n’est pas « deux »',
      () async {
        await dictationOf().start();
        recognizer.emit('deux plus trois', isFinal: false);
        await dictationOf().stop();

        dictationOf().edit('douze plus trois');

        expect(stateOf().transcript, 'douze plus trois');
        expect(stateOf().canSend, isTrue);
      },
    );

    test('annuler ne laisse aucune trace', () async {
      await dictationOf().start();
      recognizer.emit('quelque chose', isFinal: false);

      await dictationOf().cancel();

      expect(recognizer.cancelCalls, 1);
      expect(stateOf().status, DictationStatus.idle);
      expect(stateOf().transcript, isEmpty);
    });

    test('une dictée vide n’est jamais envoyable', () async {
      await dictationOf().start();
      await dictationOf().stop();

      expect(stateOf().status, DictationStatus.failed);
      expect(stateOf().canSend, isFalse);

      dictationOf().edit('   ');
      expect(stateOf().canSend, isFalse);
    });

    test('la limite de dictée et son avertissement sont contractuels', () {
      expect(DictationState.maxDuration, const Duration(seconds: 90));
      expect(DictationState.warningThreshold, const Duration(seconds: 75));

      const near = DictationState(elapsed: Duration(seconds: 76));
      expect(near.isNearingLimit, isTrue);
      const early = DictationState(elapsed: Duration(seconds: 10));
      expect(early.isNearingLimit, isFalse);
      expect(early.remaining, const Duration(seconds: 80));
    });

    test('aucun audio n’est conservé : seul le texte survit', () async {
      await dictationOf().start();
      recognizer.emit('ma question', isFinal: true);
      await Future<void>.delayed(Duration.zero);

      // Le moteur travaille sur l'appareil et rien n'est téléversé : le
      // contrôleur n'expose aucun chemin de fichier ni tampon audio.
      expect(stateOf().transcript, 'ma question');
      expect(recognizer.uploadedAudio, isEmpty);
    });
  });

  group('écouter', () {
    test('la lecture ne démarre jamais d’elle-même', () {
      expect(
        container.read(listenControllerProvider).status,
        ListenStatus.idle,
      );
      expect(speaker.spoken, isEmpty);
    });

    test('écouter puis pause suit le même bouton', () async {
      final listen = container.read(listenControllerProvider.notifier);

      await listen.toggle('m1', 'Bonjour');
      expect(container.read(listenControllerProvider).isSpeaking('m1'), isTrue);

      await listen.toggle('m1', 'Bonjour');
      expect(container.read(listenControllerProvider).isPaused('m1'), isTrue);
      expect(speaker.pauseCalls, 1);
    });

    test('un nouvel envoi interrompt la lecture sans reprise', () async {
      final listen = container.read(listenControllerProvider.notifier);
      await listen.speak('m1', 'Une réponse');

      await listen.stop();

      expect(speaker.stopCalls, greaterThan(0));
      expect(
        container.read(listenControllerProvider).status,
        ListenStatus.idle,
      );
    });

    test('le balisage n’est jamais prononcé', () {
      final spoken = ListenController.spokenForm(
        '### Titre\n- **Point** un\n`code`',
      );

      expect(spoken, isNot(contains('#')));
      expect(spoken, isNot(contains('*')));
      expect(spoken, isNot(contains('`')));
      expect(spoken, contains('Titre'));
    });

    test('les mathématiques ont une forme parlée sensée', () {
      final spoken = ListenController.spokenForm('x² ≤ 4 et Δ = b² − 4ac');

      expect(spoken, contains('au carré'));
      expect(spoken, contains('inférieur ou égal'));
      expect(spoken, contains('delta'));
      expect(spoken, contains('moins'));
      expect(spoken, isNot(contains('²')));
    });

    test('une réponse vide n’est pas lue', () async {
      final listen = container.read(listenControllerProvider.notifier);

      await listen.speak('m1', '   ');

      expect(speaker.spoken, isEmpty);
    });
  });
}

class _FakeRecognizer implements SpeechRecognizer {
  var available = true;
  var initializeResult = true;
  var listenCalls = 0;
  var stopCalls = 0;
  var cancelCalls = 0;

  /// Reste vide : la dictée ne téléverse aucun audio.
  final uploadedAudio = <String>[];

  void Function(String, bool)? _onResult;
  void Function(double)? _onLevel;

  void emit(String transcript, {required bool isFinal}) =>
      _onResult?.call(transcript, isFinal);

  void emitLevel(double level) => _onLevel?.call(level);

  @override
  bool get isAvailable => available;

  @override
  Future<bool> initialize() async => initializeResult;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(double level) onSoundLevel,
  }) async {
    listenCalls++;
    _onResult = onResult;
    _onLevel = onSoundLevel;
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> cancel() async => cancelCalls++;
}

class _FakeSpeaker implements SpeechSpeaker {
  final spoken = <String>[];
  var pauseCalls = 0;
  var stopCalls = 0;

  @override
  set onComplete(void Function()? handler) {}

  @override
  Future<void> speak(
    String text, {
    required String languageCode,
    double rate = 0.5,
  }) async {
    spoken.add(text);
  }

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> stop() async => stopCalls++;
}
