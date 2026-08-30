import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/intellia_pass/domain/family_graph.dart';
import 'package:intellia237/features/intellia_pass/domain/otp_authentication.dart';
import 'package:intellia237/features/intellia_pass/domain/parental_gate.dart';
import 'package:intellia237/features/intellia_pass/domain/phone_identity.dart';
import 'package:intellia237/features/intellia_pass/domain/shared_device_session.dart';
import 'package:intellia237/features/intellia_pass/domain/study_mode.dart';
import 'package:intellia237/features/intellia_pass/presentation/widgets/otp_channel_selector.dart';
import 'package:intellia237/features/intellia_pass/presentation/widgets/study_mode_surfaces.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 30);

  GuardianLearnerLink link({
    required String guardian,
    required String learner,
    GuardianRelationship relationship = GuardianRelationship.guardian,
    GuardianLearnerLinkStatus status = GuardianLearnerLinkStatus.verified,
  }) => GuardianLearnerLink(
    guardianUid: guardian,
    learnerUid: learner,
    relationship: relationship,
    status: status,
    permissions: const {
      GuardianPermission.viewProgress,
      GuardianPermission.startStudyMode,
    },
    createdAt: createdAt,
    verifiedAt: status == GuardianLearnerLinkStatus.verified ? createdAt : null,
  );

  test('one canonical learner can have two authorized guardians', () {
    final graph = FamilyGraph(
      learners: const [
        CanonicalLearnerProfile(
          learnerUid: 'learner-1',
          academicProfileId: 'academic-1',
        ),
      ],
    );
    graph
      ..upsertLink(
        link(
          guardian: 'guardian-mum',
          learner: 'learner-1',
          relationship: GuardianRelationship.mother,
        ),
      )
      ..upsertLink(
        link(
          guardian: 'guardian-dad',
          learner: 'learner-1',
          relationship: GuardianRelationship.father,
        ),
      );

    expect(graph.guardiansFor('learner-1'), hasLength(2));
    expect(graph.learners, hasLength(1));
    expect(graph.learners.single.academicProfileId, 'academic-1');
  });

  test('one guardian can link to multiple canonical learners', () {
    final graph = FamilyGraph(
      learners: const [
        CanonicalLearnerProfile(
          learnerUid: 'learner-1',
          academicProfileId: 'academic-1',
        ),
        CanonicalLearnerProfile(
          learnerUid: 'learner-2',
          academicProfileId: 'academic-2',
        ),
      ],
      links: [
        link(guardian: 'guardian-1', learner: 'learner-1'),
        link(guardian: 'guardian-1', learner: 'learner-2'),
      ],
    );

    expect(graph.learnersFor('guardian-1'), hasLength(2));
  });

  test('relationship label and pending state grant no authorization', () {
    final pendingMother = link(
      guardian: 'guardian-1',
      learner: 'learner-1',
      relationship: GuardianRelationship.mother,
      status: GuardianLearnerLinkStatus.pending,
    );

    expect(pendingMother.authorizes(GuardianPermission.viewProgress), isFalse);
  });

  test('second guardian linking cannot duplicate the academic record', () {
    final graph = FamilyGraph(
      learners: const [
        CanonicalLearnerProfile(
          learnerUid: 'learner-1',
          academicProfileId: 'academic-1',
        ),
      ],
    );
    graph
      ..upsertLink(link(guardian: 'g1', learner: 'learner-1'))
      ..upsertLink(link(guardian: 'g2', learner: 'learner-1'));

    expect(graph.learners, hasLength(1));
    expect(graph.links, hasLength(2));
  });

  test('Cameroon phone is primary and email remains optional', () {
    final phone = CameroonPhoneNumber.tryParse('6 99 12 34 56');
    expect(phone?.e164, '+237699123456');
    final identity = ParentContactIdentity(phone: phone!);
    expect(identity.email, isNull);
    expect(identity.hasOptionalRecoveryEmail, isFalse);
  });

  test('OTP abstraction supports SMS and WhatsApp without vendor coupling', () {
    expect(OtpChannel.values, [OtpChannel.sms, OtpChannel.whatsapp]);
    final source = Directory('lib/features/intellia_pass')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(
      source,
      isNot(
        matches(
          RegExp(
            r'MboaSmsProvider|EtechSmsProvider|LmtSmsProvider|SmsProProvider',
          ),
        ),
      ),
    );
    expect(source, isNot(matches(RegExp(r'(api[_-]?key|providerSecret)\s*='))));
  });

  test('raw learner selection is never treated as authorization proof', () {
    const request = LearnerSwitchRequest(
      selectedLearnerUid: 'learner-1',
      deviceReference: 'device-opaque',
    );
    expect(request.isAuthorizationProof, isFalse);
  });

  test('study completion stays inside INTELLIA until parental reclaim', () {
    const session = StudyModeSession(
      learnerUid: 'learner-1',
      duration: Duration(minutes: 30),
    );
    final completed = session.start().complete();
    expect(completed.status, StudyModeStatus.sessionComplete);
    expect(completed.remainsInsideIntellia, isTrue);
    expect(
      completed.reclaimAfterParentalGate().status,
      StudyModeStatus.reclaimed,
    );
  });

  test(
    'parent-sensitive access must execute a parental gate contract',
    () async {
      final gate = _RecordingGate();
      final access = ParentSensitiveAccess(gate);
      expect(
        await access.request(
          operation: ParentalOperation.viewHouseholdSettings,
          method: ParentalGateMethod.biometric,
        ),
        isTrue,
      );
      expect(
        gate.lastRequest?.operation,
        ParentalOperation.viewHouseholdSettings,
      );
    },
  );

  testWidgets(
    'OTP delivery UX offers WhatsApp and SMS without provider names',
    (tester) async {
      var channel = OtpChannel.whatsapp;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => OtpChannelSelector(
                selected: channel,
                onSelected: (value) => setState(() => channel = value),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Recevoir le code par WhatsApp'), findsOneWidget);
      expect(find.text('Recevoir le code par SMS'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('otp-channel-sms')));
      await tester.pump();
      expect(channel, OtpChannel.sms);
    },
  );

  testWidgets('study-complete surface cannot pop to the phone home screen', (
    tester,
  ) async {
    var reclaimed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StudyModeCompleteSurface(onReclaim: () => reclaimed = true),
      ),
    );
    expect(find.text('Session terminée'), findsOneWidget);
    expect(find.byType(PopScope<Object?>), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('study-mode-reclaim')));
    expect(reclaimed, isTrue);
  });
}

class _RecordingGate implements ParentalGate {
  ParentalGateRequest? lastRequest;

  @override
  Future<bool> verifyLocally(ParentalGateRequest request) async {
    lastRequest = request;
    return true;
  }
}
