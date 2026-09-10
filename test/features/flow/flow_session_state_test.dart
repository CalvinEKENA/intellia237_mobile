import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_subject.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FLOW affichait « Connecte-toi pour faire valider tes points FLOW. » à des
/// élèves authentifiés : toute erreur d'autorisation serveur était traduite
/// par une invitation à se connecter, y compris quand la session locale était
/// parfaitement valide et que seul l'envoi avait échoué.
void main() {
  const quiz = FlowMiniQuizCard(
    id: 'q1',
    subject: FlowSubjects.svt,
    question: 'q',
    options: ['bon', 'mauvais'],
    correctIndex: 0,
    explanation: 'e',
  );

  group('catégorisation des refus serveur', () {
    test('un refus de jeton n’est pas une déconnexion', () {
      // Le client n'appelle la callable qu'avec un identifiant local présent.
      // Un « unauthenticated » serveur signale donc un jeton non accepté.
      final failure = FlowPointsException.fromFunctions(
        FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'no token',
        ),
      );

      expect(failure.issue, FlowSyncIssue.syncUnavailable);
      expect(failure.issue, isNot(FlowSyncIssue.signedOut));
    });

    test('chaque code serveur garde sa catégorie propre', () {
      FlowSyncIssue issueFor(String code) => FlowPointsException.fromFunctions(
        FirebaseFunctionsException(code: code, message: code),
      ).issue;

      expect(issueFor('permission-denied'), FlowSyncIssue.notEligible);
      expect(issueFor('not-found'), FlowSyncIssue.contentNotValidated);
      expect(issueFor('already-exists'), FlowSyncIssue.duplicateEvent);
      expect(issueFor('invalid-argument'), FlowSyncIssue.invalidAnswer);
      expect(issueFor('unavailable'), FlowSyncIssue.network);
      expect(issueFor('deadline-exceeded'), FlowSyncIssue.network);
      expect(issueFor('internal'), FlowSyncIssue.unknown);
    });

    test('seule l’absence de session produit signedOut', () {
      const failure = FlowPointsException(FlowSyncIssue.signedOut);
      expect(failure.issue, FlowSyncIssue.signedOut);
    });
  });

  group('remontée au contrôleur', () {
    late ProviderContainer container;
    late FlowController controller;
    late _ThrowingGateway gateway;

    Future<void> settle() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      await SharedPreferences.getInstance();
      gateway = _ThrowingGateway();
      container = ProviderContainer(
        overrides: [
          flowPointsGatewayProvider.overrideWithValue(gateway),
          flowCardsProvider.overrideWithValue(const [quiz]),
        ],
      );
      controller = container.read(flowControllerProvider.notifier);
      await settle();
    });

    tearDown(() => container.dispose());

    test(
      'un élève authentifié dont la synchro échoue n’est pas déconnecté',
      () async {
        gateway.error = FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'no token',
        );

        final award = await controller.answerMiniQuiz(quiz, 0);

        expect(award.issue, FlowSyncIssue.syncUnavailable);
        expect(
          award.issue,
          isNot(FlowSyncIssue.signedOut),
          reason:
              'une panne de synchronisation ne doit jamais se présenter '
              'comme une déconnexion',
        );
        // La réponse de l'élève reste reconnue localement.
        expect(award.correct, isTrue);
      },
    );

    test('une session réellement absente invite bien à se connecter', () async {
      gateway.error = const FlowPointsException(FlowSyncIssue.signedOut);

      final award = await controller.answerMiniQuiz(quiz, 0);

      expect(award.issue, FlowSyncIssue.signedOut);
    });

    test(
      'un service indisponible reste une file d’attente, pas un rejet',
      () async {
        gateway.error = FirebaseFunctionsException(
          code: 'unavailable',
          message: 'down',
        );

        final award = await controller.answerMiniQuiz(quiz, 0);

        expect(award.issue, FlowSyncIssue.network);
      },
    );

    test('un profil non élève est nommé pour ce qu’il est', () async {
      gateway.error = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'denied',
      );

      final award = await controller.answerMiniQuiz(quiz, 0);

      expect(award.issue, FlowSyncIssue.notEligible);
    });

    test('une erreur inconnue ne se déguise pas en déconnexion', () async {
      gateway.error = StateError('boom');

      final award = await controller.answerMiniQuiz(quiz, 0);

      expect(award.issue, FlowSyncIssue.unknown);
    });
  });
}

class _ThrowingGateway implements FlowPointsGateway {
  Object? error;
  var _event = 0;

  @override
  String newClientEventId() => 'event_${++_event}_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    if (error != null) throw error!;
    return FlowPointsResult.pending(command);
  }

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
