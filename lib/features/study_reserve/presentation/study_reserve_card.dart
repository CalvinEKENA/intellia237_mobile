import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/study_reserve_service.dart';
import 'study_reserve_gauge.dart';

/// Carte « Réserve d'étude » prête à poser : lit [studyReserveProvider] et rend
/// la jauge. [studentId] null = l'élève courant ; un UID = un enfant lié (parent).
///
/// Chargement/erreur ne cassent jamais l'écran hôte : la carte s'efface
/// discrètement plutôt que d'afficher une donnée fictive.
class StudyReserveCard extends ConsumerWidget {
  const StudyReserveCard({this.studentId, this.compact = false, super.key});

  final String? studentId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studyReserveProvider(studentId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reserve) => StudyReserveGauge(reserve: reserve, compact: compact),
    );
  }
}
