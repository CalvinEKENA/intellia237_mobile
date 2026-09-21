import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/features/companions/presentation/companions_screen.dart';

void main() {
  group('Studio Companions Screen Integrity & Authoritative Configuration', () {
    test(
      'Source hygiene: companions_screen.dart contains no fabricated production values',
      () {
        final file = File(
          'lib/features/companions/presentation/companions_screen.dart',
        );
        expect(file.existsSync(), isTrue);

        final content = file.readAsStringSync();

        // Must NOT contain outdated or weaker model
        expect(
          content.contains('gemini-1.5-flash'),
          isFalse,
          reason: 'Companions screen must not reference gemini-1.5-flash',
        );

        // Must NOT contain fake hardcoded telemetry
        expect(
          content.contains('14 280') || content.contains('14,280'),
          isFalse,
          reason: 'Companions screen must not fabricate daily question count',
        );
        expect(
          content.contains('820 ms'),
          isFalse,
          reason: 'Companions screen must not fabricate latency metrics',
        );
        expect(
          content.contains('98.4%'),
          isFalse,
          reason:
              'Companions screen must not fabricate satisfaction percentage',
        );

        // Must NOT contain fake temperature 0.2
        expect(
          content.contains('0.2 (Faible hallucination)') ||
              content.contains('0.2'),
          isFalse,
          reason: 'Companions screen must not fabricate temperature 0.2',
        );

        // Must NOT contain static model fallback string
        expect(
          content.contains("?? 'gemini-3.8-flash'"),
          isFalse,
          reason:
              'Companions screen must not fall back statically to gemini-3.8-flash',
        );
        expect(
          content.contains("?? 'gemini-1.5-flash'"),
          isFalse,
          reason:
              'Companions screen must not fall back statically to gemini-1.5-flash',
        );

        // Must display model default temperature indicator
        expect(
          content.contains('valeur par défaut du modèle'),
          isTrue,
          reason:
              'Companions screen must state that temperature is model default',
        );

        // Must label screen section as companion specification, not duplicate production prompt
        expect(content.contains('Spécification du compagnon'), isTrue);
        expect(content.contains('Prompt Système — Production'), isFalse);

        // No local copy of the companion rules: the screen shows what the
        // server really sends, so it can never promise a rule that is not
        // applied (the old static text advertised a Socratic method).
        expect(content.contains('socratique'), isFalse);
        expect(content.contains('_kiraSpecification'), isFalse);
        expect(content.contains('formatCompanionSpecification'), isTrue);
      },
    );

    testWidgets('Renders authoritative runtime configuration from backend', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companionRuntimeConfigProvider.overrideWith(
              (ref) async => {
                'provider': 'vertex-ai',
                'model': 'gemini-3.8-flash',
                'tutorThinkingLevel': 'HIGH',
                'structuredThinkingLevel': 'MEDIUM',
                'location': 'global',
                'configured': true,
                'companions': [
                  {
                    'id': 'kira',
                    'displayName': 'Kira',
                    'role': {
                      'fr': 'Compagne d’étude.',
                      'en': 'Study companion.',
                    },
                    'temperament': {'fr': 'Patiente.', 'en': 'Patient.'},
                    'motto': {'fr': 'Apprenons.', 'en': 'Let us learn.'},
                    'style': {
                      'fr': ['Découpe les difficultés.'],
                      'en': [],
                    },
                    'pedagogy': {
                      'fr': ['Guide avant de donner la solution.'],
                      'en': [],
                    },
                    'safety': {
                      'fr': ['Adulte de confiance.'],
                      'en': [],
                    },
                    'format': {
                      'fr': ['Tutoie l’élève.'],
                      'en': [],
                    },
                  },
                  {
                    'id': 'leo',
                    'displayName': 'Léo',
                    'role': {
                      'fr': 'Compagnon d’entraînement.',
                      'en': 'Practice companion.',
                    },
                    'temperament': {'fr': 'Dynamique.', 'en': 'Energetic.'},
                    'motto': {
                      'fr': 'Dépasse tes limites.',
                      'en': 'Push your limits.',
                    },
                    'style': {
                      'fr': ['Propose des défis.'],
                      'en': [],
                    },
                    'pedagogy': {
                      'fr': ['Guide avant de donner la solution.'],
                      'en': [],
                    },
                    'safety': {
                      'fr': ['Adulte de confiance.'],
                      'en': [],
                    },
                    'format': {
                      'fr': ['Tutoie l’élève.'],
                      'en': [],
                    },
                  },
                ],
              },
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CompanionsScreen())),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and tabs
      expect(
        find.text('Opérations Compagnons IA (Kira & Léo)'),
        findsOneWidget,
      );
      expect(find.text('Spécification du compagnon — Kira'), findsOneWidget);
      expect(find.text('SPÉCIFICATION SERVEUR'), findsOneWidget);
      expect(
        find.textContaining('Guide avant de donner la solution.'),
        findsOneWidget,
      );
      expect(find.textContaining('Adulte de confiance.'), findsOneWidget);

      // Check authoritative runtime configuration card
      expect(find.text('Configuration Runtime IA'), findsOneWidget);
      expect(find.text('OPÉRATIONNEL'), findsOneWidget);
      expect(find.text('gemini-3.8-flash'), findsOneWidget);
      expect(find.text('vertex-ai'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('global'), findsOneWidget);
      expect(find.text('valeur par défaut du modèle'), findsOneWidget);

      // Check that telemetry displays truthful unaggregated state
      expect(
        find.text('Questions traitées aujourd\'hui : Donnée non disponible'),
        findsOneWidget,
      );
      expect(
        find.text('Temps moyen de réponse : Donnée non disponible'),
        findsOneWidget,
      );
      expect(
        find.text('Taux de satisfaction tuteur : Donnée non disponible'),
        findsOneWidget,
      );

      // Toggle to Léo
      await tester.tap(find.text('Léo (Défis & Performance)'));
      await tester.pumpAndSettle();

      expect(find.text('Spécification du compagnon — Léo'), findsOneWidget);
      expect(
        find.textContaining('SPÉCIFICATION DU COMPAGNON — LÉO'),
        findsOneWidget,
      );
    });

    testWidgets(
      'When runtime config is unavailable, shows Configuration serveur indisponible without static model fallback',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              companionRuntimeConfigProvider.overrideWith(
                (ref) async => throw Exception('Service Unavailable'),
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: CompanionsScreen())),
          ),
        );

        await tester.pumpAndSettle();

        // Check that "Configuration serveur indisponible" is shown
        expect(find.text('Configuration serveur indisponible'), findsOneWidget);
        expect(find.text('INDISPONIBLE'), findsOneWidget);

        // Verify that NO model is claimed statically
        expect(find.text('gemini-3.8-flash'), findsNothing);
        // Nor any companion rule: the specification is unavailable too.
        expect(
          find.textContaining('Spécification serveur indisponible'),
          findsOneWidget,
        );
        expect(find.text('gemini-1.5-flash'), findsNothing);
      },
    );
  });
}
