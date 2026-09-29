import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_dialogue_bank.dart';
import 'package:intellia237/features/ai_companion/deterministic/companion_study_context.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_session.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';

import '../content_engine/pack_fixture.dart';

const terminaleD = ClassKey('terminale', series: 'd');

/// Banque de dialogues telle que livrée.
CompanionDialogueBank loadBank(String language) => CompanionDialogueBank.parse(
  File('assets/companions/dialogue/$language.json').readAsStringSync(),
);

/// Parcours Terminale D réels (packs embarqués), avec une maîtrise vierge,
/// ou nourrie par [answer] avant lecture.
Future<ProviderContainer> terminaleDContainer(
  WidgetTester tester, {
  ClassKey? classKey = terminaleD,
  Future<void> Function(ProviderContainer container)? answer,
}) async {
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith((ref) async => classKey),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SizedBox()),
  );
  await settleSubjectJourneys(tester, container);
  if (answer != null) {
    await tester.runAsync(() => answer(container));
    await tester.pump();
    await settleSubjectJourneys(tester, container);
  }
  return container;
}

CompanionStudyContext contextFrom(
  ProviderContainer container, {
  String? firstName = 'Amina',
  List<PackQuizHistoryEntry> history = const [],
}) {
  final journeys = container.read(subjectJourneysProvider).requireValue;
  return CompanionStudyContext.build(
    studentKey: 'eleve-test',
    firstName: firstName,
    journeys: journeys,
    catalog: PackQuizCatalog.fromJourneys(journeys),
    history: history,
  );
}

List<SubjectJourney> journeysOf(ProviderContainer container) =>
    container.read(subjectJourneysProvider).requireValue;
