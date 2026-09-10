import 'flow_card.dart';
import 'flow_item.dart';
import 'flow_subject.dart';

/// Traduit une publication stockée en carte que le moteur Flow sait rendre.
///
/// Registre de décisions : le moteur d'affichage n'est pas touché. Il connaît
/// déjà une hiérarchie scellée de cartes, éprouvée sur appareil ; le fil
/// éditorial vient l'alimenter, pas le remplacer.
///
/// Toute traduction impossible renvoie null. Une publication dont le sujet
/// n'existe pas, dont la charge utile est incomplète ou dont le type n'a pas
/// encore de rendu est écartée du fil — jamais rendue à moitié.
abstract final class FlowItemMapper {
  static FlowCard? toCard(FlowItem item) {
    final subject = FlowSubjects.byId(item.subjectId);
    if (subject == null) return null;

    final title = item.title.trim();
    final duration = item.durationSeconds.clamp(10, 120);

    switch (item.type) {
      case FlowItemType.notion:
      case FlowItemType.infographic:
        final points = _strings(item.payload['points']);
        final insight = _text(item.payload['insight'], item.hook);
        if (insight.isEmpty && points.isEmpty) return null;
        return FlowNotionCard(
          id: item.id,
          subject: subject,
          title: title,
          insight: insight,
          points: points,
          estimatedSeconds: duration,
        );

      case FlowItemType.question:
        final answer = _text(item.payload['answer'], '');
        final question = _text(item.payload['question'], item.hook);
        if (question.isEmpty || answer.isEmpty) return null;
        return FlowQuestionCard(
          id: item.id,
          subject: subject,
          question: question,
          answer: answer,
          estimatedSeconds: duration,
        );

      case FlowItemType.quiz:
        final question = _text(item.payload['question'], title);
        final options = _strings(item.payload['options']);
        final correct = item.payload['correctIndex'];
        // Un quiz sans bonne réponse valide induirait l'élève en erreur.
        if (question.isEmpty || options.length < 2) return null;
        if (correct is! num) return null;
        final index = correct.toInt();
        if (index < 0 || index >= options.length) return null;
        return FlowMiniQuizCard(
          id: item.id,
          subject: subject,
          question: question,
          options: options,
          correctIndex: index,
          explanation: _text(item.payload['explanation'], ''),
          estimatedSeconds: duration,
        );

      case FlowItemType.audio:
      case FlowItemType.shortVideo:
        // Le média n'est pas recopié : la carte pointe vers lui, et sa durée
        // sert d'étiquette lisible.
        if (item.ref.storagePath == null) return null;
        return FlowVideoCard(
          id: item.id,
          subject: subject,
          title: title,
          description: item.hook,
          durationLabel: _durationLabel(item.durationSeconds),
          kicker: item.type == FlowItemType.audio
              ? 'Révision express'
              : 'Capsule vidéo',
          estimatedSeconds: duration,
        );

      case FlowItemType.image:
        final caption = _text(item.payload['caption'], item.hook);
        if (item.ref.storagePath == null || caption.isEmpty) return null;
        return FlowAnecdoteCard(
          id: item.id,
          subject: subject,
          title: title,
          story: caption,
          estimatedSeconds: duration,
        );

      case FlowItemType.interactiveNative:
        // Le registre ASTRA décide seul de ce qu'il sait rendre ; le fil se
        // contente de porter la clé et de résumer l'activité.
        final componentKey = _text(item.payload['componentKey'], '');
        if (componentKey.isEmpty) return null;
        final caption = _text(item.payload['summary'], item.hook);
        if (caption.isEmpty) return null;
        return FlowAnecdoteCard(
          id: item.id,
          subject: subject,
          title: title,
          story: caption,
          kicker: 'Activité',
          estimatedSeconds: duration,
        );
    }
  }

  /// Traduit une page entière, en écartant les publications inexploitables et
  /// les doublons d'identifiant.
  static List<FlowCard> toCards(Iterable<FlowItem> items) {
    final seen = <String>{};
    final cards = <FlowCard>[];
    for (final item in items) {
      if (!seen.add(item.id)) continue;
      final card = toCard(item);
      if (card != null) cards.add(card);
    }
    return cards;
  }

  static String _text(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback.trim();
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static String _durationLabel(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0 ? '$minutes min' : '$minutes min $rest s';
  }
}
