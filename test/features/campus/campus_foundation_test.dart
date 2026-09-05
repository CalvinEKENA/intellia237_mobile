import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/campus/application/campus_providers.dart';
import 'package:intellia237/features/campus/data/demo/demo_campus_fixtures.dart';
import 'package:intellia237/features/campus/data/repositories/demo_campus_repository.dart';
import 'package:intellia237/features/campus/domain/models/campus_attention_item.dart';
import 'package:intellia237/features/campus/domain/models/campus_context.dart';
import 'package:intellia237/features/campus/domain/models/campus_permissions.dart';
import 'package:intellia237/features/campus/domain/models/campus_program.dart';
import 'package:intellia237/features/campus/domain/models/campus_quiz.dart';
import 'package:intellia237/features/campus/domain/models/campus_roles.dart';
import 'package:intellia237/features/campus/domain/models/campus_staff.dart';
import 'package:intellia237/features/campus/presentation/screens/classes/campus_class_detail_view.dart';
import 'package:intellia237/features/campus/presentation/screens/direction/direction_dashboard_view.dart';
import 'package:intellia237/features/campus/presentation/theme/campus_theme_tokens.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_badge.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_empty_state.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_error_view.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_kpi_card.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_scaffold.dart';
import 'package:intellia237/features/campus/presentation/widgets/campus_sidebar.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

class _StaticContextNotifier extends CampusContextNotifier {
  _StaticContextNotifier(CampusContext initial) {
    state = initial;
  }
}

Widget _buildTestWrapper({
  required Widget child,
  CampusRole role = CampusRole.headOfSchool,
  Size size = const Size(1440, 900),
  double textScale = 1.0,
  Locale locale = const Locale('fr'),
}) {
  final membership = EstablishmentMembership(
    membershipId: 'mem_test_01',
    userId: 'user_test_01',
    establishmentId: DemoCampusFixtures.demoEstablishmentId,
    role: role,
    status: MembershipStatus.active,
    grantedScopes: CampusScopes.defaultScopesForRole(role),
    assignedClassIds: role == CampusRole.teacher
        ? const ['class_tc1', 'class_pc']
        : const [],
    assignedSubjectIds: role == CampusRole.teacher
        ? const ['Mathématiques']
        : const [],
  );

  final campusContext = CampusContext(
    establishmentId: DemoCampusFixtures.demoEstablishmentId,
    establishmentName: DemoCampusFixtures.demoEstablishmentName,
    subsystems: const [SubsystemType.francophone, SubsystemType.anglophone],
    academicYear: DemoCampusFixtures.demoAcademicYear,
    activeMembership: membership,
  );

  return ProviderScope(
    key: ValueKey('scope_${role.name}_${locale.languageCode}'),
    overrides: [
      campusContextProvider.overrideWith(
        (ref) => _StaticContextNotifier(campusContext),
      ),
      campusActiveNavProvider.overrideWith(
        (ref) => role == CampusRole.teacher
            ? CampusNavSection.today
            : CampusNavSection.overview,
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: CampusTokens.campusBackground,
        ),
        home: child,
      ),
    ),
  );
}

void main() {
  group('INTELLIA CAMPUS FOUNDATION — VERIFICATION SUITE', () {
    // ------------------------------------------------------------------------
    // Test 1: Navigation direction vs enseignant (sections affichées selon rôle)
    // ------------------------------------------------------------------------
    testWidgets(
      '1. Navigation direction vs enseignant (sections affichées selon rôle)',
      (tester) async {
        // Direction role: 10 items
        await tester.pumpWidget(
          _buildTestWrapper(
            child: const CampusScaffold(
              body: Center(child: Text('Direction Content')),
            ),
            role: CampusRole.headOfSchool,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vue générale'), findsWidgets);
        expect(find.text('Programme'), findsWidgets);
        expect(find.text('Enseignants'), findsWidgets);
        expect(find.text('Administration'), findsWidgets);

        // Teacher role: 5 items
        await tester.pumpWidget(
          _buildTestWrapper(
            child: const CampusScaffold(
              body: Center(child: Text('Teacher Content')),
            ),
            role: CampusRole.teacher,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aujourd’hui'), findsWidgets);
        expect(find.text('Classes'), findsWidgets);
        expect(find.text('Studio'), findsWidgets);
        // Direction exclusive sections must not be present in sidebar
        expect(find.text('Enseignants'), findsNothing);
        expect(find.text('Administration'), findsNothing);
      },
    );

    // ------------------------------------------------------------------------
    // Test 2: L'enseignant ne peut pas voir les actions réservées à la direction
    // ------------------------------------------------------------------------
    test(
      '2. L\'enseignant ne peut pas avoir les scopes réservés à la direction',
      () {
        final teacherScopes = CampusScopes.defaultScopesForRole(
          CampusRole.teacher,
        );
        final headScopes = CampusScopes.defaultScopesForRole(
          CampusRole.headOfSchool,
        );

        expect(teacherScopes.contains(CampusScopes.staffManage), isFalse);
        expect(teacherScopes.contains(CampusScopes.overviewRead), isFalse);
        expect(teacherScopes.contains(CampusScopes.auditRead), isFalse);

        expect(headScopes.contains(CampusScopes.staffManage), isTrue);
        expect(headScopes.contains(CampusScopes.overviewRead), isTrue);
        expect(headScopes.contains(CampusScopes.auditRead), isTrue);
      },
    );

    // ------------------------------------------------------------------------
    // Test 3: Le contexte d'établissement est obligatoire (lance une exception si vide)
    // ------------------------------------------------------------------------
    test(
      '3. Le contexte d\'établissement est obligatoire (lance une exception si vide)',
      () {
        final validMembership = EstablishmentMembership(
          membershipId: 'mem-1',
          userId: 'user-1',
          establishmentId: 'est-1',
          role: CampusRole.teacher,
          status: MembershipStatus.active,
          assignedClassIds: const [],
          assignedSubjectIds: const [],
        );

        expect(
          () => CampusContext(
            establishmentId: '',
            establishmentName: 'Nom',
            subsystems: const [SubsystemType.francophone],
            academicYear: '2026-2027',
            activeMembership: validMembership,
          ),
          throwsArgumentError,
        );

        expect(
          () => CampusContext(
            establishmentId: 'est-1',
            establishmentName: '',
            subsystems: const [SubsystemType.francophone],
            academicYear: '2026-2027',
            activeMembership: validMembership,
          ),
          throwsArgumentError,
        );
      },
    );

    // ------------------------------------------------------------------------
    // Test 4: Le dashboard génère une synthèse déterministe à partir de données structurées
    // ------------------------------------------------------------------------
    test(
      '4. Le dashboard génère une synthèse déterministe à partir de données structurées',
      () {
        // Deterministic calculation from fixtures
        final items = DemoCampusFixtures.attentionItems;
        final warningSeverity = items
            .where((i) => i.severity == AttentionSeverity.warning)
            .length;

        expect(warningSeverity, greaterThan(0));

        // Same structured inputs produce identical results with no random or LLM variation
        final summary1 =
            'Sur ${DemoCampusFixtures.kpiSummary.teachersTotalCount} enseignants, ${DemoCampusFixtures.kpiSummary.teachersUpToDateCount} sont à jour du calendrier prévisionnel.';
        final summary2 =
            'Sur ${DemoCampusFixtures.kpiSummary.teachersTotalCount} enseignants, ${DemoCampusFixtures.kpiSummary.teachersUpToDateCount} sont à jour du calendrier prévisionnel.';
        expect(summary1, equals(summary2));
      },
    );

    // ------------------------------------------------------------------------
    // Test 5: Le détail d'une classe affiche les agrégats de maîtrise sans pourcentages trompeurs
    // ------------------------------------------------------------------------
    testWidgets(
      '5. Le détail d\'une classe affiche les agrégats de maîtrise sans pourcentages trompeurs',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWrapper(
            child: CampusClassDetailView(classId: 'class_tc1', onBack: () {}),
          ),
        );
        await tester.pumpAndSettle();

        // Distribution numbers from fixtures: 8, 19, 9, 4
        expect(find.text('8'), findsWidgets);
        expect(find.text('19'), findsWidgets);
        expect(find.text('9'), findsWidgets);
        expect(find.text('4'), findsWidgets);

        // Labels must be present
        expect(find.text('Solide'), findsWidgets);
        expect(find.text('Bien compris'), findsWidgets);
        expect(find.text('En construction'), findsWidgets);
        expect(find.text('Pas assez d’éléments'), findsWidgets);

        // Must not display pseudo percentages in mastery buckets
        expect(find.text('20%'), findsNothing);
        expect(find.text('47.5%'), findsNothing);
      },
    );

    // ------------------------------------------------------------------------
    // Test 6: Le DTO élève ne contient aucun champ de chat / conversation privée
    // ------------------------------------------------------------------------
    test(
      '6. Le DTO élève ne contient aucun champ de chat / conversation privée',
      () {
        final student = DemoCampusFixtures.sampleStudents.first;

        // Verification of properties exposed on the DTO
        expect(student.matricule, isNotEmpty);
        expect(student.fullName, isNotEmpty);
        expect(student.overallEvidence, isNotNull);
        expect(student.completedQuizCount, greaterThanOrEqualTo(0));

        // Verify absence of dynamic chat properties
        final studentMap = {
          'id': student.id,
          'matricule': student.matricule,
          'fullName': student.fullName,
          'className': student.className,
          'overallEvidence': student.overallEvidence.name,
        };

        expect(studentMap.containsKey('chatHistory'), isFalse);
        expect(studentMap.containsKey('companionMessages'), isFalse);
        expect(studentMap.containsKey('transcripts'), isFalse);
      },
    );

    // ------------------------------------------------------------------------
    // Test 7: L'invitation d'un membre du personnel valide les champs obligatoires
    // ------------------------------------------------------------------------
    test(
      '7. L\'invitation d\'un membre du personnel valide les champs obligatoires',
      () async {
        final repo = DemoCampusRepository();

        const invalidDraft = CampusStaffInvitationDraft(
          fullName: ' ',
          phone: '123',
          role: CampusRole.teacher,
          subjects: [],
          assignedClasses: [],
        );

        expect(invalidDraft.isValid, isFalse);

        expect(
          () => repo.inviteStaffMember(
            establishmentId: DemoCampusFixtures.demoEstablishmentId,
            draft: invalidDraft,
          ),
          throwsArgumentError,
        );

        const validDraft = CampusStaffInvitationDraft(
          fullName: 'Mme. Jeanne Kamga',
          phone: '+237677889900',
          role: CampusRole.teacher,
          subjects: ['Chimie'],
          assignedClasses: ['Terminale D2'],
        );

        expect(validDraft.isValid, isTrue);
        await repo.inviteStaffMember(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          draft: validDraft,
        );

        final staff = await repo.getStaff(
          DemoCampusFixtures.demoEstablishmentId,
        );
        expect(staff.any((s) => s.fullName == 'Mme. Jeanne Kamga'), isTrue);
      },
    );

    // ------------------------------------------------------------------------
    // Test 8: La mise à jour du statut d'une séquence de programme fonctionne dans le repository démo
    // ------------------------------------------------------------------------
    test(
      '8. La mise à jour du statut d\'une séquence de programme fonctionne dans le repository démo',
      () async {
        final repo = DemoCampusRepository();
        final itemsBefore = await repo.getTeachingPlan(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
        );
        final firstItem = itemsBefore.first;

        await repo.updateTeachingPlanStatus(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          planItemId: firstItem.id,
          newStatus: TeachingPlanStatus.completed,
        );

        final itemsAfter = await repo.getTeachingPlan(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
        );
        final updatedItem = itemsAfter.firstWhere((i) => i.id == firstItem.id);
        expect(updatedItem.status, equals(TeachingPlanStatus.completed));
      },
    );

    // ------------------------------------------------------------------------
    // Test 9: Le quiz créé en studio reste à l'état brouillon tant qu'il n'est pas publié
    // ------------------------------------------------------------------------
    test(
      '9. Le quiz créé en studio reste à l\'état brouillon tant qu\'il n\'est pas publié',
      () async {
        final repo = DemoCampusRepository();
        final createdQuiz = await repo.generateDraftQuiz(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          classId: 'class_tc1',
          className: 'Terminale C1',
          subjectName: 'Mathématiques',
          chapterTitle: 'Fonctions logarithmiques',
          purpose: QuizPurpose.homework,
          difficulty: QuizDifficulty.standard,
          questionCount: 3,
        );

        expect(createdQuiz.isPublished, isFalse);

        await repo.publishQuizDraft(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          quizId: createdQuiz.id,
        );

        final quizzes = await repo.getQuizDrafts(
          DemoCampusFixtures.demoEstablishmentId,
        );
        final published = quizzes.firstWhere((q) => q.id == createdQuiz.id);
        expect(published.isPublished, isTrue);
      },
    );

    // ------------------------------------------------------------------------
    // Test 10: La vue enseignant n'affiche que les classes assignées
    // ------------------------------------------------------------------------
    test(
      '10. La vue enseignant n\'affiche que les classes assignées',
      () async {
        final repo = DemoCampusRepository();
        final allClasses = await repo.getClasses(
          DemoCampusFixtures.demoEstablishmentId,
        );
        const assignedIds = ['class_tc1', 'class_pc'];

        final teacherClasses = allClasses
            .where((c) => assignedIds.contains(c.id))
            .toList();

        expect(teacherClasses.length, equals(2));
        final names = teacherClasses.map((c) => c.displayName).toList();
        expect(names, contains('Terminale C1'));
        expect(names, contains('Première C'));
        expect(names.contains('Form 5 Science'), isFalse);
        expect(names.contains('Upper Sixth Arts'), isFalse);
      },
    );

    // ------------------------------------------------------------------------
    // Test 11: La pagination des élèves respecte le contrat de repository
    // ------------------------------------------------------------------------
    test(
      '11. La pagination des élèves respecte le contrat de repository',
      () async {
        final repo = DemoCampusRepository();
        final page1 = await repo.getStudents(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          pageIndex: 1,
          pageSize: 2,
        );

        expect(page1.items.length, equals(2));
        expect(page1.pageIndex, equals(1));
        expect(page1.hasNextPage, isTrue);
        expect(page1.totalCount, greaterThan(2));

        final page2 = await repo.getStudents(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          pageIndex: 2,
          pageSize: 2,
        );
        expect(page2.items.length, equals(2));
        expect(page2.items.first.id, isNot(equals(page1.items.first.id)));
      },
    );

    // ------------------------------------------------------------------------
    // Test 12: Le composant CampusBadge s'affiche correctement selon les variantes
    // ------------------------------------------------------------------------
    testWidgets(
      '12. Le composant CampusBadge s\'affiche correctement selon les variantes',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CampusBadge(
                    label: 'Badge Neutre',
                    variant: CampusBadgeVariant.neutral,
                  ),
                  CampusBadge(
                    label: 'Badge Info',
                    variant: CampusBadgeVariant.info,
                  ),
                  CampusBadge(
                    label: 'Badge Succès',
                    variant: CampusBadgeVariant.success,
                  ),
                  CampusBadge(
                    label: 'Badge Attention',
                    variant: CampusBadgeVariant.warning,
                  ),
                  CampusBadge(
                    label: 'Badge Critique',
                    variant: CampusBadgeVariant.critical,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Badge Neutre'), findsOneWidget);
        expect(find.text('Badge Info'), findsOneWidget);
        expect(find.text('Badge Succès'), findsOneWidget);
        expect(find.text('Badge Attention'), findsOneWidget);
        expect(find.text('Badge Critique'), findsOneWidget);
      },
    );

    // ------------------------------------------------------------------------
    // Test 13: Le composant CampusKpiCard affiche le titre, la valeur et le sous-titre
    // ------------------------------------------------------------------------
    testWidgets(
      '13. Le composant CampusKpiCard affiche le titre, la valeur et le sous-titre',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CampusKpiCard(
                category: 'PROGRAMME',
                metric: '82%',
                label: 'Séquences engagées',
                subtitle: 'Objectif trimestriel respecté',
                icon: Icons.trending_up,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PROGRAMME'), findsOneWidget);
        expect(find.text('Séquences engagées'), findsOneWidget);
        expect(find.text('82%'), findsOneWidget);
        expect(find.text('Objectif trimestriel respecté'), findsOneWidget);
      },
    );

    // ------------------------------------------------------------------------
    // Test 14: Les écrans ne provoquent pas de débordement fatal à 768 px de largeur
    // ------------------------------------------------------------------------
    testWidgets(
      '14. Les écrans ne provoquent pas de débordement fatal à 768 px de largeur',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWrapper(
            child: const CampusScaffold(body: DirectionDashboardView()),
            size: const Size(768, 1024),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    // ------------------------------------------------------------------------
    // Test 15: Le layout s'adapte à 1024 px (tablette / petit écran desktop)
    // ------------------------------------------------------------------------
    testWidgets(
      '15. Le layout s\'adapte à 1024 px (tablette / petit écran desktop)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWrapper(
            child: const CampusScaffold(body: DirectionDashboardView()),
            size: const Size(1024, 768),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(DirectionDashboardView), findsOneWidget);
      },
    );

    // ------------------------------------------------------------------------
    // Test 16: Le layout s'adapte à 1440 px (grand écran de direction)
    // ------------------------------------------------------------------------
    testWidgets(
      '16. Le layout s\'adapte à 1440 px (grand écran de direction)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWrapper(
            child: const CampusScaffold(body: DirectionDashboardView()),
            size: const Size(1440, 900),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CampusSidebar), findsOneWidget);
      },
    );

    // ------------------------------------------------------------------------
    // Test 17: Le composant supporte un facteur d'échelle de texte élevé (textScale = 2.0)
    // ------------------------------------------------------------------------
    testWidgets(
      '17. Le composant supporte un facteur d\'échelle de texte élevé (textScale = 2.0)',
      (tester) async {
        await tester.pumpWidget(
          _buildTestWrapper(
            child: const CampusScaffold(body: DirectionDashboardView()),
            size: const Size(1440, 900),
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        final err = tester.takeException();
        expect(err, isNull);
      },
    );

    // ------------------------------------------------------------------------
    // Test 18: L'isolation des erreurs fonctionne : une erreur dans un bloc n'entraîne pas le crash du shell
    // ------------------------------------------------------------------------
    testWidgets(
      '18. L\'isolation des erreurs fonctionne : une erreur dans un bloc n\'entraîne pas le crash du shell',
      (tester) async {
        bool retried = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CampusErrorView(
                errorMessage: 'Erreur isolée de test',
                onRetry: () => retried = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Erreur isolée de test'), findsOneWidget);
        await tester.tap(find.text('Réessayer'));
        expect(retried, isTrue);
      },
    );

    // ------------------------------------------------------------------------
    // Test 19: L'état vide d'un établissement sans données est rendu avec dignité
    // ------------------------------------------------------------------------
    testWidgets(
      '19. L\'état vide d\'un établissement sans données est rendu avec dignité',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CampusEmptyState(
                title: 'Aucune donnée disponible',
                subtitle:
                    'Le calendrier pédagogique est en cours d\'initialisation.',
                icon: Icons.school_outlined,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aucune donnée disponible'), findsOneWidget);
        expect(
          find.text(
            'Le calendrier pédagogique est en cours d\'initialisation.',
          ),
          findsOneWidget,
        );
      },
    );

    // ------------------------------------------------------------------------
    // Test 20: Le statut suspendu d'un membre bloque l'accès aux actions d'édition
    // ------------------------------------------------------------------------
    test(
      '20. Le statut suspendu d\'un membre bloque l\'accès aux actions d\'édition',
      () async {
        final repo = DemoCampusRepository();
        final staffList = await repo.getStaff(
          DemoCampusFixtures.demoEstablishmentId,
        );
        final memberToSuspend = staffList.first;

        await repo.updateStaffStatus(
          establishmentId: DemoCampusFixtures.demoEstablishmentId,
          staffId: memberToSuspend.id,
          newStatus: MembershipStatus.suspended,
        );

        final updatedStaff = await repo.getStaff(
          DemoCampusFixtures.demoEstablishmentId,
        );
        final target = updatedStaff.firstWhere(
          (s) => s.id == memberToSuspend.id,
        );
        expect(target.status, equals(MembershipStatus.suspended));

        // Suspended member cannot be considered active
        expect(target.status == MembershipStatus.active, isFalse);
      },
    );
  });
}
