import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../content_engine/application/subject_journey.dart';
import '../../quiz/application/pack_quiz_providers.dart';
import '../deterministic/companion_dialogue_bank.dart';
import '../deterministic/companion_study_context.dart';
import '../deterministic/deterministic_companion_engine.dart';

/// Langues de la banque de dialogues ; toute autre langue lit le français.
const companionDialogueLanguages = {'fr', 'en'};

/// Banque de dialogues de la langue de l'application, lue une fois depuis
/// les assets : aucun réseau.
final companionDialogueBankProvider =
    FutureProvider.family<CompanionDialogueBank, String>((ref, language) async {
      final code = companionDialogueLanguages.contains(language)
          ? language
          : 'fr';
      final raw = await rootBundle.loadString(
        'assets/companions/dialogue/$code.json',
      );
      return CompanionDialogueBank.parse(raw);
    });

final deterministicCompanionEngineProvider =
    Provider<DeterministicCompanionEngine>(
      (ref) => const DeterministicCompanionEngine(),
    );

/// Ce que le compagnon sait de l'élève : ses packs, sa maîtrise, ses quiz
/// et son historique local — rien d'autre, et rien d'inventé. Tant qu'une
/// source n'est pas prête, elle compte pour vide.
final companionStudyContextProvider = Provider<CompanionStudyContext>((ref) {
  final auth = ref.watch(
    authControllerProvider.select(
      (state) => (userId: state.userId, firstName: state.firstName),
    ),
  );
  final journeys =
      ref.watch(subjectJourneysProvider).valueOrNull ??
      const <SubjectJourney>[];
  return CompanionStudyContext.build(
    studentKey: auth.userId ?? 'anonymous',
    firstName: auth.firstName,
    journeys: journeys,
    catalog: ref.watch(packQuizCatalogProvider).valueOrNull,
    history: ref.watch(packQuizHistoryProvider).valueOrNull ?? const [],
  );
});
